import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

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

private extension View {
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

private struct WidgetPopupContainer<Content: View>: View {
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

private struct PopupChevronIcon: View {
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
    @StateObject private var oneDriveSync = OneDriveStateSync()

    @State private var activeSheet: ActiveSheet?
    @State private var selectedPrimarySection: PrimarySection = .currentPeriod
    @State private var expandedPullPlanBannerIDs: Set<String> = []
    @State private var isUpListExpanded = false
    @State private var isGiftCodeListExpanded = false
    @State private var currentPeriodScrollOffset: CGFloat = 0
    @State private var permanentRewardsScrollOffset: CGFloat = 0
    @State private var pullPlanScrollOffset: CGFloat = 0
    @State private var pullPlanRecordScrollOffset: CGFloat = 0
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let upPopupWidth: CGFloat = 150
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
#if os(macOS)
                            NSApp.keyWindow?.makeFirstResponder(nil)
#endif
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
                                x: proxy[anchor].minX - 3,
                                y: proxy[anchor].minY + 20
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
                            onToggleUpCharacter: { character in
                                store.togglePullPlanUpChoice(bannerID: banner.id, character: character)
                                expandedPullPlanBannerIDs.removeAll()
                            },
                            onToggleLockLevel: { lockLevel in
                                store.togglePullPlanLockChoice(bannerID: banner.id, lockLevel: lockLevel)
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
#if os(macOS)
        .frame(width: 340, height: 430)
#else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
        .onAppear {
            store.refreshRewards()
            giftCodeStore.refreshIfNeeded()
            pullPlanSyncStore.refreshIfNeeded()
            oneDriveSync.start(store: store)
        }
        .onReceive(refreshTimer) { now in
            store.refreshRewards(now: now)
            giftCodeStore.refreshIfNeeded(now: now)
            pullPlanSyncStore.refreshIfNeeded(now: now)
            oneDriveSync.refreshIfNeeded()
        }
        .onChange(of: pullPlanSyncStore.revision) {
            store.refreshRewards()
        }
        .animation(.easeInOut(duration: 0.16), value: activeSheet)
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
        let dataGapProgress = store.dailyProgresses.first {
            $0.id == RewardSchedule.dataGapProgressID
        }

        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("额外记录")

            ForEach(dailyRewards) { reward in
                rewardRow(reward)
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

            DailyProgressView(
                progress: store.activityRerunProgress,
                onTapSlot: { slot in
                    store.toggleDailyProgressSlot(store.activityRerunProgress, slot: slot)
                },
                onAdvanceCycle: {}
            )

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

        return VStack(alignment: .leading, spacing: 10) {
            // 常驻奖励不沉底：派遣和审查固定在最前面。
            ForEach(store.dailyProgresses.filter {
                $0.id != RewardSchedule.dataGapProgressID
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

            if !redemptionCodeProgress.slots.isEmpty {
                manualProgressView(for: redemptionCodeProgress)
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
                PullPlanRecordSummaryRow(summary: summary)
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
                    store.toggleRedemptionCodeSlot(progress, slot: slot)
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
        let anchorStart = RewardSchedule.currentPermanentRewardAnchor(at: Date())?.startsAt()
        return giftCodeStore.activeCodes(
            for: anchorStart,
            limit: store.redemptionCodeProgress.displayedTotalCount
        )
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
            .compactMap { banner in
                let progress = store.pullPlanBannerProgress(for: banner.id, allowCompleted: banner.isActive(at: currentDate))
                guard progress == .planned else { return nil }

                switch banner.selectionKind {
                case .none:
                    return UpListEntry(
                        id: banner.id,
                        title: banner.title,
                        detail: banner.characters.first ?? "未命名"
                    )
                case .targetChoice:
                    return UpListEntry(
                        id: banner.id,
                        title: banner.title,
                        detail: store.selectedPullPlanUpChoices[banner.id] ?? banner.characters.joined(separator: " / ")
                    )
                case .lockCount:
                    guard let lockLevel = store.selectedPullPlanLockChoices[banner.id] else { return nil }
                    return UpListEntry(
                        id: banner.id,
                        title: banner.title,
                        detail: "\(banner.characters.first ?? "未命名") ×\(lockLevel + 1)"
                    )
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
                                .lineLimit(1)
                                .truncationMode(.tail)
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
        let rowCount = banner.selectionKind == .lockCount
            ? 3
            : max(1, Int(ceil(Double(banner.characters.count) / 2.0)))
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
                CrystalAdjustmentSheet(
                    title: "增加",
                    progressContent: { EmptyView() },
                    onSave: { title, crystals in
                        store.recordManualCrystalAdjustment(
                            title: "增加·\(title)",
                            crystals: crystals
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
                    currentUpTotal: record.upTotal
                ) { giftTickets, blueTickets, upCount, upTotal in
                    store.setPullPlanTicketRecord(
                        for: bannerID,
                        giftTickets: giftTickets,
                        blueTickets: blueTickets,
                        upCount: upCount,
                        upTotal: upTotal
                    )
                    activeSheet = nil
                } onClose: {
                    activeSheet = nil
                }
            }
            .frame(width: 286)
        case .generalPoolRecord:
            WidgetPopupContainer {
                GeneralPoolRecordSheet(
                    currentRecord: store.generalPoolRecord,
                    onSave: { blueTickets, redTickets, upCount in
                        store.setGeneralPoolRecord(
                            blueTickets: blueTickets,
                            redTickets: redTickets,
                            upCount: upCount
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

private struct RewardRowView: View {
    let reward: RewardItem
    let onClaim: () -> Void

    var body: some View {
        Button(action: onClaim) {
            HStack(spacing: 10) {
                RewardCircle(isFilled: reward.isClaimed)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(reward.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.titlePrimary)

                        Spacer(minLength: 0)

                        if let footnote = reward.footnote {
                            Text(footnote)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.accentSoft)
                        }

                        Text(reward.displayValue.inlineDescription(withPlusSign: true))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.accent)
                    }

                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .widgetRoundedCard(fill: reward.isClaimed ? Color.white.opacity(0.10) : Color.white.opacity(0.18))
        }
        .buttonStyle(.plain)
    }
}

private struct AutomaticStorageRowView: View {
    let fullAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 10) {
                RewardCircle(
                    isFilled: true,
                    color: WidgetPalette.completed,
                    systemImage: "arrow.clockwise",
                    systemImageOffsetY: -1
                )
                .frame(width: 24, height: 24)

                Text(RewardSchedule.automaticStorageTitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.titlePrimary)

                Spacer(minLength: 0)

                Text(automaticStorageCountdown(until: fullAt, now: context.date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.accentSoft)

                Text(RewardSchedule.automaticStorageBatchValue.inlineDescription(withPlusSign: true))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .widgetRoundedCard(fill: Color.white.opacity(0.18))
        }
    }

    private func automaticStorageCountdown(until target: Date, now: Date) -> String {
        let seconds = max(0, Int(target.timeIntervalSince(now).rounded(.up)))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

private struct ManualUnknownRewardRowView: View {
    let reward: ManualUnknownReward
    let onClaim: () -> Void
    let onAdvanceCycle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onClaim) {
                HStack(spacing: 10) {
                    RewardCircle(isFilled: reward.isClaimed)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(reward.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.titlePrimary)

                            Spacer(minLength: 0)

                            if let remainingText = reward.remainingText {
                                Text(remainingText)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.accentSoft)
                            }

                            Text(reward.value.inlineDescription(withPlusSign: true))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.accent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if reward.showsAdvanceCycleButton {
                ManualResetButton(action: onAdvanceCycle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .widgetRoundedCard(
            fill: reward.isClaimed ? Color.white.opacity(0.10) : Color.white.opacity(0.18)
        )
    }
}

private struct SecretPassProgressView: View {
    let progress: SecretPassProgress
    let onTapSlot: (SecretPassSlot) -> Void
    let onTogglePremiumPurchased: ((Bool) -> Void)?
    let onAdvanceCycle: (() -> Void)?
    let isGiftCodeListExpanded: Bool
    let onToggleGiftCodeList: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(progress.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                progress.isCompleted
                                    ? WidgetPalette.claimed
                                    : WidgetPalette.titlePrimary
                            )

                        if let onToggleGiftCodeList {
                            Button(action: onToggleGiftCodeList) {
                                PopupChevronIcon(
                                    isExpanded: isGiftCodeListExpanded,
                                    color: progress.isCompleted
                                        ? WidgetPalette.claimed
                                        : WidgetPalette.accentSoft
                                )
                                    .anchorPreference(
                                        key: GiftCodeChevronAnchorPreferenceKey.self,
                                        value: .bounds
                                    ) { [$0] }
                            }
                            .buttonStyle(.plain)
                        }

                        if let onTogglePremiumPurchased {
                            RewardActionButton(
                                title: progress.isPremiumPurchased ? "高级已购" : "高级",
                                isEnabled: true,
                                isSelected: progress.isPremiumPurchased,
                                color: progress.isCompleted ? WidgetPalette.claimed : nil,
                                action: { onTogglePremiumPurchased(!progress.isPremiumPurchased) }
                            )
                        }

                        Spacer(minLength: 0)

                        if let remainingText = progress.remainingText {
                            Text(remainingText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(
                                    progress.isCompleted
                                        ? WidgetPalette.claimed
                                        : WidgetPalette.accentSoft
                                )
                        }

                        Text("\(progress.displayedClaimedCount)/\(progress.displayedTotalCount)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                progress.isCompleted
                                    ? WidgetPalette.claimed
                                    : WidgetPalette.accent
                            )
                    }

                }

                if progress.showsCycleAdvanceButton, let onAdvanceCycle {
                    ManualResetButton(action: onAdvanceCycle)
                }
            }

            HStack(alignment: .center, spacing: 10) {
                if progress.kind == .secretPass && progress.isPremiumPurchased {
                    VStack(alignment: .leading, spacing: 10) {
                        slotRow(progress.slots.prefix(4))
                        slotRow(progress.slots.dropFirst(4))
                    }
                } else {
                    slotRow(progress.slots)
                }

                Spacer(minLength: 0)

                Text(progress.slotValue.inlineDescription(withPlusSign: true))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        progress.isCompleted
                            ? WidgetPalette.claimed
                            : WidgetPalette.accentSoft
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .widgetRoundedCard(fill: Color.white.opacity(0.16))
    }

    private func slotRow<S: RandomAccessCollection>(_ slots: S) -> some View
    where S.Element == SecretPassSlot {
        HStack(spacing: 10) {
            ForEach(Array(slots)) { slot in
                Button(action: {
                    onTapSlot(slot)
                }) {
                        RewardCircle(isFilled: slot.isClaimed, label: slot.label)
                        .frame(width: slot.label == nil ? 24 : 36, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(!slot.isUnlocked)
            }
        }
    }
}

private struct ManualResetButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WidgetPalette.accent)
        }
        .buttonStyle(.plain)
    }
}

private struct RewardActionButton: View {
    let title: String
    let isEnabled: Bool
    let isSelected: Bool
    let color: Color?
    let action: () -> Void

    init(
        title: String,
        isEnabled: Bool,
        isSelected: Bool = false,
        color: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(isSelected ? 0.28 : 0.20))
                )
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(isSelected ? 0.0 : 0.28), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .contentShape(Capsule(style: .continuous))
    }

    private var foregroundColor: Color {
        if let color {
            return color
        }
        return isEnabled
            ? isSelected ? WidgetPalette.pinkStrong : WidgetPalette.accentSoft
            : WidgetPalette.accentSoft.opacity(0.42)
    }
}

private struct RewardCircle: View {
    let isFilled: Bool
    let color: Color
    let unfilledColor: Color
    let label: String?
    let systemImage: String?
    let systemImageOffsetY: CGFloat
    let shapeOverride: DailyProgressSlotShape?

    init(
        isFilled: Bool,
        color: Color = WidgetPalette.pink,
        unfilledColor: Color = WidgetPalette.unchecked,
        label: String? = nil,
        systemImage: String? = nil,
        systemImageOffsetY: CGFloat = 0,
        shapeOverride: DailyProgressSlotShape? = nil
    ) {
        self.isFilled = isFilled
        self.color = color
        self.unfilledColor = unfilledColor
        self.label = label
        self.systemImage = systemImage
        self.systemImageOffsetY = systemImageOffsetY
        self.shapeOverride = shapeOverride
    }

    var body: some View {
        let isWideLabel = shapeOverride == .capsule || (shapeOverride == nil && (label?.count ?? 0 > 2))
        let shape: AnyShape = shapeOverride == .circle
            ? AnyShape(Circle())
            : isWideLabel
            ? AnyShape(RoundedRectangle(cornerRadius: 9))
            : AnyShape(Circle())

        ZStack {
            shape
                .fill(isFilled ? color : Color.clear)

            shape
                .stroke(isFilled ? color : unfilledColor, lineWidth: 1.5)

            if let label {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(isFilled ? Color.white : unfilledColor)
            } else if isFilled {
                Image(systemName: systemImage ?? "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white)
                    .offset(y: systemImageOffsetY)
            }
        }
        .frame(width: isWideLabel ? 30 : 18, height: 18)
        .contentShape(isWideLabel ? AnyShape(RoundedRectangle(cornerRadius: 9)) : AnyShape(Circle()))
    }
}

private struct DailyProgressView: View {
    let progress: DailyProgress
    let onTapSlot: (DailyProgressSlot) -> Void
    let onTapReviewStage: ((DailyProgressSlot, Int) -> Void)?
    let onAdvanceCycle: () -> Void

    init(
        progress: DailyProgress,
        onTapSlot: @escaping (DailyProgressSlot) -> Void,
        onTapReviewStage: ((DailyProgressSlot, Int) -> Void)? = nil,
        onAdvanceCycle: @escaping () -> Void
    ) {
        self.progress = progress
        self.onTapSlot = onTapSlot
        self.onTapReviewStage = onTapReviewStage
        self.onAdvanceCycle = onAdvanceCycle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(progress.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        progress.isCompleted
                            ? WidgetPalette.claimed
                            : WidgetPalette.titlePrimary
                    )

                Spacer(minLength: 0)

                if let remainingText = progress.remainingText {
                    Text(remainingText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.accentSoft)
                }

                if progress.rowCapacity != nil,
                   progress.display == .value,
                   !progress.showsCycleAdvanceButton {
                    Text(progress.claimedValue.inlineDescription(withPlusSign: true))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            progress.isCompleted
                                ? WidgetPalette.claimed
                                : WidgetPalette.accent
                        )
                }

                if progress.showsCycleAdvanceButton {
                    ManualResetButton(action: onAdvanceCycle)
                }
            }

            HStack(alignment: .center, spacing: 10) {
        if progress.id == RewardSchedule.dailyReviewID {
                    HStack(spacing: 10) {
                        ForEach(progress.slots) { slot in
                            ForEach(0..<slot.maxCount, id: \.self) { stage in
                                reviewStageButton(slot, stage: stage)
                            }
                        }
                    }
                } else if let rowCapacity = progress.rowCapacity {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(progress.slots.chunked(into: rowCapacity), id: \.self) { row in
                            HStack(spacing: 10) {
                                ForEach(row) { slot in
                                    slotButton(slot)
                                }
                            }
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        ForEach(progress.slots) { slot in
                            slotButton(slot)
                        }
                    }
                }

                Spacer(minLength: 0)

                if progress.rowCapacity == nil,
                   progress.display == .value,
                   !progress.showsCycleAdvanceButton {
                    Text(progress.claimedValue.inlineDescription(withPlusSign: true))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            progress.isCompleted
                                ? WidgetPalette.claimed
                                : WidgetPalette.accent
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .widgetRoundedCard(fill: Color.white.opacity(0.16))
    }

    private func reviewStageButton(_ slot: DailyProgressSlot, stage: Int) -> some View {
        Button {
            if let onTapReviewStage {
                onTapReviewStage(slot, stage)
            } else {
                onTapSlot(slot)
            }
        } label: {
            RewardCircle(
                isFilled: slot.isStageClaimed(at: stage),
                color: fillColor(for: slot),
                unfilledColor: color(for: slot.tint),
                label: "\(slot.rewardValues[stage].crystals)"
            )
        }
        .buttonStyle(.plain)
        .frame(width: 24, height: 24)
        .contentShape(Circle())
    }

    private func slotButton(_ slot: DailyProgressSlot) -> some View {
        Button {
            onTapSlot(slot)
        } label: {
            RewardCircle(
                isFilled: slot.isDisplayedClaimed,
                color: fillColor(for: slot),
                unfilledColor: color(for: slot.tint),
                label: slot.showsCheckmark
                    ? nil
                    : progress.display == .value
                    ? slot.displayLabel ?? "\(slot.value.crystals)"
                    : "\(slot.isCompletionClaimed ? 0 : slot.count)",
                shapeOverride: slot.shape
            )
        }
        .buttonStyle(.plain)
        .disabled(!slot.isUnlocked)
        .frame(width: slot.shape == .capsule ? 42 : 24, height: 24)
        .contentShape(slot.shape == .capsule ? AnyShape(Capsule()) : AnyShape(Circle()))
    }

    private func color(for tint: DailyProgressTint) -> Color {
        switch tint {
        case .neutral:
            return WidgetPalette.unchecked
        case .orange:
            return WidgetPalette.progressOrange
        case .purple:
            return WidgetPalette.progressPurple
        case .blue:
            return WidgetPalette.progressBlue
        }
    }

    private func fillColor(for slot: DailyProgressSlot) -> Color {
        switch slot.tint {
        case .neutral:
            return WidgetPalette.pink
        case .orange, .purple, .blue:
            return color(for: slot.tint)
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

private struct PullPlanBannerCardView: View {
    let banner: PullPlanBanner
    let isActive: Bool
    let currentDate: Date
    let progress: PullPlanBannerProgress
    let pityValue: Int?
    let selectedUpCharacter: String?
    let selectedLockLevel: Int?
    let isExpanded: Bool
    let onToggleBanner: () -> Void
    let onSetPityValue: (Int?) -> Void
    let onToggleUpCharacter: (String) -> Void
    let onToggleLockLevel: (Int) -> Void
    let onOpenRecord: () -> Void
    let onToggleExpand: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggleBanner) {
                RewardCircle(
                    isFilled: progress != .none,
                    color: circleColor,
                    unfilledColor: circleColor
                )
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(titleBaseText)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(primaryTextColor)

                        if let titleSuffixText {
                            Text("· \(titleSuffixText)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }

                        if banner.supportsPopupSelection {
                            Button(action: onToggleExpand) {
                                PopupChevronIcon(
                                    isExpanded: isExpanded,
                                    color: WidgetPalette.accentSoft
                                )
                            }
                            .buttonStyle(.plain)
                            .anchorPreference(
                                key: PullPlanSelectionAnchorPreferenceKey.self,
                                value: .bounds
                            ) { [PullPlanSelectionAnchor(id: banner.id, anchor: $0)] }
                        }

                        Spacer(minLength: 0)

                        recordButton

                        statusColumn
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text(multilineDisplayRange)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetPalette.mutedText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        PullPlanPityField(value: pityValue, onSetValue: onSetPityValue)

                        Text(countdownText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetPalette.mutedText)
                            .frame(width: 34, alignment: .trailing)
                            .padding(.trailing, 4)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundFillColor)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
        }
    }

    private var titleBaseText: String {
        banner.title
    }

    private var circleColor: Color {
        switch progress {
        case .none:
            return WidgetPalette.unchecked
        case .planned:
            return WidgetPalette.pink
        case .completed:
            return WidgetPalette.completed
        }
    }

    private var primaryTextColor: Color {
        switch progress {
        case .none:
            return WidgetPalette.titlePrimary
        case .planned:
            return WidgetPalette.claimed
        case .completed:
            return WidgetPalette.completedText
        }
    }

    private var secondaryTextColor: Color {
        switch progress {
        case .completed:
            return WidgetPalette.completedSoft
        case .none, .planned:
            return WidgetPalette.accentMuted
        }
    }

    private var backgroundFillColor: Color {
        switch progress {
        case .none:
            return Color.white.opacity(0.18)
        case .planned:
            return Color.white.opacity(0.12)
        case .completed:
            return WidgetPalette.cardCompletedFill
        }
    }

    private var titleSuffixText: String? {
        switch banner.selectionKind {
        case .targetChoice:
            return selectedUpCharacter
        case .lockCount:
            if let character = banner.characters.first, let selectedLockLevel {
                return "\(character) · \(selectedLockLevel)锁"
            }
            return banner.characters.first
        case .none:
            return banner.characters.first
        }
    }

    private var countdownText: String {
        let calendar = Calendar.rewardCalendar
        let targetDate = isActive ? banner.endsAt(in: calendar) : banner.startsAt(in: calendar)
        let interval = max(0, targetDate.timeIntervalSince(currentDate))

        if interval < 86_400 {
            let totalMinutes = Int(interval / 60)
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return String(format: "%02d:%02d", hours, minutes)
        }

        let days = Int(interval / 86_400)
        return "\(days)天"
    }

    private var multilineDisplayRange: String {
        let range = banner.localDisplayRange()
        return range.replacingOccurrences(of: " - ", with: " -\n")
    }

    @ViewBuilder
    private var statusColumn: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text(isActive ? "进行中" : "未开始")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? WidgetPalette.pinkStrong : WidgetPalette.mutedText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.28), in: Capsule())
        }
    }

    private var recordButton: some View {
        Button(action: onOpenRecord) {
            Text("记录")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(
                    progress == .completed
                        ? WidgetPalette.completedText
                        : WidgetPalette.mutedText
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.28), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(progress != .completed)
    }

}

private struct PullPlanSelectionPopup: View {
    let banner: PullPlanBanner
    let selectedUpCharacter: String?
    let selectedLockLevel: Int?
    let onToggleUpCharacter: (String) -> Void
    let onToggleLockLevel: (Int) -> Void

    var body: some View {
        WidgetPopupContainer(
            cornerRadius: 22,
            fill: WidgetPalette.overlayFill,
            shadowColor: WidgetPalette.accentSoft.opacity(0.12),
            shadowRadius: 12,
            shadowY: 5
        ) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                switch banner.selectionKind {
                case .targetChoice:
                    ForEach(banner.characters, id: \.self) { character in
                        selectionButton(
                            title: character,
                            isSelected: selectedUpCharacter == character
                        ) {
                            onToggleUpCharacter(character)
                        }
                    }
                case .lockCount:
                    ForEach(0...5, id: \.self) { lockLevel in
                        selectionButton(
                            title: "\(lockLevel)锁",
                            isSelected: selectedLockLevel == lockLevel
                        ) {
                            onToggleLockLevel(lockLevel)
                        }
                    }
                case .none:
                    EmptyView()
                }
            }
            .padding(10)
            .frame(width: 260, alignment: .leading)
        }
    }

    private func selectionButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12, weight: .semibold))

                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? WidgetPalette.pinkStrong : WidgetPalette.accentMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.34) : Color.white.opacity(0.16))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.26), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PullPlanPityField: View {
    let value: Int?
    let onSetValue: (Int?) -> Void

    @State private var text: String = ""
    @State private var isFocused = false

    var body: some View {
        HStack(spacing: 5) {
            Text("垫抽")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetPalette.mutedText)

            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isFocused ? Color.white.opacity(0.20) : Color.clear)

                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        WidgetPalette.pityBorder.opacity(isFocused ? 0.72 : 0.34),
                        lineWidth: 1
                    )

                if text.isEmpty && !isFocused {
                    Text("0")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.mutedText.opacity(0.78))
                }

#if os(macOS)
                InlineNumericTextField(
                    text: editingText,
                    isFocused: $isFocused,
                    textColor: NSColor(
                        red: 0.46,
                        green: 0.17,
                        blue: 0.29,
                        alpha: 1
                    ),
                    font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                    onCommit: commitText
                )
                .padding(.horizontal, 4)
#else
                TextField("0", text: editingText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.accent)
                    .onSubmit(commitText)
                .padding(.horizontal, 4)
#endif
            }
            .frame(width: 38, height: 26)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            syncText(with: value)
        }
        .onChange(of: value) { _, newValue in
            syncText(with: newValue)
        }
        .onChange(of: isFocused) { _, newValue in
            if !newValue {
                commitText()
            }
        }
    }

    private var editingText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = filteredText(from: newValue)
            }
        )
    }

    private func syncText(with value: Int?) {
        let newText = value.map(String.init) ?? ""
        if newText != text {
            text = newText
        }
    }

    private func filteredText(from rawText: String) -> String {
        String(rawText.filter(\.isNumber).prefix(3))
    }

    private func commitText() {
        let committedText = filteredText(from: text)
        if committedText != text {
            text = committedText
        }
        onSetValue(committedText.isEmpty ? nil : Int(committedText))
    }
}

private struct PullPlanRecordSummaryRow: View {
    let summary: PullPlanRecordSummary

    var body: some View {
        HStack(spacing: 6) {
            Text(summary.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titlePrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                PullPlanRecordMetric(title: "抽数", value: summary.drawCount)
                PullPlanRecordMetric(title: "UP数", value: summary.upCount)
                PullPlanRecordMetric(title: "UP总数", value: summary.upTotal)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .widgetRoundedCard(fill: Color.white.opacity(0.18))
    }
}

private struct GeneralPoolRecordRow: View {
    let record: GeneralPoolRecord
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 6) {
                Text("普池")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.titlePrimary)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    PullPlanRecordMetric(title: "蓝票", value: record.blueTickets)
                    PullPlanRecordMetric(title: "红票", value: record.redTickets)
                    PullPlanRecordMetric(title: "UP数", value: record.upCount)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .widgetRoundedCard(fill: Color.white.opacity(0.18))
        }
        .buttonStyle(.plain)
    }
}

private struct PullPlanRecordMetric: View {
    let title: String
    let value: Int

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetPalette.mutedText)
            Text("\(value)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titleSecondary)
        }
    }
}

private struct UpListEntry: Identifiable {
    let id: String
    let title: String
    let detail: String
}

private struct GiftCodeListPopup: View {
    let codes: [GiftCode]
    @State private var copiedCodeID: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if codes.isEmpty {
                    Text("暂无有效英文兑换码")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.accentSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                } else {
                    ForEach(codes) { giftCode in
                        HStack(spacing: 6) {
                            Text(giftCode.code)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(WidgetPalette.titlePrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Spacer(minLength: 4)

                            Button {
                                copy(giftCode)
                            } label: {
                                Image(systemName: copiedCodeID == giftCode.id ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(WidgetPalette.accentSoft)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white.opacity(0.34), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 9)
                        .padding(.trailing, 5)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(0.30))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.46), lineWidth: 1)
                        }
                    }
                }
            }
            .padding(10)
        }
        .scrollIndicators(.hidden)
    }

    private func copy(_ giftCode: GiftCode) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(giftCode.code, forType: .string)
#else
        UIPasteboard.general.string = giftCode.code
#endif
        copiedCodeID = giftCode.id

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if copiedCodeID == giftCode.id {
                copiedCodeID = nil
            }
        }
    }
}

private struct UpChevronAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [Anchor<CGRect>] = []

    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}

private struct GiftCodeChevronAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [Anchor<CGRect>] = []

    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}

private struct PullPlanSelectionAnchor {
    let id: String
    let anchor: Anchor<CGRect>
}

private struct PullPlanSelectionAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [PullPlanSelectionAnchor] = []

    static func reduce(
        value: inout [PullPlanSelectionAnchor],
        nextValue: () -> [PullPlanSelectionAnchor]
    ) {
        value.append(contentsOf: nextValue())
    }
}

private enum PrimarySection: String {
    case currentPeriod
    case permanentRewards
    case pullPlan
    case pullPlanRecords
}

private enum ActiveSheet: Identifiable, Equatable {
    case editInventory
    case history
    case historyStatistics
    case consumption
    case increase
    case pullPlanRecord(String)
    case generalPoolRecord

    var id: String {
        switch self {
        case .editInventory: return "edit-inventory"
        case .history: return "history"
        case .historyStatistics: return "history-statistics"
        case .consumption: return "consumption"
        case .increase: return "increase"
        case .pullPlanRecord(let bannerID): return "pull-plan-record-\(bannerID)"
        case .generalPoolRecord: return "general-pool-record"
        }
    }
}
