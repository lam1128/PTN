import Foundation

@MainActor
final class AppStateStore: ObservableObject {
    @Published private(set) var totalCrystals: Int
    @Published private(set) var totalBlueTickets: Int
    @Published private(set) var totalRedTickets: Int
    @Published private(set) var claimedRewardKeys: Set<String>
    @Published private(set) var history: [HistoryEntry]
    @Published private(set) var currentRewards: [RewardItem] = []
    @Published private(set) var permanentRewards: [RewardItem] = []
    @Published private(set) var manualUnknownRewards: [ManualUnknownReward] = []
    @Published private(set) var dailyExtraRewards: [RewardItem] = []
    @Published private(set) var dailyProgresses: [DailyProgress] = []
    @Published private(set) var secretPassProgress: SecretPassProgress
    @Published private(set) var miniGameProgress: SecretPassProgress
    @Published private(set) var redemptionCodeProgress: SecretPassProgress
    @Published private(set) var mainlineSignInProgress: SecretPassProgress
    @Published private(set) var anniversarySignInProgress: SecretPassProgress
    @Published private(set) var hasPremiumSecretPass: Bool
    @Published private(set) var usesExtraTranslucentBackground: Bool
    @Published private(set) var pullPlanBannerProgressRawValues: [String: Int]
    @Published private(set) var selectedPullPlanUpChoices: [String: String]
    @Published private(set) var selectedPullPlanLockChoices: [String: Int]
    @Published private(set) var pullPlanPityValues: [String: Int]

    private let defaults: UserDefaults
    private let rewardEngine: RewardEngine
    private var manualCycleVersions: [String: Int]
    private var dailyCycleVersions: [String: Int]

    private enum StorageKey {
        static let totalCrystals = "ptn.totalCrystals"
        static let totalBlueTickets = "ptn.totalBlueTickets"
        static let totalRedTickets = "ptn.totalRedTickets"
        static let legacyTotalTickets = "ptn.totalTickets"
        static let claimedRewardKeys = "ptn.claimedRewardKeys"
        static let history = "ptn.history"
        static let manualCycleVersions = "ptn.manualCycleVersions"
        static let dailyCycleVersions = "ptn.dailyCycleVersions"
        static let didBootstrapInitialState = "ptn.didBootstrapInitialState"
        static let selectedPullPlanBannerIDs = "ptn.selectedPullPlanBannerIDs"
        static let pullPlanBannerProgressRawValues = "ptn.pullPlanBannerProgressRawValues"
        static let selectedPullPlanUpChoices = "ptn.selectedPullPlanUpChoices"
        static let selectedPullPlanLockChoices = "ptn.selectedPullPlanLockChoices"
        static let pullPlanPityValues = "ptn.pullPlanPityValues"
        static let usesExtraTranslucentBackground = "ptn.usesExtraTranslucentBackground"
        static let hasPremiumSecretPass = "ptn.hasPremiumSecretPass"
        static let automaticStorageLastUpdateAt = "ptn.automaticStorageLastUpdateAt"
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
        self.dailyCycleVersions = defaults.dictionary(forKey: StorageKey.dailyCycleVersions) as? [String: Int] ?? [:]
        let savedProgress = defaults.dictionary(forKey: StorageKey.pullPlanBannerProgressRawValues) as? [String: Int] ?? [:]
        let legacyPlannedBannerIDs = Set(defaults.stringArray(forKey: StorageKey.selectedPullPlanBannerIDs) ?? [])
        self.pullPlanBannerProgressRawValues = savedProgress.isEmpty
            ? Dictionary(uniqueKeysWithValues: legacyPlannedBannerIDs.map { ($0, PullPlanBannerProgress.planned.rawValue) })
            : savedProgress
        self.selectedPullPlanUpChoices = defaults.dictionary(forKey: StorageKey.selectedPullPlanUpChoices) as? [String: String] ?? [:]
        self.selectedPullPlanLockChoices = defaults.dictionary(forKey: StorageKey.selectedPullPlanLockChoices) as? [String: Int] ?? [:]
        let savedPullPlanPityValues = defaults.dictionary(forKey: StorageKey.pullPlanPityValues) as? [String: Int] ?? [:]
        self.pullPlanPityValues = Self.migratedPullPlanPityValues(from: savedPullPlanPityValues)
        self.hasPremiumSecretPass = defaults.object(forKey: StorageKey.hasPremiumSecretPass) as? Bool ?? false
        self.usesExtraTranslucentBackground = defaults.object(forKey: StorageKey.usesExtraTranslucentBackground) as? Bool ?? false
        self.secretPassProgress = SecretPassProgress(
            id: RewardSchedule.secretPassDefinition.id,
            kind: RewardSchedule.secretPassDefinition.kind,
            title: RewardSchedule.secretPassDefinition.title,
            slotValue: RewardSchedule.secretPassDefinition.slotValue,
            cycleVersion: 0,
            slots: [],
            remainingText: nil,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: RewardSchedule.secretPassDefinition.showsCycleAdvanceButton
        )
        self.miniGameProgress = SecretPassProgress(
            id: RewardSchedule.miniGameDefinition.id,
            kind: RewardSchedule.miniGameDefinition.kind,
            title: RewardSchedule.miniGameDefinition.title,
            slotValue: RewardSchedule.miniGameDefinition.slotValue,
            cycleVersion: 0,
            slots: [],
            remainingText: nil,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: RewardSchedule.miniGameDefinition.showsCycleAdvanceButton
        )
        self.redemptionCodeProgress = SecretPassProgress(
            id: RewardSchedule.redemptionCodeDefinition.id,
            kind: RewardSchedule.redemptionCodeDefinition.kind,
            title: RewardSchedule.redemptionCodeDefinition.title,
            slotValue: RewardSchedule.redemptionCodeDefinition.slotValue,
            cycleVersion: 0,
            slots: [],
            remainingText: nil,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: RewardSchedule.redemptionCodeDefinition.showsCycleAdvanceButton
        )
        self.mainlineSignInProgress = SecretPassProgress(
            id: RewardSchedule.mainlineSignInDefinition.id,
            kind: RewardSchedule.mainlineSignInDefinition.kind,
            title: RewardSchedule.mainlineSignInDefinition.title,
            slotValue: RewardSchedule.mainlineSignInDefinition.slotValue,
            cycleVersion: 0,
            slots: [],
            remainingText: nil,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: RewardSchedule.mainlineSignInDefinition.showsCycleAdvanceButton
        )
        self.anniversarySignInProgress = SecretPassProgress(
            id: RewardSchedule.anniversarySignInDefinition.id,
            kind: RewardSchedule.anniversarySignInDefinition.kind,
            title: RewardSchedule.anniversarySignInDefinition.title,
            slotValue: RewardSchedule.anniversarySignInDefinition.slotValue,
            cycleVersion: 0,
            slots: [],
            remainingText: nil,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: RewardSchedule.anniversarySignInDefinition.showsCycleAdvanceButton
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
        applyAutomaticStorage(now: now)
        let snapshot = rewardEngine.snapshot(
            on: now,
            claimedKeys: claimedRewardKeys,
            manualCycleVersions: manualCycleVersions,
            dailyCycleVersions: dailyCycleVersions,
            hasPremiumSecretPass: hasPremiumSecretPass
        )
        currentRewards = snapshot.currentRewards
        permanentRewards = snapshot.permanentRewards
        manualUnknownRewards = snapshot.manualUnknownRewards
        dailyExtraRewards = snapshot.dailyExtraRewards
        dailyProgresses = snapshot.dailyProgresses
        secretPassProgress = snapshot.secretPassProgress
        miniGameProgress = snapshot.miniGameProgress
        redemptionCodeProgress = snapshot.redemptionCodeProgress
        mainlineSignInProgress = snapshot.mainlineSignInProgress
        anniversarySignInProgress = snapshot.anniversarySignInProgress
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

    func toggleDailyProgressSlot(
        _ progress: DailyProgress,
        slot: DailyProgressSlot,
        now: Date = Date()
    ) {
        if slot.isCompletionClaimed {
            let cycleID = slot.id
            let nextVersion = dailyCycleVersions[cycleID, default: 0] + 1
            dailyCycleVersions[cycleID] = nextVersion
            recordClaim(
                claimKey: "\(cycleID)-v\(nextVersion)-1",
                value: slot.value,
                source: "\(progress.title) 第\(slot.index)项",
                now: now
            )
            return
        }

        let nextCount = slot.count == slot.maxCount ? 0 : slot.count + 1

        if nextCount > slot.count {
            for (offset, claimKey) in slot.claimKeys[slot.count..<nextCount].enumerated() {
                recordClaim(
                    claimKey: claimKey,
                    value: slot.rewardValues[slot.count + offset],
                    source: "\(progress.title) 第\(slot.index)项",
                    now: now
                )
            }
        } else {
            for index in slot.claimKeys[nextCount..<slot.count].indices.reversed() {
                unclaim(
                    claimKey: slot.claimKeys[index],
                    value: slot.rewardValues[index],
                    now: now
                )
            }
        }
    }

    func advanceDailyProgress(
        _ progress: DailyProgress,
        now: Date = Date()
    ) {
        guard progress.showsCycleAdvanceButton else { return }

        for slot in progress.slots where slot.isComplete {
            guard let bonusKey = slot.completionClaimKey else { continue }
            recordClaim(
                claimKey: bonusKey,
                value: slot.completionBonus,
                source: "\(progress.title) 第\(slot.index)项完成奖励",
                now: now
            )
        }

        for slot in progress.slots {
            dailyCycleVersions[slot.id, default: 0] += 1
        }

        persist()
        refreshRewards(now: now)
    }

    func claimSecretPassSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        let definition = RewardSchedule.secretPassDefinition
        recordClaim(claimKey: slot.baseClaimKey, value: definition.slotValue, source: "\(definition.title) 第\(slot.index)抽", now: now)

        if hasPremiumSecretPass {
            recordClaim(claimKey: slot.premiumClaimKey, value: definition.slotValue, source: "\(definition.title) 高级奖励 第\(slot.index)抽", now: now)
        }
    }

    func toggleSecretPassSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        let definition = RewardSchedule.secretPassDefinition
        if claimedRewardKeys.contains(slot.baseClaimKey) {
            unclaim(claimKey: slot.baseClaimKey, value: definition.slotValue, now: now)
            unclaim(claimKey: slot.premiumClaimKey, value: definition.slotValue, now: now)
        } else {
            claimSecretPassSlot(slot, now: now)
        }
    }

    func setHasPremiumSecretPass(_ hasPremiumSecretPass: Bool, now: Date = Date()) {
        guard self.hasPremiumSecretPass != hasPremiumSecretPass else { return }

        self.hasPremiumSecretPass = hasPremiumSecretPass
        let definition = RewardSchedule.secretPassDefinition

        for slot in secretPassProgress.slots where claimedRewardKeys.contains(slot.baseClaimKey) {
            if hasPremiumSecretPass {
                recordClaim(
                    claimKey: slot.premiumClaimKey,
                    value: definition.slotValue,
                    source: "\(definition.title) 高级奖励 第\(slot.index)抽",
                    now: now
                )
            } else {
                unclaim(
                    claimKey: slot.premiumClaimKey,
                    value: definition.slotValue,
                    now: now
                )
            }
        }

        persist()
        refreshRewards(now: now)
    }

    func claimMiniGameSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        let definition = RewardSchedule.miniGameDefinition
        recordStandardProgressSlot(
            slot,
            value: definition.slotValue,
            source: "\(definition.title) 第\(slot.index)关",
            now: now
        )
    }

    func toggleMiniGameSlot(_ slot: SecretPassSlot, now: Date = Date()) {
        let definition = RewardSchedule.miniGameDefinition
        toggleStandardProgressSlot(
            slot,
            value: definition.slotValue,
            source: "\(definition.title) 第\(slot.index)关",
            now: now
        )
    }

    func toggleMainlineSignInSlot(
        _ progress: SecretPassProgress,
        slot: SecretPassSlot,
        now: Date = Date()
    ) {
        guard slot.isUnlocked else { return }
        let definition = RewardSchedule.mainlineSignInDefinition
        toggleStandardProgressSlot(
            slot,
            value: definition.slotValue,
            source: "\(progress.title) 第\(slot.index)天",
            now: now
        )
    }

    func toggleAnniversarySignInSlot(
        _ progress: SecretPassProgress,
        slot: SecretPassSlot,
        now: Date = Date()
    ) {
        guard slot.isUnlocked else { return }
        let definition = RewardSchedule.anniversarySignInDefinition
        toggleStandardProgressSlot(
            slot,
            value: definition.slotValue,
            source: "\(progress.title) 第\(slot.index)天",
            now: now
        )
    }

    func toggleRedemptionCodeSlot(
        _ progress: SecretPassProgress,
        slot: SecretPassSlot,
        now: Date = Date()
    ) {
        let definition = RewardSchedule.redemptionCodeDefinition
        toggleStandardProgressSlot(
            slot,
            value: definition.slotValue,
            source: "\(progress.title) 第\(slot.index)个",
            now: now
        )
    }

    private func recordStandardProgressSlot(
        _ slot: SecretPassSlot,
        value: RewardValue,
        source: String,
        now: Date
    ) {
        recordClaim(
            claimKey: slot.baseClaimKey,
            value: value,
            source: source,
            now: now
        )
    }

    private func toggleStandardProgressSlot(
        _ slot: SecretPassSlot,
        value: RewardValue,
        source: String,
        now: Date
    ) {
        if claimedRewardKeys.contains(slot.baseClaimKey) {
            unclaim(claimKey: slot.baseClaimKey, value: value, now: now)
        } else {
            recordStandardProgressSlot(slot, value: value, source: source, now: now)
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
        guard let index = history.firstIndex(where: { entry in
            guard let claimKey = entry.claimKey else { return true }
            return !claimKey.hasPrefix(RewardSchedule.automaticStorageHistoryKey)
        }) else {
            return
        }

        let latest = history.remove(at: index)
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

    private func applyAutomaticStorage(now: Date) {
        let key = StorageKey.automaticStorageLastUpdateAt
        let lastUpdate = defaults.object(forKey: key) as? Date ?? now
        let elapsed = now.timeIntervalSince(lastUpdate)
        let interval = RewardSchedule.automaticStorageInterval
        let completedCycles = max(0, Int(floor(elapsed / interval)))

        if completedCycles > 0 {
            let value = RewardSchedule.automaticStorageBatchValue
            let totalValue = RewardValue(
                crystals: value.crystals * completedCycles,
                blueTickets: value.blueTickets * completedCycles,
                redTickets: value.redTickets * completedCycles
            )
            apply(value: totalValue)
            for cycle in 0..<completedCycles {
                history.insert(
                    HistoryEntry(
                        timestamp: lastUpdate.addingTimeInterval(interval * Double(cycle + 1)),
                        source: RewardSchedule.automaticStorageTitle,
                        value: value,
                        claimKey: RewardSchedule.automaticStorageHistoryKey
                    ),
                    at: 0
                )
            }
            defaults.set(lastUpdate.addingTimeInterval(interval * Double(completedCycles)), forKey: key)
            persist()
        } else if defaults.object(forKey: key) == nil {
            defaults.set(now, forKey: key)
        }
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
        defaults.set(dailyCycleVersions, forKey: StorageKey.dailyCycleVersions)
        defaults.set(pullPlanBannerProgressRawValues, forKey: StorageKey.pullPlanBannerProgressRawValues)
        defaults.set(selectedPullPlanUpChoices, forKey: StorageKey.selectedPullPlanUpChoices)
        defaults.set(selectedPullPlanLockChoices, forKey: StorageKey.selectedPullPlanLockChoices)
        defaults.set(pullPlanPityValues, forKey: StorageKey.pullPlanPityValues)
        defaults.set(hasPremiumSecretPass, forKey: StorageKey.hasPremiumSecretPass)
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
