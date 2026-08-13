import Foundation

@MainActor
final class AppStateStore: ObservableObject {
    @Published private(set) var totalCrystals: Int
    @Published private(set) var totalBlueTickets: Int
    @Published private(set) var totalRedTickets: Int
    @Published private(set) var claimedRewardKeys: Set<String>
    @Published private(set) var history: [HistoryEntry]
    @Published private(set) var currentRewards: [RewardItem] = []
    @Published private(set) var manualUnknownRewards: [ManualUnknownReward] = []
    @Published private(set) var secretPassProgress: SecretPassProgress
    @Published private(set) var miniGameProgress: SecretPassProgress
    @Published private(set) var usesExtraTranslucentBackground: Bool
    @Published private(set) var pullPlanBannerProgressRawValues: [String: Int]
    @Published private(set) var selectedPullPlanUpChoices: [String: String]
    @Published private(set) var selectedPullPlanLockChoices: [String: Int]
    @Published private(set) var pullPlanPityValues: [String: Int]

    private let defaults: UserDefaults
    private let rewardEngine: RewardEngine
    private var manualCycleVersions: [String: Int]

    private enum StorageKey {
        static let totalCrystals = "ptn.totalCrystals"
        static let totalBlueTickets = "ptn.totalBlueTickets"
        static let totalRedTickets = "ptn.totalRedTickets"
        static let legacyTotalTickets = "ptn.totalTickets"
        static let claimedRewardKeys = "ptn.claimedRewardKeys"
        static let history = "ptn.history"
        static let manualCycleVersions = "ptn.manualCycleVersions"
        static let didBootstrapInitialState = "ptn.didBootstrapInitialState"
        static let selectedPullPlanBannerIDs = "ptn.selectedPullPlanBannerIDs"
        static let pullPlanBannerProgressRawValues = "ptn.pullPlanBannerProgressRawValues"
        static let selectedPullPlanUpChoices = "ptn.selectedPullPlanUpChoices"
        static let selectedPullPlanLockChoices = "ptn.selectedPullPlanLockChoices"
        static let pullPlanPityValues = "ptn.pullPlanPityValues"
        static let usesExtraTranslucentBackground = "ptn.usesExtraTranslucentBackground"
    }

    init(
        defaults: UserDefaults = .standard,
        rewardEngine: RewardEngine = RewardEngine()
    ) {
        self.defaults = defaults
        self.rewardEngine = rewardEngine
        self.totalCrystals = defaults.object(forKey: StorageKey.totalCrystals) as? Int ?? 0
        self.totalBlueTickets = defaults.object(forKey: StorageKey.totalBlueTickets) as? Int
            ?? defaults.object(forKey: StorageKey.legacyTotalTickets) as? Int
            ?? 0
        self.totalRedTickets = defaults.object(forKey: StorageKey.totalRedTickets) as? Int ?? 0
        self.claimedRewardKeys = Set(defaults.stringArray(forKey: StorageKey.claimedRewardKeys) ?? [])
        self.history = Self.loadHistory(from: defaults.data(forKey: StorageKey.history))
        self.manualCycleVersions = defaults.dictionary(forKey: StorageKey.manualCycleVersions) as? [String: Int] ?? [:]
        let savedProgress = defaults.dictionary(forKey: StorageKey.pullPlanBannerProgressRawValues) as? [String: Int] ?? [:]
        let legacyPlannedBannerIDs = Set(defaults.stringArray(forKey: StorageKey.selectedPullPlanBannerIDs) ?? [])
        self.pullPlanBannerProgressRawValues = savedProgress.isEmpty
            ? Dictionary(uniqueKeysWithValues: legacyPlannedBannerIDs.map { ($0, PullPlanBannerProgress.planned.rawValue) })
            : savedProgress
        self.selectedPullPlanUpChoices = defaults.dictionary(forKey: StorageKey.selectedPullPlanUpChoices) as? [String: String] ?? [:]
        self.selectedPullPlanLockChoices = defaults.dictionary(forKey: StorageKey.selectedPullPlanLockChoices) as? [String: Int] ?? [:]
        let savedPullPlanPityValues = defaults.dictionary(forKey: StorageKey.pullPlanPityValues) as? [String: Int] ?? [:]
        self.pullPlanPityValues = Self.migratedPullPlanPityValues(from: savedPullPlanPityValues)
        self.usesExtraTranslucentBackground = defaults.object(forKey: StorageKey.usesExtraTranslucentBackground) as? Bool ?? false
        self.secretPassProgress = SecretPassProgress(
            id: RewardSchedule.secretPassID,
            title: RewardSchedule.secretPassTitle,
            slotValue: RewardSchedule.secretPassSlotValue,
            cycleVersion: 0,
            slots: [],
            remainingText: RewardSchedule.secretPassRemainingText
        )
        self.miniGameProgress = SecretPassProgress(
            id: RewardSchedule.miniGameID,
            title: RewardSchedule.miniGameTitle,
            slotValue: RewardSchedule.miniGameSlotValue,
            cycleVersion: 0,
            slots: [],
            remainingText: RewardSchedule.miniGameRemainingText
        )
        bootstrapInitialStateIfNeeded()
        refreshRewards()
    }

    var totalDrawCount: Double {
        Double(totalCrystals) / 180.0 + Double(totalBlueTickets)
    }

    var totalDrawCountFloor: Int {
        Int(totalDrawCount.rounded(.down))
    }

    var totalPlannedUpCount: Int {
        let currentDate = Date()
        return RewardSchedule.pullPlanBanners.reduce(0) { partial, banner in
            let progress = pullPlanBannerProgress(for: banner.id, allowCompleted: banner.isActive(at: currentDate))
            switch banner.selectionKind {
            case .none, .targetChoice:
                return partial + (progress == .planned ? 1 : 0)
            case .lockCount:
                if progress == .planned, let lock = selectedPullPlanLockChoices[banner.id] {
                    return partial + lock + 1
                }
                return partial
            }
        }
    }

    var todayCrystalEquivalentText: String? {
        let today = DayStamp.rewardDay(from: Date())
        let total = history.reduce(RewardValue.zero) { partial, entry in
            let entryDay = DayStamp.rewardDay(from: entry.timestamp)
            guard entryDay == today else { return partial }
            return partial + entry.value
        }

        guard !total.isZero else { return nil }
        return total.crystalEquivalentDescription(withPlusSign: true)
    }

    func pullPlanBannerProgress(for bannerID: String) -> PullPlanBannerProgress {
        PullPlanBannerProgress(rawValue: pullPlanBannerProgressRawValues[bannerID] ?? 0) ?? .none
    }

    func pullPlanBannerProgress(for bannerID: String, allowCompleted: Bool) -> PullPlanBannerProgress {
        let progress = pullPlanBannerProgress(for: bannerID)
        if !allowCompleted && progress == .completed {
            return .planned
        }
        return progress
    }

    func refreshRewards(now: Date = Date()) {
        let snapshot = rewardEngine.snapshot(
            on: now,
            claimedKeys: claimedRewardKeys,
            manualCycleVersions: manualCycleVersions
        )
        currentRewards = snapshot.currentRewards
        manualUnknownRewards = snapshot.manualUnknownRewards
        secretPassProgress = snapshot.secretPassProgress
        miniGameProgress = snapshot.miniGameProgress
    }

    func claim(_ reward: RewardItem, now: Date = Date()) {
        recordClaim(
            claimKey: reward.claimKey,
            value: reward.claimValue,
            source: reward.claimSource,
            now: now
        )
    }

    func toggle(_ reward: RewardItem, now: Date = Date()) {
        if claimedRewardKeys.contains(reward.claimKey) {
            unclaim(claimKey: reward.claimKey, value: reward.claimValue, now: now)
        } else {
            claim(reward, now: now)
        }
    }

    func claimManualUnknown(_ reward: ManualUnknownReward, now: Date = Date()) {
        recordClaim(
            claimKey: reward.claimKey,
            value: reward.value,
            source: reward.claimSource,
            now: now
        )
    }

    func toggleManualUnknown(_ reward: ManualUnknownReward, now: Date = Date()) {
        if claimedRewardKeys.contains(reward.claimKey) {
            unclaim(claimKey: reward.claimKey, value: reward.value, now: now)
        } else {
            claimManualUnknown(reward, now: now)
        }
    }

    func claimSecretPassSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        recordClaim(
            claimKey: slot.claimKey,
            value: RewardSchedule.secretPassSlotValue,
            source: "\(RewardSchedule.secretPassTitle) 第\(slot.index)抽",
            now: now
        )
    }

    func toggleSecretPassSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        if claimedRewardKeys.contains(slot.claimKey) {
            unclaim(claimKey: slot.claimKey, value: RewardSchedule.secretPassSlotValue, now: now)
        } else {
            claimSecretPassSlot(slot, now: now)
        }
    }

    func claimMiniGameSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        recordClaim(
            claimKey: slot.claimKey,
            value: RewardSchedule.miniGameSlotValue,
            source: "\(RewardSchedule.miniGameTitle) 第\(slot.index)关",
            now: now
        )
    }

    func toggleMiniGameSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        if claimedRewardKeys.contains(slot.claimKey) {
            unclaim(claimKey: slot.claimKey, value: RewardSchedule.miniGameSlotValue, now: now)
        } else {
            claimMiniGameSlot(slot, now: now)
        }
    }

    func advanceManualCycle(for sourceID: String, now: Date = Date()) {
        manualCycleVersions[sourceID, default: 0] += 1
        persist()
        refreshRewards(now: now)
    }

    func setInventory(crystals: Int, blueTickets: Int, redTickets: Int, now: Date = Date()) {
        let sanitizedCrystals = max(0, crystals)
        let sanitizedBlueTickets = max(0, blueTickets)
        let sanitizedRedTickets = max(0, redTickets)
        let delta = RewardValue(
            crystals: sanitizedCrystals - totalCrystals,
            blueTickets: sanitizedBlueTickets - totalBlueTickets,
            redTickets: sanitizedRedTickets - totalRedTickets
        )

        guard !delta.isZero else { return }

        totalCrystals = sanitizedCrystals
        totalBlueTickets = sanitizedBlueTickets
        totalRedTickets = sanitizedRedTickets
        history.insert(
            HistoryEntry(
                timestamp: now,
                source: "手动调整库存",
                value: delta,
                claimKey: nil
            ),
            at: 0
        )

        persist()
        refreshRewards(now: now)
    }

    func setUsesExtraTranslucentBackground(_ usesExtraTranslucentBackground: Bool) {
        guard self.usesExtraTranslucentBackground != usesExtraTranslucentBackground else { return }
        self.usesExtraTranslucentBackground = usesExtraTranslucentBackground
        persist()
    }

    func togglePullPlanBanner(_ bannerID: String, allowCompleted: Bool) {
        let nextProgress: PullPlanBannerProgress
        switch pullPlanBannerProgress(for: bannerID, allowCompleted: allowCompleted) {
        case .none:
            nextProgress = .planned
        case .planned:
            nextProgress = allowCompleted ? .completed : .none
        case .completed:
            nextProgress = .none
        }

        if nextProgress == .none {
            pullPlanBannerProgressRawValues.removeValue(forKey: bannerID)
        } else {
            pullPlanBannerProgressRawValues[bannerID] = nextProgress.rawValue
        }

        persist()
    }

    func togglePullPlanUpChoice(bannerID: String, character: String) {
        if selectedPullPlanUpChoices[bannerID] == character {
            selectedPullPlanUpChoices.removeValue(forKey: bannerID)
        } else {
            selectedPullPlanUpChoices[bannerID] = character
        }

        persist()
    }

    func togglePullPlanLockChoice(bannerID: String, lockLevel: Int) {
        if selectedPullPlanLockChoices[bannerID] == lockLevel {
            selectedPullPlanLockChoices.removeValue(forKey: bannerID)
            pullPlanBannerProgressRawValues.removeValue(forKey: bannerID)
        } else {
            selectedPullPlanLockChoices[bannerID] = lockLevel
            pullPlanBannerProgressRawValues[bannerID] = PullPlanBannerProgress.planned.rawValue
        }

        persist()
    }

    func pullPlanPityValue(for bannerID: String) -> Int? {
        let pityKey = RewardSchedule.pullPlanPityKey(for: bannerID)
        return pullPlanPityValues[pityKey]
    }

    func setPullPlanPityValue(for bannerID: String, value: Int?) {
        let pityKey = RewardSchedule.pullPlanPityKey(for: bannerID)

        if let value {
            pullPlanPityValues[pityKey] = max(0, value)
        } else {
            pullPlanPityValues.removeValue(forKey: pityKey)
        }

        persist()
    }

    func undoLatestHistoryEntry(now: Date = Date()) {
        guard let latest = history.first else { return }

        history.removeFirst()
        revert(value: latest.value)

        if let claimKey = latest.claimKey {
            claimedRewardKeys.remove(claimKey)
        }

        persist()
        refreshRewards(now: now)
    }

    private func unclaim(claimKey: String, value: RewardValue, now: Date = Date()) {
        guard claimedRewardKeys.contains(claimKey) else { return }

        claimedRewardKeys.remove(claimKey)
        revert(value: value)

        if let index = history.firstIndex(where: { $0.claimKey == claimKey }) {
            history.remove(at: index)
        }

        persist()
        refreshRewards(now: now)
    }

    private func recordClaim(
        claimKey: String,
        value: RewardValue,
        source: String,
        now: Date
    ) {
        guard !claimedRewardKeys.contains(claimKey) else { return }

        apply(value: value)
        claimedRewardKeys.insert(claimKey)
        history.insert(
            HistoryEntry(
                timestamp: now,
                source: source,
                value: value,
                claimKey: claimKey
            ),
            at: 0
        )

        persist()
        refreshRewards(now: now)
    }

    private func bootstrapInitialStateIfNeeded(now: Date = Date()) {
        guard !defaults.bool(forKey: StorageKey.didBootstrapInitialState) else { return }
        defer {
            defaults.set(true, forKey: StorageKey.didBootstrapInitialState)
        }

        let today = DayStamp.rewardDay(from: now)
        let baseline = DayStamp(year: 2026, month: 8, day: 13)
        guard today == baseline else { return }
        guard history.isEmpty else { return }

        claimedRewardKeys.insert(rewardEngine.currentDarkZoneClaimKey(on: now))
        claimedRewardKeys.insert("dark-zone-season-31")
        persist()
    }

    private func apply(value: RewardValue) {
        totalCrystals += value.crystals
        totalBlueTickets += value.blueTickets
        totalRedTickets += value.redTickets
    }

    private func revert(value: RewardValue) {
        totalCrystals = max(0, totalCrystals - value.crystals)
        totalBlueTickets = max(0, totalBlueTickets - value.blueTickets)
        totalRedTickets = max(0, totalRedTickets - value.redTickets)
    }

    private func persist() {
        defaults.set(totalCrystals, forKey: StorageKey.totalCrystals)
        defaults.set(totalBlueTickets, forKey: StorageKey.totalBlueTickets)
        defaults.set(totalRedTickets, forKey: StorageKey.totalRedTickets)
        defaults.set(Array(claimedRewardKeys).sorted(), forKey: StorageKey.claimedRewardKeys)
        defaults.set(manualCycleVersions, forKey: StorageKey.manualCycleVersions)
        defaults.set(pullPlanBannerProgressRawValues, forKey: StorageKey.pullPlanBannerProgressRawValues)
        defaults.set(selectedPullPlanUpChoices, forKey: StorageKey.selectedPullPlanUpChoices)
        defaults.set(selectedPullPlanLockChoices, forKey: StorageKey.selectedPullPlanLockChoices)
        defaults.set(pullPlanPityValues, forKey: StorageKey.pullPlanPityValues)
        defaults.set(usesExtraTranslucentBackground, forKey: StorageKey.usesExtraTranslucentBackground)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(history) {
            defaults.set(data, forKey: StorageKey.history)
        }
    }

    private static func loadHistory(from data: Data?) -> [HistoryEntry] {
        guard let data else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([HistoryEntry].self, from: data)) ?? []
    }

    private static func migratedPullPlanPityValues(from rawValues: [String: Int]) -> [String: Int] {
        guard !rawValues.isEmpty else { return rawValues }

        var migrated = rawValues

        for banner in RewardSchedule.pullPlanBanners {
            let legacyKey = "pull-plan-pity-\(banner.id)"
            let groupKey = RewardSchedule.pullPlanPityKey(for: banner.id)

            guard legacyKey != groupKey else { continue }
            guard let legacyValue = migrated[legacyKey] else { continue }
            guard migrated[groupKey] == nil else { continue }

            migrated[groupKey] = legacyValue
        }

        return migrated
    }
}
