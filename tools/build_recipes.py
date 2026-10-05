#!/usr/bin/env python3
"""Собирает FoodApp/Resources/recipes.json из исходников tools/recipes/*.txt.

Формат исходника (один рецепт):

    ## id | Название | mealType | минуты | difficulty | порции | эмодзи
    > Короткое описание.
    - normalized_key | количество | единица | opt | Название (если отличается от словаря)
    1. Шаг приготовления.

Пустые поля в строке ингредиента можно опускать: `- salt`, `- tomato | 2 | шт`, `- herbs | | | opt`.
Все normalized_key проверяются по FoodDictionary.swift — опечатка в ключе ломает matching, поэтому это ошибка сборки.

Запуск:  python tools/build_recipes.py          — собрать
         python tools/build_recipes.py --check  — проверить, что JSON актуален (для CI)
"""
from __future__ import annotations

import io
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "tools" / "recipes"
DICTIONARY = ROOT / "FoodApp" / "Core" / "Recipes" / "FoodDictionary.swift"
OUTPUT = ROOT / "FoodApp" / "Resources" / "recipes.json"

MEAL_TYPES = {"breakfast", "lunch", "dinner", "soup", "salad", "baking", "dessert", "other"}
DIFFICULTIES = {"easy", "medium", "hard"}


def load_dictionary() -> dict[str, str]:
    text = DICTIONARY.read_text(encoding="utf-8")
    return dict(re.findall(r'\.init\("([a-z_]+)", "([^"]+)"', text))


def parse_quantity(raw: str) -> float | None:
    raw = raw.strip().replace(",", ".").replace("½", "0.5").replace("¼", "0.25")
    if not raw:
        return None
    if "/" in raw:
        a, b = raw.split("/", 1)
        return round(float(a) / float(b), 3)
    return float(raw)


def parse_file(path: Path, dictionary: dict[str, str], errors: list[str]) -> list[dict]:
    recipes: list[dict] = []
    current: dict | None = None
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        where = f"{path.name}:{lineno}"
        if not line or line.startswith("#!") or line.startswith("//"):
            continue
        if line.startswith("## "):
            parts = [p.strip() for p in line[3:].split("|")]
            if len(parts) != 7:
                errors.append(f"{where}: заголовок должен иметь 7 полей")
                current = None
                continue
            rid, title, meal, minutes, difficulty, servings, emoji = parts
            if meal not in MEAL_TYPES:
                errors.append(f"{where}: неизвестный mealType '{meal}'")
            if difficulty not in DIFFICULTIES:
                errors.append(f"{where}: неизвестная сложность '{difficulty}'")
            current = {
                "id": rid,
                "title": title,
                "description": "",
                "cookingTimeMinutes": int(minutes),
                "difficulty": difficulty,
                "servings": int(servings),
                "mealType": meal,
                "ingredients": [],
                "steps": [],
                "emoji": emoji or None,
                "_where": where,
            }
            recipes.append(current)
        elif current is None:
            errors.append(f"{where}: строка вне рецепта")
        elif line.startswith(">"):
            current["description"] = (current["description"] + " " + line[1:].strip()).strip()
        elif line.startswith("- "):
            parts = [p.strip() for p in line[2:].split("|")] + [""] * 5
            key, qty, unit, opt, name = parts[:5]
            if key not in dictionary:
                errors.append(f"{where}: ключ '{key}' отсутствует в FoodDictionary.swift")
                continue
            ingredient = {"name": name or dictionary[key], "normalizedName": key}
            try:
                q = parse_quantity(qty)
            except ValueError:
                errors.append(f"{where}: некорректное количество '{qty}'")
                q = None
            if q is not None:
                ingredient["quantity"] = q
            if unit:
                ingredient["unit"] = unit
            if opt == "opt":
                ingredient["optional"] = True
            elif opt:
                errors.append(f"{where}: 4-е поле может быть только 'opt'")
            current["ingredients"].append(ingredient)
        elif re.match(r"^\d+\.\s", line):
            current["steps"].append(re.sub(r"^\d+\.\s*", "", line))
        else:
            errors.append(f"{where}: непонятная строка: {line[:40]}")
    return recipes


def validate(recipes: list[dict], errors: list[str]) -> None:
    ids = Counter(r["id"] for r in recipes)
    for rid, count in ids.items():
        if count > 1:
            errors.append(f"дубликат id '{rid}'")
    for r in recipes:
        where = r["_where"]
        keys = [i["normalizedName"] for i in r["ingredients"]]
        if len(r["ingredients"]) < 2:
            errors.append(f"{where}: меньше 2 ингредиентов")
        if len(set(keys)) != len(keys):
            errors.append(f"{where}: повторяющийся ингредиент")
        if len(r["steps"]) < 2:
            errors.append(f"{where}: меньше 2 шагов")
        if not r["description"]:
            errors.append(f"{where}: нет описания")
        if not (1 <= r["cookingTimeMinutes"] <= 600):
            errors.append(f"{where}: странное время")


def build() -> tuple[str, list[dict]]:
    dictionary = load_dictionary()
    errors: list[str] = []
    recipes: list[dict] = []
    for path in sorted(SOURCES.glob("*.txt")):
        recipes.extend(parse_file(path, dictionary, errors))
    validate(recipes, errors)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)
    for r in recipes:
        r.pop("_where")
        if r["emoji"] is None:
            r.pop("emoji")
    text = json.dumps(recipes, ensure_ascii=False, indent=1) + "\n"
    return text, recipes


def main() -> None:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")
    text, recipes = build()
    if "--check" in sys.argv:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != text:
            print("recipes.json устарел: запустите python tools/build_recipes.py", file=sys.stderr)
            sys.exit(1)
        print(f"recipes.json актуален ({len(recipes)} рецептов)")
        return
    OUTPUT.write_text(text, encoding="utf-8", newline="\n")
    meals = Counter(r["mealType"] for r in recipes)
    quick = sum(1 for r in recipes if r["cookingTimeMinutes"] <= 20)
    print(f"Собрано {len(recipes)} рецептов → {OUTPUT.relative_to(ROOT)}")
    print("По типам:", dict(sorted(meals.items())), f"| быстрых (≤20 мин): {quick}")


if __name__ == "__main__":
    main()
