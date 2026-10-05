import SwiftData
import SwiftUI

@main
struct FoodApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .environment(container)
                .modelContainer(container.modelContainer)
                .task {
                    container.analytics.track(.appOpened)
                    container.subscriptions.start()
                }
        }
    }
}
