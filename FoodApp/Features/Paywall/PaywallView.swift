import Observation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class PaywallViewModel {
    enum Plan: Hashable { case yearly, monthly }

    let reason: PaywallReason
    var selectedPlan: Plan = .yearly
    private(set) var isPurchasing = false
    var errorMessage: String?
    private let container: AppContainer

    init(container: AppContainer, reason: PaywallReason) {
        self.container = container
        self.reason = reason
    }

    private var subscriptions: SubscriptionManager { container.subscriptions }

    var title: String {
        reason == .scansExhausted ? L10n.Paywall.scansTitle(PlanLimits.freeScansPerMonth) : L10n.Paywall.title
    }

    var subtitle: String { L10n.Paywall.subtitle }

    // Цены берутся из App Store; до загрузки показываем базовые цены из плана.
    var yearlyPrice: String { subscriptions.yearly?.displayPrice ?? "$39.99" }
    var monthlyPrice: String { subscriptions.monthly?.displayPrice ?? "$4.99" }

    var yearlyPerMonth: String {
        guard let yearly = subscriptions.yearly else { return "$3.33" }
        return (yearly.price / 12).formatted(yearly.priceFormatStyle)
    }

    var savingsPercent: Int { subscriptions.yearlySavingsPercent }

    func onAppear() async {
        container.analytics.track(.paywallShown(reason: reason.rawValue))
        await subscriptions.loadProducts()
    }

    /// true — покупка прошла, paywall можно закрыть.
    func purchase() async -> Bool {
        let product = selectedPlan == .yearly ? subscriptions.yearly : subscriptions.monthly
        guard let product else {
            errorMessage = L10n.Paywall.productsUnavailable
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        switch await subscriptions.purchase(product) {
        case .success: return true
        case .cancelled, .pending: return false
        case .failed:
            errorMessage = L10n.Paywall.purchaseFailed
            return false
        }
    }

    func restore() async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        await subscriptions.restore()
        if !subscriptions.isPremium { errorMessage = L10n.Paywall.nothingToRestore }
        return subscriptions.isPremium
    }
}

/// Мягкий paywall: всегда можно закрыть.
struct PaywallView: View {
    @State private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss

    init(container: AppContainer, reason: PaywallReason) {
        _viewModel = State(initialValue: PaywallViewModel(container: container, reason: reason))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                hero
                features
                plans
                purchaseButton
                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Theme.Spacing.l)
        }
        .background(Theme.background)
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.regularMaterial, in: Circle())
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.Common.close)
            .accessibilityIdentifier("paywall.closeButton")
            .padding(Theme.Spacing.s)
        }
        .alert(
            L10n.Error.genericTitle,
            isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
        ) {
            Button(L10n.Common.done, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { await viewModel.onAppear() }
        .interactiveDismissDisabled(viewModel.isPurchasing)
    }

    private var hero: some View {
        VStack(spacing: Theme.Spacing.s) {
            ZStack {
                Circle().fill(Theme.ctaGradient).frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.top, Theme.Spacing.xl)
            .accessibilityHidden(true)
            Text(viewModel.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(viewModel.subtitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            feature("camera.viewfinder", L10n.Paywall.featureScans(PlanLimits.proScansPerMonth))
            feature("slider.horizontal.3", L10n.Paywall.featureFilters)
            feature("calendar", L10n.Paywall.featureMenu)
            feature("cart", L10n.Paywall.featureShopping)
            feature("clock.arrow.circlepath", L10n.Paywall.featureHistory)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text).font(.subheadline.weight(.medium))
        }
    }

    private var plans: some View {
        VStack(spacing: Theme.Spacing.s) {
            PlanCard(
                title: L10n.Paywall.yearly,
                price: viewModel.yearlyPrice,
                detail: L10n.Paywall.perMonth(viewModel.yearlyPerMonth),
                badge: L10n.Paywall.save(viewModel.savingsPercent),
                isSelected: viewModel.selectedPlan == .yearly
            ) { viewModel.selectedPlan = .yearly }
            .accessibilityIdentifier("paywall.yearlyPlan")

            PlanCard(
                title: L10n.Paywall.monthly,
                price: viewModel.monthlyPrice,
                detail: L10n.Paywall.billedMonthly,
                badge: nil,
                isSelected: viewModel.selectedPlan == .monthly
            ) { viewModel.selectedPlan = .monthly }
            .accessibilityIdentifier("paywall.monthlyPlan")
        }
    }

    private var purchaseButton: some View {
        Button {
            Task { if await viewModel.purchase() { dismiss() } }
        } label: {
            if viewModel.isPurchasing {
                ProgressView().tint(.white)
            } else {
                Text(L10n.Paywall.cta)
            }
        }
        .buttonStyle(.primaryLarge)
        .disabled(viewModel.isPurchasing)
        .accessibilityIdentifier("paywall.purchaseButton")
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text(L10n.Paywall.legal)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: Theme.Spacing.m) {
                Button(L10n.Profile.restore) {
                    Task { if await viewModel.restore() { dismiss() } }
                }
                Link(L10n.Profile.terms, destination: AppLinks.appleEULA)
                Link(L10n.Profile.privacy, destination: AppLinks.privacy)
            }
            .font(.footnote.weight(.semibold))
        }
    }
}

private struct PlanCard: View {
    let title: String
    let price: String
    let detail: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title).font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .foregroundStyle(.white)
                                .background(Theme.success, in: Capsule())
                        }
                    }
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(price).font(.title3.weight(.bold))
            }
            .foregroundStyle(Color.primary)
            .padding(Theme.Spacing.m)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
