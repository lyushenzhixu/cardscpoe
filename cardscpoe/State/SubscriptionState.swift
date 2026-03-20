import Foundation
import Observation

enum SubscriptionTier: String, CaseIterable {
    case free
    case proMonthly
    case proYearly
    case lifetime

    var displayName: String {
        switch self {
        case .free: return "Free Plan"
        case .proMonthly: return "Pro Monthly"
        case .proYearly: return "Pro Yearly"
        case .lifetime: return "Lifetime Pro"
        }
    }

    var isPaid: Bool { self != .free }
}

enum PaywallSource: String {
    case onboarding
    case featureLimit
    case valueUnlock
    case profile
}

enum PaywallVariant: String {
    case soft
    case hard
}

@Observable
final class SubscriptionState {
    private enum Keys {
        static let tier = "CardScope.subscription.tier"
        static let paywallVariant = "CardScope.subscription.paywallVariant"
        static let trialEndAt = "CardScope.subscription.trialEndAt"
        static let dailyScanCount = "CardScope.subscription.dailyScanCount"
        static let dailyScanDate = "CardScope.subscription.dailyScanDate"
    }

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    private(set) var tier: SubscriptionTier {
        didSet { defaults.set(tier.rawValue, forKey: Keys.tier) }
    }

    private(set) var paywallVariant: PaywallVariant {
        didSet { defaults.set(paywallVariant.rawValue, forKey: Keys.paywallVariant) }
    }

    private(set) var trialEndAt: Date? {
        didSet { defaults.set(trialEndAt, forKey: Keys.trialEndAt) }
    }

    private(set) var dailyScanCount: Int {
        didSet { defaults.set(dailyScanCount, forKey: Keys.dailyScanCount) }
    }

    private(set) var dailyScanDate: Date {
        didSet { defaults.set(dailyScanDate, forKey: Keys.dailyScanDate) }
    }

    let freeDailyScanLimit = 3
    let freeCollectionLimit = 20

    init() {
        if let rawTier = defaults.string(forKey: Keys.tier),
           let savedTier = SubscriptionTier(rawValue: rawTier) {
            tier = savedTier
        } else {
            tier = .free
        }

        if let rawVariant = defaults.string(forKey: Keys.paywallVariant),
           let savedVariant = PaywallVariant(rawValue: rawVariant) {
            paywallVariant = savedVariant
        } else {
            // 本地分桶：50/50。后续可由远端配置覆盖。
            let assigned: PaywallVariant = Bool.random() ? .soft : .hard
            paywallVariant = assigned
            defaults.set(assigned.rawValue, forKey: Keys.paywallVariant)
        }

        trialEndAt = defaults.object(forKey: Keys.trialEndAt) as? Date
        dailyScanCount = defaults.integer(forKey: Keys.dailyScanCount)
        dailyScanDate = defaults.object(forKey: Keys.dailyScanDate) as? Date ?? Date()
        refreshDailyQuotaIfNeeded()
    }

    var isPro: Bool { tier.isPaid }
    var planDisplayName: String { tier.displayName }
    var hasTrialActive: Bool { (trialEndAt ?? .distantPast) > Date() }

    var planPrice: String {
        switch tier {
        case .free: return "Free"
        case .proMonthly: return "$9.99/mo"
        case .proYearly: return "$49.99/yr"
        case .lifetime: return "$149.99"
        }
    }

    var planDescription: String {
        switch tier {
        case .free: return "Basic features"
        case .proMonthly: return "Cancel anytime"
        case .proYearly: return "Save 50%"
        case .lifetime: return "One-time purchase"
        }
    }

    func setTier(_ newTier: SubscriptionTier) {
        tier = newTier
    }

    func startTrial(days: Int = 3) {
        guard days > 0 else { return }
        trialEndAt = calendar.date(byAdding: .day, value: days, to: Date())
    }

    func clearTrial() {
        trialEndAt = nil
    }

    func refreshDailyQuotaIfNeeded(now: Date = Date()) {
        if !calendar.isDate(dailyScanDate, inSameDayAs: now) {
            dailyScanDate = now
            dailyScanCount = 0
        }
    }

    func canScanToday() -> Bool {
        refreshDailyQuotaIfNeeded()
        if isPro { return true }
        return dailyScanCount < freeDailyScanLimit
    }

    func remainingFreeScansToday() -> Int {
        refreshDailyQuotaIfNeeded()
        if isPro { return Int.max }
        return max(0, freeDailyScanLimit - dailyScanCount)
    }

    func recordSuccessfulScan() {
        refreshDailyQuotaIfNeeded()
        guard !isPro else { return }
        dailyScanCount += 1
    }

    func canAddToCollection(currentCount: Int) -> Bool {
        if isPro { return true }
        return currentCount < freeCollectionLimit
    }

    func hasFullValuation() -> Bool { isPro }
    func hasPriceChart() -> Bool { isPro }
    func hasGradeAssessment() -> Bool { isPro }
    func hasBatchScan() -> Bool { tier == .proYearly || tier == .lifetime }
    func hasExport() -> Bool { tier == .proYearly || tier == .lifetime }
}
