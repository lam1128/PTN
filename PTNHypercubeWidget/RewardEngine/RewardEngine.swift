import Foundation

struct RewardSnapshot {
    let currentRewards: [RewardItem]
    let manualUnknownRewards: [ManualUnknownReward]
    let secretPassProgress: SecretPassProgress
    let miniGameProgress: SecretPassProgress
}

struct RewardEngine {
    private let calendar = Calendar.rewardCalendar

    func snapshot(
        on currentDate: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> RewardSnapshot {
        let today = DayStamp.rewardDay(from: currentDate, calendar: calendar)
        var rewards: [RewardItem] = []

        rewards.append(contentsOf: makeDailyRewards(for: today, claimedKeys: claimedKeys))
        rewards.append(contentsOf: makeWeeklyRewards(for: today, claimedKeys: claimedKeys))
        rewards.append(contentsOf: makeMonthlyRewards(for: today, claimedKeys: claimedKeys))
        rewards.append(contentsOf: makeTimedMonthlyRewards(for: today, claimedKeys: claimedKeys))
        if let eventTrialReward = makeEventTrialReward(for: currentDate, claimedKeys: claimedKeys) {
            rewards.append(eventTrialReward)
        }

        rewards.append(contentsOf: makeDarkZoneRewards(for: today, claimedKeys: claimedKeys))

        if let dataGapReward = makeDataGapReward(for: today, claimedKeys: claimedKeys) {
            rewards.append(dataGapReward)
        }

        return RewardSnapshot(
            currentRewards: sortCurrentRewards(rewards),
            manualUnknownRewards: sortManualUnknownRewards(
                makeManualUnknownRewards(
                    claimedKeys: claimedKeys,
                    manualCycleVersions: manualCycleVersions
                )
            ),
            secretPassProgress: makeSecretPassProgress(
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions
            ),
            miniGameProgress: makeMiniGameProgress(
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions
            )
        )
    }

    private func makeDailyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        let claimKey = "daily-fixed-\(day.key)"
        let isClaimed = claimedKeys.contains(claimKey)
        let totalValue = RewardSchedule.dailySources.reduce(RewardValue.zero) { partial, source in
            partial + source.value
        }

        return RewardSchedule.dailySources.enumerated().map { index, source in
            RewardItem(
                id: "\(source.id)-\(day.key)",
                category: .daily,
                title: source.title,
                footnote: nil,
                displayValue: source.value,
                claimValue: totalValue,
                claimSource: RewardSchedule.dailyFixedClaimSource,
                claimKey: claimKey,
                sortOrder: 100 + index,
                isClaimed: isClaimed
            )
        }
    }

    private func makeWeeklyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        let weekStart = weekStart(for: day)
        return RewardSchedule.weeklySources.enumerated().map { index, source in
            let claimKey = "\(source.id)-\(weekStart.key)"
            return RewardItem(
                id: claimKey,
                category: .weekly,
                title: source.title,
                footnote: nil,
                displayValue: source.value,
                claimValue: source.value,
                claimSource: source.title,
                claimKey: claimKey,
                sortOrder: 200 + index,
                isClaimed: claimedKeys.contains(claimKey)
            )
        }
    }

    private func makeMonthlyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        let monthStart = monthStart(for: day)
        return RewardSchedule.monthlySources.enumerated().map { index, source in
            let claimKey = "\(source.id)-\(monthStart.key)"
            return RewardItem(
                id: claimKey,
                category: .monthly,
                title: source.title,
                footnote: nil,
                displayValue: source.value,
                claimValue: source.value,
                claimSource: source.title,
                claimKey: claimKey,
                sortOrder: 250 + index,
                isClaimed: claimedKeys.contains(claimKey)
            )
        }
    }

    private func makeTimedMonthlyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        RewardSchedule.timedMonthlySources.enumerated().compactMap { index, source in
            guard isWithinTimedMonthlyWindow(day: day, targetDay: source.dayOfMonth, visibleDays: source.visibleDays) else {
                return nil
            }

            let monthStart = monthStart(for: day)
            let claimKey = "\(source.id)-\(monthStart.key)"
            return RewardItem(
                id: claimKey,
                category: .monthly,
                title: source.title,
                footnote: nil,
                displayValue: source.value,
                claimValue: source.value,
                claimSource: source.title,
                claimKey: claimKey,
                sortOrder: 275 + index,
                isClaimed: claimedKeys.contains(claimKey)
            )
        }
    }

    private func makeDarkZoneRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        let weekStartDate = weekStart(for: day).date(in: calendar)
        let anchorDate = RewardSchedule.darkZoneAnchorMonday.date(in: calendar)
        let dayDifference = calendar.dateComponents([.day], from: anchorDate, to: weekStartDate).day ?? 0

        let weekOffset = dayDifference / 7
        let seasonOffset = floorDiv(weekOffset, RewardSchedule.darkZoneCycleWeeks)
        let weekIndex = positiveMod(weekOffset, RewardSchedule.darkZoneCycleWeeks) + 1
        let currentSeason = RewardSchedule.darkZoneAnchorSeason + seasonOffset
        var rewards: [RewardItem] = []

        let weeklyClaimKey = "dark-zone-\(currentSeason)-week-\(weekIndex)"
        rewards.append(
            RewardItem(
                id: weeklyClaimKey,
                category: .darkZone,
                title: "暗域·第\(currentSeason)期第\(weekIndex)周",
                footnote: nil,
                displayValue: RewardSchedule.darkZoneWeeklyValue,
                claimValue: RewardSchedule.darkZoneWeeklyValue,
                claimSource: "暗域·第\(currentSeason)期第\(weekIndex)周",
                claimKey: weeklyClaimKey,
                sortOrder: 300,
                isClaimed: claimedKeys.contains(weeklyClaimKey)
            )
        )

        for season in RewardSchedule.darkZoneAnchorSeason...currentSeason {
            let openingWeekOffset = (season - RewardSchedule.darkZoneAnchorSeason) * RewardSchedule.darkZoneCycleWeeks
            guard let seasonStart = calendar.date(byAdding: .day, value: openingWeekOffset * 7, to: anchorDate) else {
                continue
            }
            guard seasonStart <= day.date(in: calendar) else { continue }

            let claimKey = "dark-zone-season-\(season)"
            let isClaimed = claimedKeys.contains(claimKey)
            if season == currentSeason || !isClaimed {
                rewards.append(
                    RewardItem(
                        id: claimKey,
                        category: .darkZone,
                        title: "暗域·第\(season)期赛季奖励",
                        footnote: nil,
                        displayValue: RewardSchedule.darkZoneSeasonOpeningBonus,
                        claimValue: RewardSchedule.darkZoneSeasonOpeningBonus,
                        claimSource: "暗域·第\(season)期赛季奖励",
                        claimKey: claimKey,
                        sortOrder: 301 + season,
                        isClaimed: isClaimed
                    )
                )
            }
        }

        return rewards
    }

    private func makeEventTrialReward(for currentDate: Date, claimedKeys: Set<String>) -> RewardItem? {
        let activeEventBanners = RewardSchedule.pullPlanBanners
            .filter { $0.title == "活动池" && $0.isActive(at: currentDate, calendar: calendar) }
            .sorted { lhs, rhs in
                let lhsStart = lhs.startsAt(in: calendar)
                let rhsStart = rhs.startsAt(in: calendar)
                if lhsStart != rhsStart {
                    return lhsStart < rhsStart
                }
                return lhs.id < rhs.id
            }

        guard !activeEventBanners.isEmpty else { return nil }

        let title = RewardSchedule.eventTrialTitle(for: activeEventBanners)
        let value = RewardSchedule.eventTrialValue(for: activeEventBanners)
        let groupKey = activeEventBanners.map(\.id).sorted().joined(separator: "-")
        let claimKey = "event-trial-\(groupKey)"

        return RewardItem(
            id: claimKey,
            category: .eventTrial,
            title: "试用·\(title)",
            footnote: nil,
            displayValue: value,
            claimValue: value,
            claimSource: "试用·\(title)",
            claimKey: claimKey,
            sortOrder: 290,
            isClaimed: claimedKeys.contains(claimKey)
        )
    }

    private func makeDataGapReward(for day: DayStamp, claimedKeys: Set<String>) -> RewardItem? {
        let currentDate = day.date(in: calendar)

        for window in RewardSchedule.dataGapWindows {
            let startDate = window.start.date(in: calendar)
            let offset = calendar.dateComponents([.day], from: startDate, to: currentDate).day ?? Int.max
            guard (0..<window.days).contains(offset) else { continue }

            let dayIndex = offset + 1
            let claimKey = "data-gap-\(window.id)-day-\(dayIndex)"
            return RewardItem(
                id: claimKey,
                category: .dataGap,
                title: "\(window.title) Day \(dayIndex)",
                footnote: nil,
                displayValue: window.dailyValue,
                claimValue: window.dailyValue,
                claimSource: "\(window.title) Day \(dayIndex)",
                claimKey: claimKey,
                sortOrder: 400,
                isClaimed: claimedKeys.contains(claimKey)
            )
        }

        return nil
    }

    private func makeManualUnknownRewards(
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> [ManualUnknownReward] {
        RewardSchedule.manualUnknownSources.map { source in
            let version = manualCycleVersions[source.id] ?? 0
            let claimKey = "\(source.id)-manual-v\(version)"
            return ManualUnknownReward(
                id: source.id,
                title: source.title,
                value: source.value,
                claimSource: source.title,
                claimKey: claimKey,
                cycleVersion: version,
                isClaimed: claimedKeys.contains(claimKey)
            )
        }
    }

    private func makeSecretPassProgress(
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        makeProgress(
            id: RewardSchedule.secretPassID,
            title: RewardSchedule.secretPassTitle,
            slotValue: RewardSchedule.secretPassSlotValue,
            slotCount: RewardSchedule.secretPassTotalSlots,
            remainingText: RewardSchedule.secretPassRemainingText,
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions
        )
    }

    private func makeMiniGameProgress(
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        makeProgress(
            id: RewardSchedule.miniGameID,
            title: RewardSchedule.miniGameTitle,
            slotValue: RewardSchedule.miniGameSlotValue,
            slotCount: RewardSchedule.miniGameTotalSlots,
            remainingText: RewardSchedule.miniGameRemainingText,
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions
        )
    }

    private func makeProgress(
        id: String,
        title: String,
        slotValue: RewardValue,
        slotCount: Int,
        remainingText: String?,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        let version = manualCycleVersions[id] ?? 0
        let slots = (1...slotCount).map { index in
            let claimKey = "\(id)-v\(version)-slot-\(index)"
            return SecretPassSlot(
                id: claimKey,
                index: index,
                claimKey: claimKey,
                isClaimed: claimedKeys.contains(claimKey)
            )
        }

        return SecretPassProgress(
            id: id,
            title: title,
            slotValue: slotValue,
            cycleVersion: version,
            slots: slots,
            remainingText: remainingText
        )
    }

    private func sortCurrentRewards(_ rewards: [RewardItem]) -> [RewardItem] {
        rewards.sorted { lhs, rhs in
            if lhs.isClaimed != rhs.isClaimed {
                return !lhs.isClaimed && rhs.isClaimed
            }
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }
            return lhs.title < rhs.title
        }
    }

    private func sortManualUnknownRewards(_ rewards: [ManualUnknownReward]) -> [ManualUnknownReward] {
        rewards.sorted { lhs, rhs in
            if lhs.isClaimed != rhs.isClaimed {
                return !lhs.isClaimed && rhs.isClaimed
            }
            return lhs.title < rhs.title
        }
    }

    func currentDarkZoneClaimKey(on currentDate: Date) -> String {
        let day = DayStamp.rewardDay(from: currentDate, calendar: calendar)
        let weekStart = weekStart(for: day).date(in: calendar)
        let anchorDate = RewardSchedule.darkZoneAnchorMonday.date(in: calendar)
        let dayDifference = calendar.dateComponents([.day], from: anchorDate, to: weekStart).day ?? 0
        let weekOffset = dayDifference / 7
        let seasonOffset = floorDiv(weekOffset, RewardSchedule.darkZoneCycleWeeks)
        let weekIndex = positiveMod(weekOffset, RewardSchedule.darkZoneCycleWeeks) + 1
        let season = RewardSchedule.darkZoneAnchorSeason + seasonOffset
        return "dark-zone-\(season)-week-\(weekIndex)"
    }

    private func weekStart(for day: DayStamp) -> DayStamp {
        let date = day.date(in: calendar)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let weekStart = calendar.date(from: components) else {
            return day
        }
        return DayStamp.from(weekStart, calendar: calendar)
    }

    private func monthStart(for day: DayStamp) -> DayStamp {
        DayStamp(year: day.year, month: day.month, day: 1)
    }

    private func isWithinTimedMonthlyWindow(day: DayStamp, targetDay: Int, visibleDays: Int) -> Bool {
        let currentDate = day.date(in: calendar)
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = targetDay
        components.hour = 12
        guard let targetDate = calendar.date(from: components) else { return false }
        let diff = calendar.dateComponents([.day], from: targetDate, to: currentDate).day ?? Int.max
        return (0..<visibleDays).contains(diff)
    }

    private func floorDiv(_ lhs: Int, _ rhs: Int) -> Int {
        let quotient = lhs / rhs
        let remainder = lhs % rhs
        if remainder != 0 && ((remainder < 0) != (rhs < 0)) {
            return quotient - 1
        }
        return quotient
    }

    private func positiveMod(_ lhs: Int, _ rhs: Int) -> Int {
        let remainder = lhs % rhs
        return remainder >= 0 ? remainder : remainder + rhs
    }
}
