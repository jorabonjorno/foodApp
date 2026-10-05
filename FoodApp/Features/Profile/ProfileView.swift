import Observation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {
    var isManageSubscriptionsPresented = false
    var isRestoring = false
    var toast: String?
    let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var isPremium: Bool { container.entitlements.isPremium }
    var scansUsed: Int { container.quota.used }
    var scansLimit: Int { container.entitlements.scansLimit }
    var isMock: Bool { container.environment.isMock }

    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var analyticsCounters: [(String, Int)] {
        guard let local = container.analytics as? LocalAnalyticsService else { return [] }
        return local.counters.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    func upgrade() { container.router.presentPaywall(.profile) }

    func restore() async {
        isRestoring = true
        await container.subscriptions.restore()
        isRestoring = false
        toast = isPremium ? L10n.Profile.restored : L10n.Paywall.nothingToRestore
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // Только для mock-режима: проверить PRO-интерфейс без покупки.
    var debugPremium: Bool {
        get { container.subscriptions.debugOverride }
        set { container.subscriptions.debugOverride = newValue }
    }

    func resetScans() { container.quota.reset() }
}

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: ProfileViewModel(container: container))
    }

    var body: some View {
        List {
            Section {
                statusCard
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                if viewModel.isPremium {
                    Button(L10n.Profile.manage, systemImage: "creditcard") {
                        viewModel.isManageSubscriptionsPresented = true
                    }
                }
                Button {
                    Task { await viewModel.restore() }
                } label: {
                    HStack {
                        Label(L10n.Profile.restore, systemImage: "arrow.clockwise")
                        if viewModel.isRestoring { Spacer(); ProgressView() }
                    }
                }
                .disabled(viewModel.isRestoring)
                .accessibilityIdentifier("profile.restoreButton")
            }

            Section {
                Button(L10n.Profile.language, systemImage: "globe", action: viewModel.openSystemSettings)
                Link(destination: AppLinks.privacy) {
                    Label(L10n.Profile.privacy, systemImage: "hand.raised")
                }
                Link(destination: AppLinks.terms) {
                    Label(L10n.Profile.terms, systemImage: "doc.text")
                }
            } footer: {
                Text(L10n.Profile.photoNote + "\n\n" + L10n.Profile.version(viewModel.appVersion))
            }

            if viewModel.isMock {
                Section(L10n.Profile.debugTitle) {
                    Toggle(L10n.Profile.debugPremium, isOn: $viewModel.debugPremium)
                    Button(L10n.Profile.debugResetScans, action: viewModel.resetScans)
                    ForEach(viewModel.analyticsCounters, id: \.0) { name, count in
                        LabeledContent(name, value: "\(count)")
                            .font(.footnote.monospaced())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(L10n.Tab.profile)
        .manageSubscriptionsSheet(isPresented: $viewModel.isManageSubscriptionsPresented)
        .toast($viewModel.toast)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(viewModel.isPremium ? L10n.Profile.proActive : L10n.Profile.freePlan)
                    .font(.title3.weight(.bold))
                if viewModel.isPremium { ProBadge() }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Profile.scansUsage(viewModel.scansUsed, viewModel.scansLimit))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(min(viewModel.scansUsed, viewModel.scansLimit)), total: Double(max(viewModel.scansLimit, 1)))
                    .tint(Theme.accent)
            }
            if !viewModel.isPremium {
                Button(L10n.Paywall.cta, action: viewModel.upgrade)
                    .buttonStyle(.primary)
                    .accessibilityIdentifier("profile.upgradeButton")
            }
        }
        .cardStyle()
    }
}
