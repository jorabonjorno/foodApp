import SwiftUI

/// История сканирований (PRO): только списки продуктов, без фотографий.
struct ScanHistoryView: View {
    let container: AppContainer

    var body: some View {
        List {
            ForEach(container.history.records) { record in
                NavigationLink(value: route(for: record)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        Text(record.ingredients.map(\.name).joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(L10n.History.title)
        .overlay {
            if container.history.records.isEmpty {
                EmptyStateView(title: L10n.History.emptyTitle, message: L10n.History.subtitle, systemImage: "clock")
            }
        }
    }

    /// Открывает список на экране подтверждения: его можно поправить и снова найти рецепты.
    private func route(for record: ScanRecord) -> AppRoute {
        .ingredients(record.ingredients.map { ingredient -> Ingredient in
            var copy = ingredient
            copy.id = UUID()
            return copy
        })
    }
}
