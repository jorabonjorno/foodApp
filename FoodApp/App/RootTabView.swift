import SwiftUI

struct RootTabView: View {
    let container: AppContainer
    @Bindable private var router: AppRouter

    init(container: AppContainer) {
        self.container = container
        self._router = Bindable(container.router)
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeView(container: container)
                    .appDestinations(container: container)
            }
            .tabItem { Label(L10n.Tab.home, systemImage: "house.fill") }
            .tag(AppRouter.Tab.home)

            NavigationStack(path: $router.pantryPath) {
                PantryView(container: container)
                    .appDestinations(container: container)
            }
            .tabItem { Label(L10n.Tab.pantry, systemImage: "refrigerator.fill") }
            .tag(AppRouter.Tab.pantry)

            NavigationStack(path: $router.favoritesPath) {
                FavoritesView(container: container)
                    .appDestinations(container: container)
            }
            .tabItem { Label(L10n.Tab.favorites, systemImage: "heart.fill") }
            .tag(AppRouter.Tab.favorites)

            NavigationStack(path: $router.profilePath) {
                ProfileView(container: container)
                    .appDestinations(container: container)
            }
            .tabItem { Label(L10n.Tab.profile, systemImage: "person.crop.circle") }
            .tag(AppRouter.Tab.profile)
        }
        .sheet(item: $router.paywallReason) { reason in
            PaywallView(container: container, reason: reason)
        }
    }
}
