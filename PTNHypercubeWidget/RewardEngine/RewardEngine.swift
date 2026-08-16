import Foundation

struct RewardSnapshot {
    let currentRewards: [RewardItem]
    let permanentRewards: [RewardItem]
    let manualUnknownRewards: [ManualUnknownReward]
    let dailyExtraRewards: [RewardItem]
    let dailyProgresses: [DailyProgress]
    let secretPassProgress: SecretPassProgress
    let miniGameProgress: SecretPassProgress
    let redemptionCodeProgress: SecretPassProgress
    let mainlineSignInProgress: SecretPassProgress
    let anniversarySignInProgress: SecretPassProgress
}

struct RewardEngine {
    private let calendar = Calendar.rewardCalendar

    func snapshot(
        on currentDate: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int],
        dailyCycleVersions: [String: Int],
        hasPremiumSecretPass: Bool
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
            permanentRewards: makePermanentRewards(for: currentDate, claimedKeys: claimedKeys),
            manualUnknownRewards: makeManualUnknownRewards(
                now: currentDate,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions
            ),
            dailyExtraRewards: makeDailyExtraRewards(for: today, claimedKeys: claimedKeys),
            dailyProgresses: makeDailyProgresses(
                for: today,
                claimedKeys: claimedKeys,
                dailyCycleVersions: dailyCycleVersions
            ),
            secretPassProgress: makeSecretPassProgress(
                now: currentDate,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions,
                hasPremiumSecretPass: hasPremiumSecretPass
            ),
            miniGameProgress: makeMiniGameProgress(
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions
            ),
            redemptionCodeProgress: makeRedemptionCodeProgress(
                now: currentDate,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions
            ),
            mainlineSignInProgress: makeMainlineSignInProgress(
                now: currentDate,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions
            ),
            anniversarySignInProgress: makeAnniversarySignInProgress(
                now: currentDate,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions
            )
        )
    }

    private func makePermanentRewards(
        for currentDate: Date,
        claimedKeys: Set<String>
    ) -> [RewardItem] {
        guard let anchor = currentPermanentRewardAnchor(at: currentDate) else {
            return []
        }
        let poolTitle = permanentRewardPoolTitle(for: anchor)

        return RewardSchedule.permanentRewardDefinitions.compactMap { definition in
            guard let window = permanentRewardWindow(for: definition, anchor: anchor),
                  window.start <= currentDate,
                  currentDate < window.end else {
                return nil
            }

            let claimKey = "permanent-reward-\(definition.id)-\(anchor.id)"
            let title = "\(definition.title)·\(poolTitle)"
            return makeRewardItem(
                category: .unknownSchedule,
                title: title,
                footnote: remainingText(
                    until: window.end,
                    now: currentDate,
                    hourSuffix: "时"
                ),
                displayValue: definition.value,
                claimKey: claimKey,
                sortOrder: definition.sortOrder,
                claimedKeys: claimedKeys
            )
        }
        .sorted { lhs, rhs in
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func permanentRewardPoolTitle(for anchor: PullPlanBanner) -> String {
        guard anchor.title != "限定池" else { return "周年庆" }
        let matchingBanners = RewardSchedule.pullPlanBanners.filter { banner in
            banner.title == RewardSchedule.activityPoolTitle
                && banner.startsAt(in: calendar) == anchor.startsAt(in: calendar)
        }
        return RewardSchedule.eventTrialTitle(for: matchingBanners)
    }

    private func currentPermanentRewardAnchor(at date: Date) -> PullPlanBanner? {
        RewardSchedule.currentPermanentRewardAnchor(at: date, calendar: calendar)
    }

    private func permanentRewardPoolBanners(for anchor: PullPlanBanner) -> [PullPlanBanner] {
        RewardSchedule.pullPlanBanners.filter { banner in
            banner.title == RewardSchedule.activityPoolTitle
                && banner.startsAt(in: calendar) == anchor.startsAt(in: calendar)
        }
    }

    private func isEnhancedPermanentRewardPool(_ anchor: PullPlanBanner) -> Bool {
        anchor.title == "限定池" || permanentRewardPoolBanners(for: anchor).count >= 2
    }

    private func permanentRewardWindow(
        for definition: PermanentRewardDefinition,
        anchor: PullPlanBanner
    ) -> (start: Date, end: Date)? {
        let anchorStart = anchor.startsAt(in: calendar)

        switch definition.timing {
        case .maintenance:
            guard let start = calendar.date(
                byAdding: .hour,
                value: RewardSchedule.maintenanceStartOffsetHours,
                to: anchorStart
            ),
            let end = calendar.date(
                byAdding: .day,
                value: RewardSchedule.maintenanceWindowDays,
                to: start
            ) else {
                return nil
            }
            return (start, end)
        case .questionnaire:
            guard let questionnaireDay = calendar.date(
                byAdding: .day,
                value: RewardSchedule.questionnaireStartOffsetDays,
                to: anchorStart
            ),
            let endDay = calendar.date(
                byAdding: .day,
                value: RewardSchedule.questionnaireEndOffsetDays,
                to: questionnaireDay
            ) else {
                return nil
            }

            let start = preciseDate(
                day: DayStamp.from(questionnaireDay, calendar: calendar),
                hour: RewardSchedule.questionnaireStartHour,
                minute: RewardSchedule.questionnaireStartMinute
            )
            let end = preciseDate(
                day: DayStamp.from(endDay, calendar: calendar),
                hour: RewardSchedule.questionnaireEndHour,
                minute: RewardSchedule.questionnaireEndMinute
            )
            return (start, end)
        }
    }

    private func makeDailyExtraRewards(
        for day: DayStamp,
        claimedKeys: Set<String>
    ) -> [RewardItem] {
        makeConfiguredRewards(
            from: RewardSchedule.dailyExtraSources,
            category: .unknownSchedule,
            cycleKey: day.key,
            sortOrderBase: 500,
            claimedKeys: claimedKeys
        )
    }

    private func makeDailyProgresses(
        for day: DayStamp,
        claimedKeys: Set<String>,
        dailyCycleVersions: [String: Int]
    ) -> [DailyProgress] {
        RewardSchedule.dailyProgressDefinitions.map { definition in
            let slots = definition.slots.enumerated().map { offset, slotDefinition in
                let index = offset + 1
                let cycleID = "\(definition.id)-\(day.key)-\(slotDefinition.id)"
                let cycleVersion = dailyCycleVersions[cycleID] ?? 0
                let versionSuffix = cycleVersion == 0 ? "" : "-v\(cycleVersion)"
                let claimPrefix = "\(cycleID)\(versionSuffix)"
                let claimKeys = (1...slotDefinition.maxCount).map { count in
                    "\(claimPrefix)-\(count)"
                }
                let completionClaimKey = slotDefinition.completionBonus.isZero
                    ? nil
                    : "\(claimPrefix)-completion"
                return DailyProgressSlot(
                    id: cycleID,
                    index: index,
                    value: slotDefinition.value,
                    claimKeys: claimKeys,
                    count: claimKeys.filter { claimedKeys.contains($0) }.count,
                    rewardValues: slotDefinition.rewardValues,
                    labels: slotDefinition.labels,
                    historySources: slotDefinition.historySources,
                    tint: slotDefinition.tint,
                    completionBonus: slotDefinition.completionBonus,
                    completionClaimKey: completionClaimKey,
                    isCompletionClaimed: completionClaimKey.map { claimedKeys.contains($0) } ?? false
                )
            }
            return DailyProgress(
                id: definition.id,
                title: definition.title,
                slots: slots,
                display: definition.display,
                showsCycleAdvanceButton: definition.showsCycleAdvanceButton
            )
        }
    }

    private func makeDailyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        let claimKey = "daily-fixed-\(day.key)"
        let totalValue = RewardSchedule.dailySources.reduce(RewardValue.zero) { partial, source in
            partial + source.value
        }

        return RewardSchedule.dailySources.enumerated().map { index, source in
            makeRewardItem(
                id: "\(source.id)-\(day.key)",
                category: .daily,
                title: source.title,
                displayValue: source.value,
                claimValue: totalValue,
                claimSource: RewardSchedule.dailyFixedClaimSource,
                claimKey: claimKey,
                sortOrder: 100 + index,
                claimedKeys: claimedKeys
            )
        }
    }

    private func makeWeeklyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        makeConfiguredRewards(
            from: RewardSchedule.weeklySources,
            category: .weekly,
            cycleKey: weekStart(for: day).key,
            sortOrderBase: 200,
            claimedKeys: claimedKeys
        )
    }

    private func makeMonthlyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        makeConfiguredRewards(
            from: RewardSchedule.monthlySources,
            category: .monthly,
            cycleKey: monthStart(for: day).key,
            sortOrderBase: 250,
            claimedKeys: claimedKeys
        )
    }

    private func makeConfiguredRewards(
        from sources: [RewardSourceDefinition],
        category: RewardCategory,
        cycleKey: String,
        sortOrderBase: Int,
        claimedKeys: Set<String>
    ) -> [RewardItem] {
        sources.enumerated().map { index, source in
            let claimKey = "\(source.id)-\(cycleKey)"
            return makeRewardItem(
                category: category,
                title: source.title,
                displayValue: source.value,
                claimKey: claimKey,
                sortOrder: sortOrderBase + index,
                claimedKeys: claimedKeys
            )
        }
    }

    private func makeRewardItem(
        id: String? = nil,
        category: RewardCategory,
        title: String,
        footnote: String? = nil,
        displayValue: RewardValue,
        claimValue: RewardValue? = nil,
        claimSource: String? = nil,
        claimKey: String,
        sortOrder: Int,
        claimedKeys: Set<String>
    ) -> RewardItem {
        RewardItem(
            id: id ?? claimKey,
            category: category,
            title: title,
            footnote: footnote,
            displayValue: displayValue,
            claimValue: claimValue ?? displayValue,
            claimSource: claimSource ?? title,
            claimKey: claimKey,
            sortOrder: sortOrder,
            isClaimed: claimedKeys.contains(claimKey)
        )
    }

    private func makeTimedMonthlyRewards(for day: DayStamp, claimedKeys: Set<String>) -> [RewardItem] {
        RewardSchedule.timedMonthlySources.enumerated().compactMap { index, source in
            guard isWithinTimedMonthlyWindow(day: day, targetDay: source.dayOfMonth, visibleDays: source.visibleDays) else {
                return nil
            }

            let monthStart = monthStart(for: day)
            let claimKey = "\(source.id)-\(monthStart.key)"
            return makeRewardItem(
                category: .monthly,
                title: source.title,
                displayValue: source.value,
                claimKey: claimKey,
                sortOrder: 275 + index,
                claimedKeys: claimedKeys
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
        let weeklyTitle = "暗域·第\(currentSeason)期第\(weekIndex)周"
        rewards.append(
            makeRewardItem(
                category: .darkZone,
                title: weeklyTitle,
                displayValue: RewardSchedule.darkZoneWeeklyValue,
                claimKey: weeklyClaimKey,
                sortOrder: 300,
                claimedKeys: claimedKeys
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
                let title = "暗域·第\(season)期赛季奖励"
                rewards.append(
                    makeRewardItem(
                        category: .darkZone,
                        title: title,
                        displayValue: RewardSchedule.darkZoneSeasonOpeningBonus,
                        claimKey: claimKey,
                        sortOrder: 301 + season,
                        claimedKeys: claimedKeys
                    )
                )
            }
        }

        return rewards
    }

    private func makeEventTrialReward(for currentDate: Date, claimedKeys: Set<String>) -> RewardItem? {
        let activeEventBanners = RewardSchedule.pullPlanBanners
            .filter { $0.title == RewardSchedule.activityPoolTitle && $0.isActive(at: currentDate, calendar: calendar) }
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
        let rewardTitle = "试用·\(title)"

        return makeRewardItem(
            category: .eventTrial,
            title: rewardTitle,
            displayValue: value,
            claimKey: claimKey,
            sortOrder: 290,
            claimedKeys: claimedKeys
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
            let title = "\(window.title) Day \(dayIndex)"
            return makeRewardItem(
                category: .dataGap,
                title: title,
                displayValue: window.dailyValue,
                claimKey: claimKey,
                sortOrder: 400,
                claimedKeys: claimedKeys
            )
        }

        return nil
    }

    private func makeManualUnknownRewards(
        now: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> [ManualUnknownReward] {
        RewardSchedule.manualUnknownSources.map { source in
            let version = manualCycleVersions[source.id] ?? 0
            let claimKey = manualUnknownClaimKey(for: source.id, version: version, now: now)
            return ManualUnknownReward(
                id: source.id,
                title: source.title,
                value: source.value,
                claimSource: source.title,
                claimKey: claimKey,
                cycleVersion: version,
                remainingText: manualUnknownRemainingText(for: source.id, now: now),
                showsAdvanceCycleButton: source.showsAdvanceCycleButton,
                isClaimed: claimedKeys.contains(claimKey)
            )
        }
    }

    private func manualUnknownClaimKey(for sourceID: String, version: Int, now: Date) -> String {
        if sourceID == RewardSchedule.emotionRandomSourceID {
            return "\(sourceID)-\(monthStart(for: DayStamp.rewardDay(from: now, calendar: calendar)).key)"
        }
        return "\(sourceID)-manual-v\(version)"
    }

    private func makeSecretPassProgress(
        now: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int],
        hasPremiumSecretPass: Bool
    ) -> SecretPassProgress {
        let definition = RewardSchedule.secretPassDefinition
        return makeProgress(
            id: definition.id,
            kind: definition.kind,
            title: definition.title,
            slotValue: hasPremiumSecretPass
                ? RewardValue(blueTickets: definition.slotValue.blueTickets * 2)
                : definition.slotValue,
            slotCount: definition.slotCount,
            remainingText: remainingText(
                until: preciseDate(
                    day: RewardSchedule.secretPassSeasonEnd,
                    hour: RewardSchedule.secretPassSeasonEndHour,
                    minute: RewardSchedule.secretPassSeasonEndMinute,
                    timeZoneIdentifier: RewardSchedule.secretPassSeasonTimeZoneIdentifier
                ),
                now: now,
                hourSuffix: "小时"
            ),
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions,
            isPremiumPurchased: hasPremiumSecretPass,
            showsCycleAdvanceButton: definition.showsCycleAdvanceButton
        )
    }

    private func makeMiniGameProgress(
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        let definition = RewardSchedule.miniGameDefinition
        return makeProgress(
            id: definition.id,
            kind: definition.kind,
            title: definition.title,
            slotValue: definition.slotValue,
            slotCount: definition.slotCount,
            remainingText: nil,
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: definition.showsCycleAdvanceButton
        )
    }

    private func makeMainlineSignInProgress(
        now: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        let definition = RewardSchedule.mainlineSignInDefinition
        guard let anchor = currentPermanentRewardAnchor(at: now),
              permanentRewardPoolBanners(for: anchor).count >= 2 else {
            return makeProgress(
                id: definition.id,
                kind: definition.kind,
                title: definition.title,
                slotValue: definition.slotValue,
                slotCount: 0,
                remainingText: nil,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions,
                isPremiumPurchased: false,
                showsCycleAdvanceButton: definition.showsCycleAdvanceButton
            )
        }

        return makeTimedSignInProgress(
            definition: definition,
            anchor: anchor,
            now: now,
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions
        )
    }

    private func makeAnniversarySignInProgress(
        now: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        let definition = RewardSchedule.anniversarySignInDefinition
        guard let anchor = currentPermanentRewardAnchor(at: now),
              anchor.title == "限定池" else {
            return makeProgress(
                id: definition.id,
                kind: definition.kind,
                title: definition.title,
                slotValue: definition.slotValue,
                slotCount: 0,
                remainingText: nil,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions,
                isPremiumPurchased: false,
                showsCycleAdvanceButton: definition.showsCycleAdvanceButton
            )
        }

        return makeTimedSignInProgress(
            definition: definition,
            anchor: anchor,
            now: now,
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions
        )
    }

    private func makeTimedSignInProgress(
        definition: ProgressModuleDefinition,
        anchor: PullPlanBanner,
        now: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        let cycleID = "\(definition.id)-\(anchor.id)"
        let cycleStart = anchor.startsAt(in: calendar)
        let cycleEnd = anchor.endsAt(in: calendar)
        let cycleStartDay = DayStamp.from(cycleStart, calendar: calendar)
        let currentDay = DayStamp.rewardDay(from: now, calendar: calendar)
        let unlockDays = RewardSchedule.mainlineSignInUnlockDays.map { day in
            let date = calendar.date(byAdding: .day, value: day - 1, to: cycleStartDay.date(in: calendar)) ?? cycleStartDay.date(in: calendar)
            return DayStamp.from(date, calendar: calendar)
        }

        // 主线签到从第九天才出现；周期结束后由当前卡池锚点自动隐藏。
        guard currentDay >= unlockDays[0] else {
            return makeProgress(
                id: cycleID,
                kind: definition.kind,
                title: definition.title,
                slotValue: definition.slotValue,
                slotCount: 0,
                remainingText: nil,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions,
                isPremiumPurchased: false,
                showsCycleAdvanceButton: definition.showsCycleAdvanceButton
            )
        }

        let version = manualCycleVersions[cycleID] ?? 0
        let claimKeys = (1...definition.slotCount).map { index in
            "\(cycleID)-v\(version)-slot-\(index)"
        }
        var unlockedSlots = Set<Int>()
        if currentDay >= unlockDays[0] {
            unlockedSlots.insert(1)
        }
        if currentDay >= unlockDays[1], claimedKeys.contains(claimKeys[0]) {
            unlockedSlots.insert(2)
        }
        if currentDay >= unlockDays[2], claimedKeys.contains(claimKeys[1]) {
            unlockedSlots.insert(3)
        }

        return makeProgress(
            id: cycleID,
            kind: definition.kind,
            title: definition.title,
            slotValue: definition.slotValue,
            slotCount: definition.slotCount,
            remainingText: remainingText(until: cycleEnd, now: now, hourSuffix: "时"),
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: definition.showsCycleAdvanceButton,
            unlockedSlotIndices: unlockedSlots
        )
    }

    private func makeRedemptionCodeProgress(
        now: Date,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int]
    ) -> SecretPassProgress {
        let definition = RewardSchedule.redemptionCodeDefinition
        guard let anchor = currentPermanentRewardAnchor(at: now) else {
            return makeProgress(
                id: definition.id,
                kind: definition.kind,
                title: definition.title,
                slotValue: definition.slotValue,
                slotCount: definition.slotCount,
                remainingText: nil,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions,
                isPremiumPurchased: false,
                showsCycleAdvanceButton: definition.showsCycleAdvanceButton
            )
        }

        let title = "兑换码·\(permanentRewardPoolTitle(for: anchor))"
        let activeStart = preciseDate(
            day: anchor.start,
            hour: RewardSchedule.redemptionCodeStartHour,
            minute: RewardSchedule.redemptionCodeStartMinute
        )
        let end = activeStart.addingTimeInterval(RewardSchedule.redemptionCodeDuration)
        let slotCount = isEnhancedPermanentRewardPool(anchor) ? 3 : 1
        let cycleID = "\(definition.id)-\(anchor.id)"

        guard activeStart <= now, now < end else {
            return makeProgress(
                id: cycleID,
                kind: definition.kind,
                title: title,
                slotValue: definition.slotValue,
                slotCount: 0,
                remainingText: nil,
                claimedKeys: claimedKeys,
                manualCycleVersions: manualCycleVersions,
                isPremiumPurchased: false,
                showsCycleAdvanceButton: definition.showsCycleAdvanceButton
            )
        }

        return makeProgress(
            id: cycleID,
            kind: definition.kind,
            title: title,
            slotValue: definition.slotValue,
            slotCount: slotCount,
            remainingText: remainingText(until: end, now: now, hourSuffix: "时"),
            claimedKeys: claimedKeys,
            manualCycleVersions: manualCycleVersions,
            isPremiumPurchased: false,
            showsCycleAdvanceButton: definition.showsCycleAdvanceButton
        )
    }

    private func makeProgress(
        id: String,
        kind: ProgressModuleKind,
        title: String,
        slotValue: RewardValue,
        slotCount: Int,
        remainingText: String?,
        claimedKeys: Set<String>,
        manualCycleVersions: [String: Int],
        isPremiumPurchased: Bool,
        showsCycleAdvanceButton: Bool,
        unlockedSlotIndices: Set<Int>? = nil
    ) -> SecretPassProgress {
        let version = manualCycleVersions[id] ?? 0
        let slots: [SecretPassSlot] = slotCount == 0
            ? []
            : (1...slotCount).map { index in
                let baseClaimKey = "\(id)-v\(version)-slot-\(index)"
                let premiumClaimKey = "\(id)-v\(version)-slot-\(index)-premium"
                return SecretPassSlot(
                    id: baseClaimKey,
                    index: index,
                    baseClaimKey: baseClaimKey,
                    premiumClaimKey: premiumClaimKey,
                    isClaimed: claimedKeys.contains(baseClaimKey),
                    isUnlocked: unlockedSlotIndices?.contains(index) ?? true
                )
            }

        return SecretPassProgress(
            id: id,
            kind: kind,
            title: title,
            slotValue: slotValue,
            cycleVersion: version,
            slots: slots,
            remainingText: remainingText,
            isPremiumPurchased: isPremiumPurchased,
            showsCycleAdvanceButton: showsCycleAdvanceButton
        )
    }

    private func manualUnknownRemainingText(for sourceID: String, now: Date) -> String? {
        guard sourceID == RewardSchedule.dataGapManualSourceID else { return nil }
        return remainingText(
            until: preciseDate(
                day: RewardSchedule.dataGapCurrentSeasonEnd,
                hour: RewardSchedule.dataGapCurrentSeasonEndHour,
                minute: RewardSchedule.dataGapCurrentSeasonEndMinute
            ),
            now: now,
            hourSuffix: "时"
        )
    }

    private func preciseDate(
        day: DayStamp,
        hour: Int,
        minute: Int,
        timeZoneIdentifier: String? = nil
    ) -> Date {
        var resolvedCalendar = calendar
        if let timeZoneIdentifier, let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            resolvedCalendar.timeZone = timeZone
        }

        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return resolvedCalendar.date(from: components) ?? day.date(in: resolvedCalendar)
    }

    private func remainingText(
        until targetDate: Date,
        now: Date,
        hourSuffix: String
    ) -> String? {
        let interval = Int(max(0, targetDate.timeIntervalSince(now)))
        guard interval > 0 else { return nil }

        let days = interval / 86_400

        if days > 0 {
            return "\(days)天"
        }

        if interval >= 3_600 {
            let hours = Int(ceil(Double(interval) / 3_600.0))
            return "\(hours)\(hourSuffix)"
        }

        let minutes = max(1, interval / 60)
        return "\(minutes)分"
    }

    private func sortCurrentRewards(_ rewards: [RewardItem]) -> [RewardItem] {
        rewards.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
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
