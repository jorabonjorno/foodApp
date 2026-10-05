import SwiftUI

/// Строка продукта: иконка, название, количество [−] [+], удаление.
/// Используется на экране подтверждения и в «Моих продуктах».
struct IngredientRow: View {
    let ingredient: Ingredient
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onDelete: () -> Void
    var onRename: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            FoodIconView(emoji: ingredient.emoji)

            VStack(alignment: .leading, spacing: 3) {
                Text(ingredient.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                if ingredient.isLowConfidence {
                    Label(L10n.Ingredients.lowConfidence, systemImage: "questionmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.warning)
                } else {
                    Text(ingredient.category.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onRename?() }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(onRename == nil ? [] : .isButton)
            .accessibilityHint(onRename == nil ? "" : L10n.Ingredients.rename)

            quantityStepper

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(L10n.Common.delete + " " + ingredient.name)
        }
        .padding(.vertical, 2)
        .contextMenu {
            if let onRename {
                Button(L10n.Ingredients.rename, systemImage: "pencil", action: onRename)
            }
            Button(L10n.Common.delete, systemImage: "trash", role: .destructive, action: onDelete)
        }
    }

    private var quantityStepper: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) { Image(systemName: "minus") }
                .buttonStyle(.circleIcon)
                .disabled(ingredient.quantity == nil)
                .accessibilityLabel(L10n.Ingredients.decrease)

            Text(ingredient.formattedQuantity ?? "—")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .frame(minWidth: 44)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(.snappy, value: ingredient.quantity)

            Button(action: onIncrement) { Image(systemName: "plus") }
                .buttonStyle(.circleIcon)
                .accessibilityLabel(L10n.Ingredients.increase)
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(L10n.Ingredients.quantityA11y(ingredient.formattedQuantity ?? L10n.Ingredients.quantityUnknown))
    }
}
