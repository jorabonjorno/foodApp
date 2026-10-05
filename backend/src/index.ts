/**
 * FoodApp — минимальный прокси к Vision AI (Cloudflare Workers, free tier).
 *
 * Единственный маршрут: POST /recognize-foods
 *   { imageBase64: string, mediaType: "image/jpeg" | "image/png" | "image/webp", locale?: string }
 *   → { foods: [{ name, normalizedName, category, confidence, quantity, unit }] }
 *
 * Принципы:
 * - ключ AI хранится только здесь (wrangler secret), в приложении его нет;
 * - фото не сохраняется и не логируется: оно живёт только в памяти на время запроса;
 * - никаких аккаунтов и баз данных.
 */
import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { z } from "zod";
import { FOOD_RECOGNITION_SYSTEM, foodRecognitionUserText } from "./prompts";

export interface Env {
  ANTHROPIC_API_KEY: string;
  APP_TOKEN?: string;
  AI_MODEL?: string;
  LIMITER?: RateLimit;
}

const MAX_IMAGE_BASE64_LENGTH = 3_000_000; // ~2.2 MB JPEG — приложение шлёт ~150–400 KB
const MEDIA_TYPES = ["image/jpeg", "image/png", "image/webp"] as const;

const RequestSchema = z.object({
  imageBase64: z.string().min(100).max(MAX_IMAGE_BASE64_LENGTH),
  mediaType: z.enum(MEDIA_TYPES),
  locale: z.string().max(10).optional(),
});

const FoodSchema = z.object({
  name: z.string(),
  normalizedName: z.string(),
  category: z.enum([
    "vegetables", "fruits", "meat", "fish", "dairy", "eggs", "grains",
    "bakery", "spices", "sauces", "drinks", "sweets", "nuts", "other",
  ]),
  confidence: z.number(),
  quantity: z.number().nullable(),
  unit: z.string().nullable(),
});

const RecognitionSchema = z.object({ foods: z.array(FoodSchema) });

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" },
  });
}

async function recognizeFoods(request: Request, env: Env): Promise<Response> {
  let input: z.infer<typeof RequestSchema>;
  try {
    input = RequestSchema.parse(await request.json());
  } catch {
    return json({ error: "invalid_request" }, 400);
  }

  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY, maxRetries: 1, timeout: 25_000 });

  try {
    const response = await client.messages.parse({
      model: env.AI_MODEL ?? "claude-haiku-4-5",
      max_tokens: 2000,
      system: FOOD_RECOGNITION_SYSTEM,
      messages: [
        {
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: input.mediaType, data: input.imageBase64 } },
            { type: "text", text: foodRecognitionUserText(input.locale ?? "ru") },
          ],
        },
      ],
      output_config: { format: zodOutputFormat(RecognitionSchema) },
    });

    if (response.stop_reason === "refusal" || !response.parsed_output) {
      // Пустой список: приложение покажет «не нашли продуктов» и предложит ввести вручную.
      return json({ foods: [] });
    }

    const foods = response.parsed_output.foods
      .filter((food) => food.name.trim().length > 0)
      .slice(0, 40)
      .map((food) => ({
        ...food,
        confidence: Math.min(Math.max(food.confidence, 0), 1),
        quantity: food.quantity !== null && food.quantity > 0 ? food.quantity : null,
      }));

    // Только метрики, без содержимого фото и ответа.
    console.log(JSON.stringify({
      event: "recognize",
      foods: foods.length,
      input_tokens: response.usage.input_tokens,
      output_tokens: response.usage.output_tokens,
    }));

    return json({ foods });
  } catch (error) {
    if (error instanceof Anthropic.RateLimitError) return json({ error: "busy" }, 503);
    if (error instanceof Anthropic.BadRequestError) return json({ error: "bad_image" }, 422);
    if (error instanceof Anthropic.APIError) return json({ error: "upstream" }, 502);
    return json({ error: "internal" }, 500);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") return json({ ok: true });
    if (request.method !== "POST" || url.pathname !== "/recognize-foods") return json({ error: "not_found" }, 404);

    // Публичный токен приложения: не секрет, но отсекает случайный трафик.
    if (env.APP_TOKEN && request.headers.get("X-App-Token") !== env.APP_TOKEN) {
      return json({ error: "unauthorized" }, 401);
    }

    if (env.LIMITER) {
      const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";
      const { success } = await env.LIMITER.limit({ key: ip });
      if (!success) return json({ error: "rate_limited" }, 429);
    }

    return recognizeFoods(request, env);
  },
} satisfies ExportedHandler<Env>;
