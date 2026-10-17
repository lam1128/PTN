import SwiftUI
import AppKit

enum WidgetPalette {
    static let titlePrimary = Color(red: 0.34, green: 0.15, blue: 0.22)
    static let titleSecondary = Color(red: 0.44, green: 0.21, blue: 0.30)
    static let accent = Color(red: 0.46, green: 0.17, blue: 0.29)
    static let accentSoft = Color(red: 0.50, green: 0.24, blue: 0.35)
    static let accentMuted = Color(red: 0.52, green: 0.26, blue: 0.36)
    static let accentLight = Color(red: 0.56, green: 0.35, blue: 0.43)
    static let mutedText = Color(red: 0.54, green: 0.31, blue: 0.40)
    static let claimed = Color(red: 0.58, green: 0.36, blue: 0.43)
    static let pink = Color(red: 0.87, green: 0.31, blue: 0.55)
    static let pinkStrong = Color(red: 0.82, green: 0.30, blue: 0.53)
    static let unchecked = Color(red: 0.65, green: 0.42, blue: 0.51)
    static let completed = Color(red: 0.34, green: 0.67, blue: 0.61)
    static let completedText = Color(red: 0.27, green: 0.47, blue: 0.43)
    static let completedSoft = Color(red: 0.35, green: 0.58, blue: 0.53)
    static let progressOrange = Color(red: 0.93, green: 0.50, blue: 0.22)
    static let progressPurple = Color(red: 0.54, green: 0.34, blue: 0.76)
    static let progressBlue = Color(red: 0.24, green: 0.54, blue: 0.82)
    static let cardCompletedFill = Color(red: 0.83, green: 0.95, blue: 0.91).opacity(0.34)
    static let overlayFill = Color.white.opacity(0.58)
    static let overlayStroke = Color.white.opacity(0.62)
    static let cardStroke = Color.white.opacity(0.34)
    static let capsuleStroke = Color.white.opacity(0.30)
    static let pityBorder = Color(red: 0.82, green: 0.56, blue: 0.67)
}

private enum WidgetPopupLayer {
    static let dismissArea: Double = 10
    static let popup: Double = 20
}

extension View {
    func widgetRoundedCard(
        cornerRadius: CGFloat = 16,
        fill: Color,
        stroke: Color = WidgetPalette.cardStroke
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        }
    }

    func widgetOverlayPanelCard(
        cornerRadius: CGFloat = 22,
        fill: Color = WidgetPalette.overlayFill
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(WidgetPalette.overlayStroke, lineWidth: 1)
        }
    }
}

struct WidgetPopupContainer<Content: View>: View {
    let cornerRadius: CGFloat
    let fill: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowY: CGFloat
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = 22,
        fill: Color = WidgetPalette.overlayFill,
        shadowColor: Color = Color.black.opacity(0.08),
        shadowRadius: CGFloat = 14,
        shadowY: CGFloat = 6,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.fill = fill
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.content = content()
    }

    var body: some View {
        content
            .widgetOverlayPanelCard(cornerRadius: cornerRadius, fill: fill)
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }
}

struct PopupChevronIcon: View {
    enum Style {
        case summary
        case module

        var fontSize: CGFloat {
            switch self {
            case .summary: return 11
            case .module: return 9
            }
        }

        var hitSize: CGFloat {
            switch self {
            case .summary: return 24
            case .module: return 30
            }
        }
    }

    let isExpanded: Bool
    let color: Color
    var style: Style = .module

    var body: some View {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: style.fontSize, weight: .bold))
            .foregroundStyle(color)
            .frame(width: style.hitSize, height: style.hitSize)
            .contentShape(Rectangle())
            .padding(.horizontal, (16 - style.hitSize) / 2)
            .padding(.vertical, (24 - style.hitSize) / 2)
    }
}

struct MainWidgetView: View {
    @ObservedObject var store: AppStateStore
    @StateObject private var giftCodeStore = GiftCodeStore()
    @StateObject private var pullPlanSyncStore = PullPlanSyncStore()

    @State private var activeSheet: ActiveSheet?
    @State private var selectedPrimarySection: PrimarySection = .currentPeriod
    @State private var expandedPullPlanBannerIDs: Set<String> = []
    @State private var isUpListExpanded = false
    @State private var isGiftCodeListExpanded = false
    @State private var currentPeriodScrollOffset: CGFloat = 0
    @State private var permanentRewardsScrollOffset: CGFloat = 0
    @State private var pullPlanScrollOffset: CGFloat = 0
    @State private var pullPlanRecordScrollOffset: CGFloat = 0
    @AppStorage("ptn.lastConsumptionAdjustmentSource") private var lastConsumptionAdjustmentSource = ""
    @AppStorage("ptn.lastIncreaseAdjustmentSource") private var lastIncreaseAdjustmentSource = ""
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let upPopupWidth: CGFloat = 260
    private let giftCodePopupWidth: CGFloat = 260
    private let pullPlanPopupWidth: CGFloat = 260

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.opacity(0.002)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.97).opacity(store.usesExtraTranslucentBackground ? 0.24 : 0.62),
                                Color(red: 0.97, green: 0.89, blue: 0.93).opacity(store.usesExtraTranslucentBackground ? 0.16 : 0.50),
                                Color(red: 0.95, green: 0.85, blue: 0.91).opacity(store.usesExtraTranslucentBackground ? 0.10 : 0.42)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(store.usesExtraTranslucentBackground ? 0.08 : 0.24),
                                Color.white.opacity(store.usesExtraTranslucentBackground ? 0.02 : 0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        headerSection

                        primarySectionTabs

                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.14),
                                        Color(red: 0.84, green: 0.60, blue: 0.72).opacity(0.88),
                                        Color.white.opacity(0.14)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1.5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    Group {
                        switch selectedPrimarySection {
                        case .currentPeriod:
                            ManagedScrollView(scrollOffset: $currentPeriodScrollOffset) {
                                VStack(alignment: .leading, spacing: 14) {
                                    currentPeriodSection
                                    manualUnknownSection
                                    footerSection
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                    .padding(.bottom, 16)
                            }
                        case .permanentRewards:
                            ManagedScrollView(scrollOffset: $permanentRewardsScrollOffset) {
                                VStack(alignment: .leading, spacing: 14) {
                                    permanentRewardsSection
                                    footerSection
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 16)
                            }
                        case .pullPlan:
                            ManagedScrollView(scrollOffset: $pullPlanScrollOffset) {
                                VStack(alignment: .leading, spacing: 14) {
                                    pullPlanSection
                                    footerSection
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 16)
                            }
                        case .pullPlanRecords:
                            ManagedScrollView(scrollOffset: $pullPlanRecordScrollOffset) {
                                VStack(alignment: .leading, spacing: 14) {
                                    pullPlanRecordSection
                                    footerSection
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                }
                .blur(radius: activeSheet == nil ? 0 : 2)
                .opacity(activeSheet == nil ? 1 : 0.28)
                .animation(.easeInOut(duration: 0.14), value: activeSheet)

                if isUpListExpanded || isGiftCodeListExpanded {
                    Rectangle()
                        .fill(Color.black.opacity(0.001))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isUpListExpanded = false
                            isGiftCodeListExpanded = false
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                        .zIndex(WidgetPopupLayer.dismissArea)
                }

                if let activeSheet {
                    Color.black.opacity(0.24)
                        .ignoresSafeArea()
                        .onTapGesture {
                            self.activeSheet = nil
                        }

                    panelView(for: activeSheet)
                        .padding(12)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

            }
            .coordinateSpace(name: "widgetRoot")
            .overlayPreferenceValue(UpChevronAnchorPreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    if isUpListExpanded, let anchor = anchors.first {
                        upListPopup
                            .offset(
                                x: popupOriginX(
                                    anchorX: proxy[anchor].minX,
                                    popupWidth: upPopupWidth,
                                    totalWidth: proxy.size.width
                                ),
                                y: proxy[anchor].maxY + 8
                            )
                            .zIndex(WidgetPopupLayer.popup)
                    }
                }
            }
            .overlayPreferenceValue(GiftCodeChevronAnchorPreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    if isGiftCodeListExpanded, let anchor = anchors.first {
                        let frame = proxy[anchor]
                        giftCodeListPopup
                            .offset(
                                x: popupOriginX(
                                    anchorX: frame.minX,
                                    popupWidth: giftCodePopupWidth,
                                    totalWidth: proxy.size.width
                                ),
                                y: popupOriginY(
                                    anchor: frame,
                                    popupHeight: giftCodePopupHeight,
                                    totalHeight: proxy.size.height
                                )
                            )
                            .zIndex(WidgetPopupLayer.popup)
                    }
                }
            }
            .overlayPreferenceValue(PullPlanSelectionAnchorPreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    if let bannerID = expandedPullPlanBannerIDs.first,
                       let anchor = anchors.first(where: { $0.id == bannerID }),
                       let banner = RewardSchedule.pullPlanBanners.first(where: { $0.id == bannerID }) {
                        PullPlanSelectionPopup(
                            banner: banner,
                            selectedUpCharacter: store.selectedPullPlanUpChoices[banner.id],
                            selectedLockLevel: store.selectedPullPlanLockChoices[banner.id],
                            selectedCharacterLockLevels: store.pullPlanCharacterLockLevels(for: banner),
                            onToggleUpCharacter: { character in
                                store.togglePullPlanUpChoice(bannerID: banner.id, character: character)
                                expandedPullPlanBannerIDs.removeAll()
                            },
                            onToggleLockLevel: { lockLevel in
                                store.togglePullPlanLockChoice(bannerID: banner.id, lockLevel: lockLevel)
                                expandedPullPlanBannerIDs.removeAll()
                            },
                            onSetCharacterLockLevel: { character, lockLevel in
                                store.setPullPlanCharacterLockChoice(
                                    bannerID: banner.id,
                                    character: character,
                                    lockLevel: lockLevel
                                )
                                expandedPullPlanBannerIDs.removeAll()
                            }
                        )
                        .offset(
                            x: popupOriginX(
                                anchorX: proxy[anchor.anchor].minX,
                                popupWidth: pullPlanPopupWidth,
                                totalWidth: proxy.size.width
                            ),
                            y: popupOriginY(
                                anchor: proxy[anchor.anchor],
                                popupHeight: pullPlanPopupHeight(for: banner),
                                totalHeight: proxy.size.height
                            )
                        )
                        .zIndex(WidgetPopupLayer.popup)
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                WindowDragHandle()
                    .frame(height: 18)
            }
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.clear)
        }
        .frame(width: 340, height: 430)
        .onAppear {
            store.refreshRewards()
            store.autoClaimDailyRewardsIfNeeded()
            giftCodeStore.refreshIfNeeded()
            pullPlanSyncStore.refreshIfNeeded()
        }
        .onReceive(refreshTimer) { now in
            store.refreshRewards(now: now)
            store.autoClaimDailyRewardsIfNeeded(now: now)
            giftCodeStore.refreshIfNeeded(now: now)
            pullPlanSyncStore.refreshIfNeeded(now: now)
            closeGiftCodeListIfEmpty()
        }
        .onChange(of: pullPlanSyncStore.revision) {
            store.refreshRewards()
        }
        .onChange(of: giftCodeStore.codes) {
            closeGiftCodeListIfEmpty()
        }
        .animation(.easeInOut(duration: 0.16), value: activeSheet)
    }

    private func closeGiftCodeListIfEmpty() {
        if visibleGiftCodes.isEmpty {
            isGiftCodeListExpanded = false
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                HStack(alignment: .top, spacing: 18) {
                    summaryMetric(
                        title: "总抽数",
                        value: store.totalDrawCountFloor.formatted(.number.grouping(.automatic))
                    )

                    upSummaryMetric
                }

                Spacer(minLength: 0)

                HStack(alignment: .center, spacing: 8) {
                    Text(DayStamp.rewardDay(from: Date()).key)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.accentSoft)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.32), in: Capsule())

                    Button {
                        activeSheet = .editInventory
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .offset(x: -1)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.34), in: Circle())
                            .foregroundStyle(WidgetPalette.accentSoft)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Text("蓝票：\(store.totalBlueTickets)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.accentSoft)

                Text("红票：\(store.totalRedTickets)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.accentSoft)

                Text("异方晶：\(store.totalCrystals)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.accentSoft)
            }
        }
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titleSecondary)

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.titlePrimary)
                .offset(y: 3)
        }
        .frame(minWidth: 58, alignment: .leading)
    }

    private var upSummaryMetric: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("UP数")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titleSecondary)

            Button {
                isGiftCodeListExpanded = false
                isUpListExpanded.toggle()
            } label: {
                HStack(spacing: 2) {
                    Text("\(store.totalPlannedUpCount)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.titlePrimary)
                        .offset(y: -1)

                    PopupChevronIcon(
                        isExpanded: isUpListExpanded,
                        color: WidgetPalette.accentSoft,
                        style: .summary
                    )
                        .anchorPreference(
                            key: UpChevronAnchorPreferenceKey.self,
                            value: .bounds
                        ) { [$0] }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(minWidth: 58, alignment: .leading)
    }

    private var primarySectionTabs: some View {
        HStack(spacing: 6) {
            primaryTabButton(.currentPeriod, title: "当前周期")
            primaryTabButton(.permanentRewards, title: "常驻奖励")
            primaryTabButton(.pullPlan, title: "抽卡规划")
            primaryTabButton(.pullPlanRecords, title: "抽卡记录")
        }
        .frame(maxWidth: .infinity)
    }

    private var currentPeriodSection: some View {
        let visibleRewards = store.currentRewards.filter { $0.category != .eventTrial }

        return VStack(alignment: .leading, spacing: 10) {
            if visibleRewards.isEmpty {
                Text("今天没有可显示的周期项")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                AutomaticStorageRowView(fullAt: store.automaticStorageFullAt)

                if !store.weeklyInspectionProgress.slots.isEmpty {
                    DailyProgressView(
                        progress: store.weeklyInspectionProgress,
                        onTapSlot: { slot in
                            store.toggleDailyProgressSlot(store.weeklyInspectionProgress, slot: slot)
                        },
                        onAdvanceCycle: {}
                    )
                }

                ForEach(visibleRewards) { reward in
                    RewardRowView(reward: reward) {
                        store.toggle(reward)
                    }
                }
            }
        }
    }

    private var manualUnknownSection: some View {
        let trialRewards = store.currentRewards
            .filter { $0.category == .eventTrial }
            .sorted { lhs, rhs in
                return lhs.sortOrder < rhs.sortOrder
            }

        let extraManualRewards = store.manualUnknownRewards.filter {
            !RewardSchedule.permanentManualSourceOrder.contains($0.id)
        }
        let dailyRewards = store.dailyExtraRewards
        let emotionRewards = extraManualRewards.filter { $0.id == RewardSchedule.emotionRandomSourceID }
        let dataGapRewards = extraManualRewards.filter { $0.id == RewardSchedule.dataGapManualSourceID }
        let remainingManualRewards = extraManualRewards.filter {
            $0.id != RewardSchedule.emotionRandomSourceID
                && $0.id != RewardSchedule.dataGapManualSourceID
        }
        let remainingProgressItems = [store.miniGameProgress, store.anniversarySignInProgress]
            .filter { !$0.slots.isEmpty }
        let emotionProgress = store.dailyProgresses.first {
            $0.id == RewardSchedule.dailyEmotionDetectionID
        }
        let dataGapProgress = store.dailyProgresses.first {
            $0.id == RewardSchedule.dataGapProgressID
        }
        let ashTideProgress = store.dailyProgresses.first {
            $0.id == RewardSchedule.ashTideProgressID
        }

        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("额外记录")

            ForEach(dailyRewards) { reward in
                rewardRow(reward)
            }

            if let emotionProgress {
                DailyProgressView(
                    progress: emotionProgress,
                    onTapSlot: { slot in
                        store.toggleDailyProgressSlot(emotionProgress, slot: slot)
                    },
                    onAdvanceCycle: {}
                )
            }

            ForEach(emotionRewards) { reward in
                manualRewardRow(reward)
            }

            if !store.secretPassProgress.slots.isEmpty {
                manualProgressView(for: store.secretPassProgress)
            }

            if let dataGapProgress {
                DailyProgressView(
                    progress: dataGapProgress,
                    onTapSlot: { slot in
                        store.toggleDailyProgressSlot(dataGapProgress, slot: slot)
                    },
                    onAdvanceCycle: {}
                )
            }

            if let ashTideProgress {
                DailyProgressView(
                    progress: ashTideProgress,
                    onTapSlot: { slot in
                        store.toggleDailyProgressSlot(ashTideProgress, slot: slot)
                    },
                    onAdvanceCycle: {}
                )
            }

            if !store.activityRerunProgress.slots.isEmpty {
                DailyProgressView(
                    progress: store.activityRerunProgress,
                    onTapSlot: { slot in
                        store.toggleDailyProgressSlot(store.activityRerunProgress, slot: slot)
                    },
                    onAdvanceCycle: {}
                )
            }

            ForEach(dataGapRewards) { reward in
                manualRewardRow(reward)
            }

            if !store.mainlineSignInProgress.slots.isEmpty {
                manualProgressView(for: store.mainlineSignInProgress)
            }

            ForEach(trialRewards) { reward in
                rewardRow(reward)
            }

            ForEach(remainingManualRewards) { reward in
                manualRewardRow(reward)
            }

            ForEach(remainingProgressItems, id: \.id) { progress in
                manualProgressView(for: progress)
            }
        }
    }

    private func rewardRow(_ reward: RewardItem) -> some View {
        RewardRowView(reward: reward) {
            store.toggle(reward)
        }
    }

    private func manualRewardRow(_ reward: ManualUnknownReward) -> some View {
        ManualUnknownRewardRowView(
            reward: reward,
            onClaim: { store.toggleManualUnknown(reward) },
            onAdvanceCycle: { store.advanceManualCycle(for: reward.id) }
        )
    }

    private var permanentRewardsSection: some View {
        let permanentRewards = store.permanentRewards.sorted { $0.sortOrder < $1.sortOrder }
        let manualRewards = store.manualUnknownRewards.filter {
            RewardSchedule.permanentManualSourceOrder.contains($0.id)
        }
        let manualRewardsByID = Dictionary(uniqueKeysWithValues: manualRewards.map { ($0.id, $0) })
        let orderedManualRewards = RewardSchedule.permanentManualSourceOrder.compactMap {
            manualRewardsByID[$0]
        }
        let redemptionCodeProgress = store.redemptionCodeProgress
        let giftCodes = visibleGiftCodes

        return VStack(alignment: .leading, spacing: 10) {
            // 常驻奖励不沉底：派遣和审查固定在最前面。
            ForEach(store.dailyProgresses.filter {
                $0.id != RewardSchedule.dataGapProgressID
                    && $0.id != RewardSchedule.ashTideProgressID
                    && $0.id != RewardSchedule.dailyEmotionDetectionID
            }) { progress in
                DailyProgressView(
                    progress: progress,
                    onTapSlot: { slot in
                        store.toggleDailyProgressSlot(progress, slot: slot)
                    },
                    onTapReviewStage: progress.id == RewardSchedule.dailyReviewID
                        ? { slot, stage in
                            store.toggleDailyReviewStage(progress, slot: slot, stage: stage)
                        }
                        : nil,
                    onAdvanceCycle: {
                        store.advanceDailyProgress(progress)
                    }
                )
            }

            if !redemptionCodeProgress.slots.isEmpty && !giftCodes.isEmpty {
                manualProgressView(
                    for: redemptionCodeProgress.withGiftCodeRewards(giftCodes)
                )
            }

            ForEach(permanentRewards) { reward in
                RewardRowView(reward: reward) {
                    store.toggle(reward)
                }
            }

            ForEach(orderedManualRewards) { reward in
                ManualUnknownRewardRowView(
                    reward: reward,
                    onClaim: { store.toggleManualUnknown(reward) },
                    onAdvanceCycle: { store.advanceManualCycle(for: reward.id) }
                )
            }

            ForEach(store.permanentProgresses) { progress in
                DailyProgressView(
                    progress: progress,
                    onTapSlot: { slot in
                        store.toggleDailyProgressSlot(progress, slot: slot)
                    },
                    onAdvanceCycle: {}
                )
            }
        }
    }

    private var pullPlanSection: some View {
        let currentDate = Date()
        let banners = RewardSchedule.pullPlanBanners
            .filter { $0.endsAt() > currentDate }
            .sorted { lhs, rhs in
                if lhs.isActive(at: currentDate) != rhs.isActive(at: currentDate) {
                    return lhs.isActive(at: currentDate)
                }
                return lhs.start < rhs.start
            }

        return VStack(alignment: .leading, spacing: 10) {
            if banners.isEmpty {
                Text("当前没有已填写的抽卡规划")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(banners) { banner in
                    let isActive = banner.isActive(at: currentDate)
                    let progress = store.pullPlanBannerProgress(for: banner.id, allowCompleted: isActive)
                    PullPlanBannerCardView(
                        banner: banner,
                        isActive: isActive,
                        currentDate: currentDate,
                        progress: progress,
                        pityValue: store.pullPlanPityValue(for: banner.id),
                        selectedUpCharacter: store.selectedPullPlanUpChoices[banner.id],
                        selectedLockLevel: store.selectedPullPlanLockChoices[banner.id],
                        selectedCharacterLockLevels: store.pullPlanCharacterLockLevels(for: banner),
                        isExpanded: expandedPullPlanBannerIDs.contains(banner.id),
                        onToggleBanner: { store.togglePullPlanBanner(banner.id, allowCompleted: isActive) },
                        onSetPityValue: { value in
                            store.setPullPlanPityValue(for: banner.id, value: value)
                        },
                        onToggleUpCharacter: { character in
                            store.togglePullPlanUpChoice(bannerID: banner.id, character: character)
                        },
                        onToggleLockLevel: { lockLevel in
                            store.togglePullPlanLockChoice(bannerID: banner.id, lockLevel: lockLevel)
                        },
                        onSetCharacterLockLevel: { character, lockLevel in
                            store.setPullPlanCharacterLockChoice(
                                bannerID: banner.id,
                                character: character,
                                lockLevel: lockLevel
                            )
                            expandedPullPlanBannerIDs.removeAll()
                        },
                        onOpenRecord: {
                            expandedPullPlanBannerIDs.removeAll()
                            activeSheet = .pullPlanRecord(banner.id)
                        },
                        onToggleExpand: {
                            if expandedPullPlanBannerIDs.contains(banner.id) {
                                expandedPullPlanBannerIDs.remove(banner.id)
                            } else {
                                expandedPullPlanBannerIDs = [banner.id]
                            }
                        }
                    )
                    .zIndex(
                        expandedPullPlanBannerIDs.contains(banner.id)
                            ? WidgetPopupLayer.popup
                            : 0
                    )
                }
            }
        }
    }

    private var pullPlanRecordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(store.pullPlanRecordSummaries) { summary in
                PullPlanRecordSummaryRow(summary: summary) {
                    activeSheet = .pullPlanRecordDetails(summary.id)
                }
            }

            GeneralPoolRecordRow(record: store.generalPoolRecord) {
                activeSheet = .generalPoolRecord
            }
        }
    }

    private var footerSection: some View {
        HStack(spacing: 8) {
            Button {
                activeSheet = .history
            } label: {
                Label("历史", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(.bordered)

            Button("消耗") {
                activeSheet = .consumption
            }
            .buttonStyle(.bordered)

            Button("增加") {
                activeSheet = .increase
            }
            .buttonStyle(.bordered)

            Spacer(minLength: 0)

            if let todayTotal = store.todayCrystalEquivalentText {
                Text("今日：\(todayTotal)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.accentSoft)
            }
        }
        .padding(.top, 2)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
    }

    private func manualProgressView(for progress: SecretPassProgress) -> some View {
        SecretPassProgressView(
            progress: progress,
            onTapSlot: { slot in
                switch progress.kind {
                case .secretPass:
                    store.toggleSecretPassSlot(slot)
                case .redemptionCode:
                    store.toggleRedemptionCodeSlot(progress, slot: slot, value: slot.rewardValue)
                case .miniGame:
                    store.toggleMiniGameSlot(slot)
                case .photoExchange:
                    store.togglePhotoExchangeSlot(slot)
                case .mainlineSignIn:
                    store.toggleMainlineSignInSlot(progress, slot: slot)
                case .anniversarySignIn:
                    store.toggleAnniversarySignInSlot(progress, slot: slot)
                }
            },
            onTogglePremiumPurchased: progress.kind == .secretPass
                ? { isOn in store.setHasPremiumSecretPass(isOn) }
                : nil,
            onAdvanceCycle: progress.kind == .miniGame
                ? { store.advanceManualCycle(for: RewardSchedule.miniGameDefinition.id) }
                : nil,
            isGiftCodeListExpanded: progress.kind == .redemptionCode && isGiftCodeListExpanded,
            onToggleGiftCodeList: progress.kind == .redemptionCode
                ? {
                    isUpListExpanded = false
                    isGiftCodeListExpanded.toggle()
                    giftCodeStore.refreshIfNeeded()
                }
                : nil
        )
    }

    private var visibleGiftCodes: [GiftCode] {
        let currentDate = Date()
        let anchor = RewardSchedule.currentPermanentRewardAnchor(at: currentDate)
        let codes = giftCodeStore.activeCodes(
            from: anchor?.startsAt(),
            to: anchor?.endsAt(),
            limit: store.redemptionCodeProgress.displayedTotalCount
        )
        let rewardValue = store.redemptionCodeProgress.slotValue
        return codes.map { code in
            GiftCode(
                id: code.id,
                code: code.code,
                startsAt: code.startsAt,
                endsAt: code.endsAt,
                rewardValue: rewardValue
            )
        }
    }

    private var upListEntries: [UpListEntry] {
        let currentDate = Date()

        return RewardSchedule.pullPlanBanners
            .sorted { lhs, rhs in
                let lhsStart = lhs.startsAt()
                let rhsStart = rhs.startsAt()
                if lhsStart != rhsStart {
                    return lhsStart < rhsStart
                }
                return lhs.id < rhs.id
            }
            .flatMap { banner -> [UpListEntry] in
                guard banner.endsAt() > currentDate else { return [] }
                let progress = store.pullPlanBannerProgress(for: banner.id, allowCompleted: banner.isActive(at: currentDate))
                guard progress == .planned else { return [] }

                switch banner.selectionKind {
                case .none:
                    return [UpListEntry(
                        id: banner.id,
                        title: banner.title,
                        detail: banner.characters.first ?? "未命名"
                    )]
                case .targetChoice:
                    return [UpListEntry(
                        id: banner.id,
                        title: banner.title,
                        detail: store.selectedPullPlanUpChoices[banner.id] ?? banner.characters.joined(separator: " / ")
                    )]
                case .lockCount:
                    guard let lockLevel = store.selectedPullPlanLockChoices[banner.id] else { return [] }
                    return [UpListEntry(
                        id: banner.id,
                        title: banner.title,
                        detail: "\(banner.characters.first ?? "未命名") ×\(lockLevel + 1)"
                    )]
                case .multiLockCount:
                    let characterLocks = store.pullPlanCharacterLockLevels(for: banner)
                    return banner.characters.compactMap { character in
                        guard let lockLevel = characterLocks[character] else {
                            return nil
                        }
                        return UpListEntry(
                            id: "\(banner.id)-\(character)",
                            title: banner.title,
                            detail: "\(character) ×\(lockLevel + 1)"
                        )
                    }
                }
            }
    }

    private var upListPopup: some View {
        WidgetPopupContainer(
            cornerRadius: 14,
            fill: WidgetPalette.overlayFill,
            shadowColor: WidgetPalette.accentSoft.opacity(0.12),
            shadowRadius: 12,
            shadowY: 5
        ) {
            VStack(alignment: .leading, spacing: 8) {
                if upListEntries.isEmpty {
                    Text("当前没有UP记录")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.accentSoft)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 6),
                            GridItem(.flexible(), spacing: 6)
                        ],
                        alignment: .leading,
                        spacing: 6
                    ) {
                        ForEach(upListEntries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(WidgetPalette.titlePrimary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Text(entry.detail)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(WidgetPalette.titleSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.44),
                                            Color(red: 0.93, green: 0.96, blue: 1.00).opacity(0.16)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.46), lineWidth: 1)
                        }
                        }
                    }
                }
            }
            .padding(10)
            .frame(width: upPopupWidth, alignment: .leading)
        }
    }

    private var giftCodeListPopup: some View {
        WidgetPopupContainer(
            cornerRadius: 22,
            fill: WidgetPalette.overlayFill,
            shadowColor: WidgetPalette.accentSoft.opacity(0.12),
            shadowRadius: 12,
            shadowY: 5
        ) {
            GiftCodeListPopup(codes: visibleGiftCodes)
        }
            .frame(width: giftCodePopupWidth, height: giftCodePopupHeight)
    }

    private var giftCodePopupHeight: CGFloat {
        let rowCount = max(visibleGiftCodes.count, 1)
        return min(218, 20 + CGFloat(rowCount * 34) + CGFloat(max(rowCount - 1, 0) * 6))
    }

    private func popupOriginX(
        anchorX: CGFloat,
        popupWidth: CGFloat,
        totalWidth: CGFloat
    ) -> CGFloat {
        let padding: CGFloat = 12
        return min(
            max(anchorX - 8, padding),
            max(padding, totalWidth - popupWidth - padding)
        )
    }

    private func popupOriginY(
        anchor: CGRect,
        popupHeight: CGFloat,
        totalHeight: CGFloat
    ) -> CGFloat {
        let padding: CGFloat = 12
        let spacing: CGFloat = 6
        let below = anchor.maxY + spacing
        if below + popupHeight <= totalHeight - padding {
            return below
        }
        return max(padding, anchor.minY - popupHeight - spacing)
    }

    private func pullPlanPopupHeight(for banner: PullPlanBanner) -> CGFloat {
        let rowCount: Int
        switch banner.selectionKind {
        case .lockCount:
            rowCount = 3
        case .multiLockCount:
            rowCount = max(1, banner.characters.count)
        case .none, .targetChoice:
            rowCount = max(1, Int(ceil(Double(banner.characters.count) / 2.0)))
        }
        return 20 + CGFloat(rowCount * 32) + CGFloat(max(rowCount - 1, 0) * 8)
    }

    private func primaryTabButton(_ section: PrimarySection, title: String) -> some View {
        Button {
            isUpListExpanded = false
            isGiftCodeListExpanded = false
            selectedPrimarySection = section
        } label: {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        selectedPrimarySection == section
                        ? WidgetPalette.accent
                        : WidgetPalette.accentLight
                )
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            selectedPrimarySection == section
                                ? Color.white.opacity(0.42)
                                : Color.white.opacity(0.16)
                        )
                )
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(WidgetPalette.capsuleStroke, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func panelView(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .editInventory:
            WidgetPopupContainer {
                EditInventorySheet(
                    currentCrystals: store.totalCrystals,
                    currentBlueTickets: store.totalBlueTickets,
                    currentRedTickets: store.totalRedTickets
                ) { crystals, blueTickets, redTickets in
                    store.setInventory(
                        crystals: crystals,
                        blueTickets: blueTickets,
                        redTickets: redTickets
                    )
                    activeSheet = nil
                } onClose: {
                    activeSheet = nil
                }
            }
            .frame(width: 310)
        case .history:
            WidgetPopupContainer {
                HistorySheetView(
                    store: store,
                    onClose: { activeSheet = nil },
                    onShowStatistics: { activeSheet = .historyStatistics }
                )
            }
            .frame(width: 310, height: 270)
        case .historyStatistics:
            WidgetPopupContainer {
                HistoryIncomeStatisticsSheet(store: store) {
                    activeSheet = .history
                }
            }
            .frame(width: 310, height: 350)
        case .consumption:
            WidgetPopupContainer {
                CrystalAdjustmentSheet(
                    title: "消耗",
                    initialSource: lastConsumptionAdjustmentSource,
                    progressContent: {
                        SecretPassProgressView(
                            progress: store.photoExchangeProgress,
                            onTapSlot: { slot in
                                store.togglePhotoExchangeSlot(slot)
                            },
                            onTogglePremiumPurchased: nil,
                            onAdvanceCycle: {
                                store.advanceManualCycle(for: RewardSchedule.photoExchangeDefinition.id)
                            },
                            isGiftCodeListExpanded: false,
                            onToggleGiftCodeList: nil
                        )
                    },
                    onSave: { title, crystals in
                        lastConsumptionAdjustmentSource = title
                        store.recordManualCrystalAdjustment(
                            title: "消耗·\(title)",
                            crystals: -crystals
                        )
                        activeSheet = nil
                    },
                    onClose: { activeSheet = nil }
                )
            }
            .frame(width: 310)
        case .increase:
            WidgetPopupContainer {
                InventoryIncreaseSheet(
                    initialSource: lastIncreaseAdjustmentSource,
                    onSave: { title, value in
                        lastIncreaseAdjustmentSource = title
                        store.recordManualAdjustment(
                            title: "增加·\(title)",
                            value: value
                        )
                        activeSheet = nil
                    },
                    onClose: { activeSheet = nil }
                )
            }
            .frame(width: 310)
        case .pullPlanRecord(let bannerID):
            let record = store.pullPlanTicketRecord(for: bannerID)
            WidgetPopupContainer {
                PullPlanTicketRecordSheet(
                    bannerTitle: RewardSchedule.pullPlanBanners.first(where: { $0.id == bannerID })?.title ?? "卡池",
                    currentGiftTickets: record.giftTickets,
                    currentBlueTickets: record.blueTickets,
                    availableBlueTickets: store.availableBlueTicketsForPullPlanRecord(bannerID),
                    currentUpCount: record.upCount,
                    currentUpTotal: record.upTotal,
                    currentNonUpCharacters: record.nonUpCharacters
                ) { giftTickets, blueTickets, upCount, upTotal, nonUpCharacters in
                    store.setPullPlanTicketRecord(
                        for: bannerID,
                        giftTickets: giftTickets,
                        blueTickets: blueTickets,
                        upCount: upCount,
                        upTotal: upTotal,
                        nonUpCharacters: nonUpCharacters
                    )
                    activeSheet = nil
                } onClose: {
                    activeSheet = nil
                }
            }
            .frame(width: 286)
        case .pullPlanRecordDetails(let poolTitle):
            WidgetPopupContainer {
                PullPlanRecordDetailsSheet(
                    poolTitle: poolTitle,
                    details: store.pullPlanRecordDetails(for: poolTitle),
                    onClose: { activeSheet = nil }
                )
            }
            .frame(width: 310, height: 270)
        case .generalPoolRecord:
            WidgetPopupContainer {
                GeneralPoolRecordSheet(
                    currentRecord: store.generalPoolRecord,
                    onSave: { blueTickets, redTickets, upCharacters in
                        store.setGeneralPoolRecord(
                            blueTickets: blueTickets,
                            redTickets: redTickets,
                            upCharacters: upCharacters
                        )
                        activeSheet = nil
                    },
                    onClose: { activeSheet = nil }
                )
            }
            .frame(width: 286)
        }
    }
}
