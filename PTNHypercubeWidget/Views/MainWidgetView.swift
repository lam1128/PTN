import AppKit
import SwiftUI

private enum WidgetPalette {
    static let titlePrimary = Color(red: 0.34, green: 0.15, blue: 0.22)
    static let titleSecondary = Color(red: 0.44, green: 0.21, blue: 0.30)
    static let accent = Color(red: 0.46, green: 0.17, blue: 0.29)
    static let accentSoft = Color(red: 0.50, green: 0.24, blue: 0.35)
    static let accentMuted = Color(red: 0.52, green: 0.26, blue: 0.36)
    static let accentLight = Color(red: 0.56, green: 0.35, blue: 0.43)
    static let claimed = Color(red: 0.58, green: 0.36, blue: 0.43)
    static let pink = Color(red: 0.87, green: 0.31, blue: 0.55)
    static let pinkStrong = Color(red: 0.82, green: 0.30, blue: 0.53)
    static let unchecked = Color(red: 0.65, green: 0.42, blue: 0.51)
    static let completed = Color(red: 0.34, green: 0.67, blue: 0.61)
    static let completedText = Color(red: 0.27, green: 0.47, blue: 0.43)
    static let completedSoft = Color(red: 0.35, green: 0.58, blue: 0.53)
    static let cardCompletedFill = Color(red: 0.83, green: 0.95, blue: 0.91).opacity(0.34)
    static let overlayFill = Color.white.opacity(0.82)
    static let overlayStroke = Color.white.opacity(0.44)
    static let cardStroke = Color.white.opacity(0.34)
    static let capsuleStroke = Color.white.opacity(0.30)
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

    func widgetOverlayPanelCard() -> some View {
        background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(WidgetPalette.overlayFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(WidgetPalette.overlayStroke, lineWidth: 1)
        }
    }
}

struct MainWidgetView: View {
    @ObservedObject var store: AppStateStore

    @State private var activeSheet: ActiveSheet?
    @State private var selectedPrimarySection: PrimarySection = .currentPeriod
    @State private var expandedPullPlanBannerIDs: Set<String> = []
    @State private var isUpListExpanded = false
    @State private var currentPeriodScrollOffset: CGFloat = 0
    @State private var pullPlanScrollOffset: CGFloat = 0
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let upPopupWidth: CGFloat = 150

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

                if isUpListExpanded {
                    Rectangle()
                        .fill(Color.black.opacity(0.001))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isUpListExpanded = false
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                }

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
                        }
                    }
                }
                .blur(radius: activeSheet == nil ? 0 : 2)
                .opacity(activeSheet == nil ? 1 : 0.28)
                .animation(.easeInOut(duration: 0.14), value: activeSheet)

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
                            .zIndex(20)
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
        }
        .onReceive(refreshTimer) { now in
            store.refreshRewards(now: now)
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
        }
        .frame(minWidth: 58, alignment: .leading)
    }

    private var upSummaryMetric: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("UP数")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titleSecondary)

            HStack(spacing: 2) {
                Text("\(store.totalPlannedUpCount)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.titlePrimary)

                Button {
                    isUpListExpanded.toggle()
                } label: {
                    Image(systemName: isUpListExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WidgetPalette.accentSoft)
                        .frame(width: 16, height: 16)
                        .anchorPreference(
                            key: UpChevronAnchorPreferenceKey.self,
                            value: .bounds
                        ) { [$0] }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(minWidth: 58, alignment: .leading)
    }

    private var primarySectionTabs: some View {
        HStack(spacing: 8) {
            primaryTabButton(.currentPeriod, title: "当前周期")
            primaryTabButton(.pullPlan, title: "抽卡规划")
            Spacer(minLength: 0)
        }
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
                if lhs.isClaimed != rhs.isClaimed {
                    return !lhs.isClaimed && rhs.isClaimed
                }
                return lhs.sortOrder < rhs.sortOrder
            }
        let incompleteTrialRewards = trialRewards.filter { !$0.isClaimed }
        let completedTrialRewards = trialRewards.filter(\.isClaimed)

        let incompleteManualUnknownRewards = store.manualUnknownRewards.filter { !$0.isClaimed }
        let completedManualUnknownRewards = store.manualUnknownRewards.filter(\.isClaimed)

        let incompleteProgressItems = [store.secretPassProgress, store.miniGameProgress]
            .filter { !$0.isCompleted }
        let completedProgressItems = [store.secretPassProgress, store.miniGameProgress]
            .filter(\.isCompleted)

        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("额外记录")

            ForEach(incompleteTrialRewards) { reward in
                RewardRowView(reward: reward) {
                    store.toggle(reward)
                }
            }

            ForEach(incompleteManualUnknownRewards) { reward in
                ManualUnknownRewardRowView(
                    reward: reward,
                    onClaim: { store.toggleManualUnknown(reward) },
                    onAdvanceCycle: { store.advanceManualCycle(for: reward.id) }
                )
            }

            ForEach(incompleteProgressItems, id: \.id) { progress in
                manualProgressView(for: progress)
            }

            ForEach(completedTrialRewards) { reward in
                RewardRowView(reward: reward) {
                    store.toggle(reward)
                }
            }

            ForEach(completedManualUnknownRewards) { reward in
                ManualUnknownRewardRowView(
                    reward: reward,
                    onClaim: { store.toggleManualUnknown(reward) },
                    onAdvanceCycle: { store.advanceManualCycle(for: reward.id) }
                )
            }

            ForEach(completedProgressItems, id: \.id) { progress in
                manualProgressView(for: progress)
            }
        }
        .padding(.horizontal, 4)
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
                        onToggleExpand: {
                            if expandedPullPlanBannerIDs.contains(banner.id) {
                                expandedPullPlanBannerIDs.remove(banner.id)
                            } else {
                                expandedPullPlanBannerIDs.insert(banner.id)
                            }
                        }
                    )
                }
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

            Spacer(minLength: 0)

            if let todayTotal = store.todayCrystalEquivalentText {
                Text("今日：\(todayTotal)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.50, green: 0.24, blue: 0.35))
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
                if progress.id == RewardSchedule.secretPassID {
                    store.toggleSecretPassSlot(slot)
                } else {
                    store.toggleMiniGameSlot(slot)
                }
            },
            onTogglePremiumPurchased: progress.id == RewardSchedule.secretPassID
                ? { isOn in store.setHasPremiumSecretPass(isOn) }
                : nil,
            onAdvanceCycle: progress.id == RewardSchedule.miniGameID
                ? { store.advanceManualCycle(for: RewardSchedule.miniGameID) }
                : nil
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            Color(red: 0.95, green: 0.98, blue: 1.0).opacity(0.95),
                            Color(red: 0.94, green: 0.96, blue: 0.99).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.70), lineWidth: 1)
        }
        .shadow(color: WidgetPalette.accentSoft.opacity(0.12), radius: 12, y: 5)
    }

    private func primaryTabButton(_ section: PrimarySection, title: String) -> some View {
        Button {
            selectedPrimarySection = section
        } label: {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        selectedPrimarySection == section
                        ? WidgetPalette.accent
                        : WidgetPalette.accentLight
                )
                .padding(.horizontal, 12)
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
    }

    @ViewBuilder
    private func panelView(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .editInventory:
            OverlayPanel {
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
            OverlayPanel {
                HistorySheetView(store: store) {
                    activeSheet = nil
                }
            }
            .frame(width: 310, height: 350)
        }
    }
}

private struct OverlayPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .widgetOverlayPanelCard()
            .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
    }
}

private struct RewardRowView: View {
    let reward: RewardItem
    let onClaim: () -> Void

    var body: some View {
        Button(action: onClaim) {
            HStack(spacing: 10) {
                Image(systemName: reward.isClaimed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(reward.isClaimed ? WidgetPalette.pink : WidgetPalette.unchecked)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(reward.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.titlePrimary)

                        Spacer(minLength: 0)

                        Text(reward.displayValue.inlineDescription(withPlusSign: true))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(reward.isClaimed ? WidgetPalette.claimed : WidgetPalette.accent)
                    }

                }
            }
            .padding(11)
            .widgetRoundedCard(fill: reward.isClaimed ? Color.white.opacity(0.10) : Color.white.opacity(0.18))
        }
        .buttonStyle(.plain)
    }
}

private struct ManualUnknownRewardRowView: View {
    let reward: ManualUnknownReward
    let onClaim: () -> Void
    let onAdvanceCycle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onClaim) {
                Image(systemName: reward.isClaimed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(reward.isClaimed ? WidgetPalette.pink : WidgetPalette.unchecked)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

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

            if reward.showsAdvanceCycleButton {
                Button(action: onAdvanceCycle) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WidgetPalette.claimed)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(11)
        .widgetRoundedCard(fill: Color.white.opacity(0.16))
    }
}

private struct SecretPassProgressView: View {
    let progress: SecretPassProgress
    let onTapSlot: (SecretPassSlot) -> Void
    let onTogglePremiumPurchased: ((Bool) -> Void)?
    let onAdvanceCycle: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(progress.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetPalette.titlePrimary)

                        if let onTogglePremiumPurchased {
                            Button {
                                onTogglePremiumPurchased(!progress.isPremiumPurchased)
                            } label: {
                                Text(progress.isPremiumPurchased ? "高级已购" : "高级")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        progress.isPremiumPurchased
                                            ? Color(red: 0.82, green: 0.30, blue: 0.53)
                                            : WidgetPalette.accentSoft
                                    )
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(
                                                progress.isPremiumPurchased
                                                    ? Color.white.opacity(0.28)
                                                    : Color.white.opacity(0.20)
                                            )
                                    )
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .strokeBorder(Color.white.opacity(progress.isPremiumPurchased ? 0.0 : 0.28), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 0)

                        if let remainingText = progress.remainingText {
                            Text(remainingText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(WidgetPalette.accentSoft)
                        }

                        Text("\(progress.displayedClaimedCount)/\(progress.displayedTotalCount)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetPalette.accent)
                    }

                }

                if progress.showsCycleAdvanceButton, let onAdvanceCycle {
                    Button(action: onAdvanceCycle) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(WidgetPalette.claimed)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                ForEach(progress.slots) { slot in
                    Button(action: {
                        onTapSlot(slot)
                    }) {
                        Image(systemName: slot.isClaimed ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                slot.isClaimed
                                    ? WidgetPalette.pink
                                    : WidgetPalette.unchecked
                            )
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                Text(progress.slotValue.inlineDescription(withPlusSign: true))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.accentSoft)
            }
        }
        .padding(11)
        .widgetRoundedCard(fill: Color.white.opacity(0.16))
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
    let onToggleExpand: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggleBanner) {
                Image(systemName: progress == .none ? "circle" : "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(circleColor)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            ZStack(alignment: .topLeading) {
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
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(red: 0.52, green: 0.26, blue: 0.36))
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 0)

                        statusColumn
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text(multilineDisplayRange)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.54, green: 0.31, blue: 0.40))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        PullPlanPityField(value: pityValue, onSetValue: onSetPityValue)

                        Text(countdownText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.54, green: 0.31, blue: 0.40))
                            .frame(width: 34, alignment: .trailing)
                            .padding(.trailing, 4)
                    }
                }

                if banner.supportsPopupSelection && isExpanded {
                    selectionPopup
                        .offset(x: 0, y: 38)
                        .zIndex(2)
                }
            }
        }
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
            return Color(red: 0.65, green: 0.42, blue: 0.51)
        case .planned:
            return Color(red: 0.87, green: 0.31, blue: 0.55)
        case .completed:
            return Color(red: 0.34, green: 0.67, blue: 0.61)
        }
    }

    private var primaryTextColor: Color {
        switch progress {
        case .none:
            return Color(red: 0.34, green: 0.15, blue: 0.22)
        case .planned:
            return Color(red: 0.58, green: 0.36, blue: 0.43)
        case .completed:
            return Color(red: 0.27, green: 0.47, blue: 0.43)
        }
    }

    private var secondaryTextColor: Color {
        switch progress {
        case .completed:
            return Color(red: 0.35, green: 0.58, blue: 0.53)
        case .none, .planned:
            return Color(red: 0.52, green: 0.26, blue: 0.36)
        }
    }

    private var backgroundFillColor: Color {
        switch progress {
        case .none:
            return Color.white.opacity(0.18)
        case .planned:
            return Color.white.opacity(0.12)
        case .completed:
            return Color(red: 0.83, green: 0.95, blue: 0.91).opacity(0.34)
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
                .foregroundStyle(isActive ? Color(red: 0.82, green: 0.30, blue: 0.53) : Color(red: 0.54, green: 0.31, blue: 0.40))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.28), in: Capsule())
        }
    }

    private var selectionPopup: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch banner.selectionKind {
            case .targetChoice:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(banner.characters, id: \.self) { character in
                        Button {
                            onToggleUpCharacter(character)
                            onToggleExpand()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: selectedUpCharacter == character ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12, weight: .semibold))

                                Text(character)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(
                                selectedUpCharacter == character
                                    ? Color(red: 0.82, green: 0.30, blue: 0.53)
                                    : Color(red: 0.52, green: 0.26, blue: 0.36)
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        selectedUpCharacter == character
                                            ? Color.white.opacity(0.34)
                                            : Color.white.opacity(0.16)
                                    )
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.26), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .lockCount:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(0...5, id: \.self) { lockLevel in
                        Button {
                            onToggleLockLevel(lockLevel)
                            onToggleExpand()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: selectedLockLevel == lockLevel ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12, weight: .semibold))

                                Text("\(lockLevel)锁")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(
                                selectedLockLevel == lockLevel
                                    ? Color(red: 0.82, green: 0.30, blue: 0.53)
                                    : Color(red: 0.52, green: 0.26, blue: 0.36)
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        selectedLockLevel == lockLevel
                                            ? Color.white.opacity(0.34)
                                            : Color.white.opacity(0.16)
                                    )
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.26), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .none:
                EmptyView()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.90))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.44), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
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
                .foregroundStyle(Color(red: 0.54, green: 0.31, blue: 0.40))

            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isFocused ? Color.white.opacity(0.20) : Color.clear)

                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        Color(red: 0.82, green: 0.56, blue: 0.67).opacity(isFocused ? 0.72 : 0.34),
                        lineWidth: 1
                    )

                if text.isEmpty && !isFocused {
                    Text("0")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.54, green: 0.31, blue: 0.40).opacity(0.78))
                }

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

private struct UpListEntry: Identifiable {
    let id: String
    let title: String
    let detail: String
}

private struct UpChevronAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [Anchor<CGRect>] = []

    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}

private enum PrimarySection: String {
    case currentPeriod
    case pullPlan
}

private enum ActiveSheet: String, Identifiable {
    case editInventory
    case history

    var id: String { rawValue }
}
