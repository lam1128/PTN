import SwiftUI
import AppKit

struct RewardRowView: View {
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

struct AutomaticStorageRowView: View {
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

struct ManualUnknownRewardRowView: View {
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

struct SecretPassProgressView: View {
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

extension SecretPassProgress {
    func withGiftCodeRewards(_ codes: [GiftCode]) -> SecretPassProgress {
        guard kind == .redemptionCode else { return self }
        let updatedSlots = slots.enumerated().map { offset, slot in
            guard codes.indices.contains(offset),
                  let value = codes[offset].rewardValue else {
                return slot
            }
            return SecretPassSlot(
                id: slot.id,
                index: slot.index,
                baseClaimKey: slot.baseClaimKey,
                premiumClaimKey: slot.premiumClaimKey,
                rewardValue: value,
                label: value.shortLabel,
                isPremiumOnly: slot.isPremiumOnly,
                isClaimed: slot.isClaimed,
                isUnlocked: slot.isUnlocked
            )
        }
        let displayedSlotValue = updatedSlots.compactMap(\.rewardValue).first ?? slotValue
        return SecretPassProgress(
            id: id,
            kind: kind,
            title: title,
            slotValue: displayedSlotValue,
            cycleVersion: cycleVersion,
            slots: updatedSlots,
            remainingText: remainingText,
            isPremiumPurchased: isPremiumPurchased,
            showsCycleAdvanceButton: showsCycleAdvanceButton
        )
    }
}

extension RewardValue {
    var shortLabel: String? {
        if crystals != 0 && blueTickets == 0 && redTickets == 0 {
            return String(crystals)
        }
        if crystals == 0 && blueTickets != 0 && redTickets == 0 {
            return "\(blueTickets)票"
        }
        if crystals == 0 && blueTickets == 0 && redTickets != 0 {
            return "\(redTickets)红"
        }
        return nil
    }
}

struct ManualResetButton: View {
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

struct RewardActionButton: View {
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

struct RewardCircle: View {
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

struct DailyProgressView: View {
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
        let label = slot.showsCheckmark
            ? nil
            : progress.display == .value
                ? slot.displayLabel ?? "\(slot.value.crystals)"
                : "\(slot.isCompletionClaimed ? 0 : slot.count)"
        let usesWideLayout = slot.shape == .capsule
            || (slot.shape == nil && (label?.count ?? 0) > 2)

        return Button {
            onTapSlot(slot)
        } label: {
            RewardCircle(
                isFilled: slot.isDisplayedClaimed,
                color: fillColor(for: slot),
                unfilledColor: color(for: slot.tint),
                label: label,
                shapeOverride: slot.shape
            )
        }
        .buttonStyle(.plain)
        .disabled(!slot.isUnlocked)
        .frame(width: usesWideLayout ? 42 : 24, height: 24)
        .contentShape(usesWideLayout ? AnyShape(Capsule()) : AnyShape(Circle()))
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

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct PullPlanBannerCardView: View {
    let banner: PullPlanBanner
    let isActive: Bool
    let currentDate: Date
    let progress: PullPlanBannerProgress
    let pityValue: Int?
    let selectedUpCharacter: String?
    let selectedLockLevel: Int?
    let selectedCharacterLockLevels: [String: Int]
    let isExpanded: Bool
    let onToggleBanner: () -> Void
    let onSetPityValue: (Int?) -> Void
    let onToggleUpCharacter: (String) -> Void
    let onToggleLockLevel: (Int) -> Void
    let onSetCharacterLockLevel: (String, Int?) -> Void
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
            return nil
        case .multiLockCount:
            return nil
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

struct PullPlanSelectionPopup: View {
    let banner: PullPlanBanner
    let selectedUpCharacter: String?
    let selectedLockLevel: Int?
    let selectedCharacterLockLevels: [String: Int]
    let onToggleUpCharacter: (String) -> Void
    let onToggleLockLevel: (Int) -> Void
    let onSetCharacterLockLevel: (String, Int?) -> Void

    var body: some View {
        WidgetPopupContainer(
            cornerRadius: 22,
            fill: WidgetPalette.overlayFill,
            shadowColor: WidgetPalette.accentSoft.opacity(0.12),
            shadowRadius: 12,
            shadowY: 5
        ) {
            switch banner.selectionKind {
            case .multiLockCount:
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(banner.characters, id: \.self) { character in
                        PullPlanCharacterLockField(
                            character: character,
                            value: selectedCharacterLockLevels[character],
                            onSetValue: { lockLevel in
                                onSetCharacterLockLevel(character, lockLevel)
                            },
                            selectionContent: { title, isSelected in
                                AnyView(selectionContent(title: title, isSelected: isSelected))
                            }
                        )
                    }
                }
                .padding(10)
                .frame(width: 260, alignment: .leading)
            case .targetChoice, .lockCount, .none:
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
                    case .none, .multiLockCount:
                        EmptyView()
                    }
                }
                .padding(10)
                .frame(width: 260, alignment: .leading)
            }
        }
    }

    private func selectionButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            selectionContent(title: title, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func selectionContent(title: String, isSelected: Bool) -> some View {
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
}

struct PullPlanCharacterLockField: View {
    let character: String
    let value: Int?
    let onSetValue: (Int?) -> Void
    let selectionContent: (String, Bool) -> AnyView

    @State private var text: String = ""
    @State private var isFocused = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if value == nil {
                    onSetValue(0)
                } else {
                    onSetValue(nil)
                }
            } label: {
                selectionContent(character, value != nil)
            }
            .buttonStyle(.plain)

            Text("锁")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetPalette.mutedText)

            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isFocused ? Color.white.opacity(0.22) : Color.white.opacity(0.14))

                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        WidgetPalette.pityBorder.opacity(isFocused ? 0.72 : 0.34),
                        lineWidth: 1
                    )

                if text.isEmpty && !isFocused {
                    Text(value == nil ? "" : "0")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.mutedText.opacity(0.78))
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
            .frame(width: 34, height: 26)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onTapGesture {
                if value == nil {
                    onSetValue(0)
                    text = "0"
                }
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
        String(rawText.filter(\.isNumber).prefix(1))
    }

    private func commitText() {
        let committedText = filteredText(from: text)
        if committedText != text {
            text = committedText
        }
        guard value != nil || !committedText.isEmpty else {
            onSetValue(nil)
            return
        }
        onSetValue(Int(committedText) ?? 0)
    }
}

struct PullPlanPityField: View {
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

struct PullPlanRecordSummaryRow: View {
    let summary: PullPlanRecordSummary
    let onOpenDetails: () -> Void

    var body: some View {
        Button(action: onOpenDetails) {
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
        .buttonStyle(.plain)
    }
}

struct GeneralPoolRecordRow: View {
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
                    PullPlanRecordMetric(title: "UP数", value: record.displayedUpCount)
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

struct PullPlanRecordMetric: View {
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

struct UpListEntry: Identifiable {
    let id: String
    let title: String
    let detail: String
}

struct GiftCodeListPopup: View {
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(giftCode.code)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(WidgetPalette.titlePrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)

                                if let rewardValue = giftCode.rewardValue {
                                    Text(rewardValue.inlineDescription(withPlusSign: true))
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundStyle(WidgetPalette.accentSoft)
                                }
                            }

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
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(giftCode.code, forType: .string)
        copiedCodeID = giftCode.id

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if copiedCodeID == giftCode.id {
                copiedCodeID = nil
            }
        }
    }
}

struct UpChevronAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [Anchor<CGRect>] = []

    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}

struct GiftCodeChevronAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [Anchor<CGRect>] = []

    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}

struct PullPlanSelectionAnchor {
    let id: String
    let anchor: Anchor<CGRect>
}

struct PullPlanSelectionAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [PullPlanSelectionAnchor] = []

    static func reduce(
        value: inout [PullPlanSelectionAnchor],
        nextValue: () -> [PullPlanSelectionAnchor]
    ) {
        value.append(contentsOf: nextValue())
    }
}

enum PrimarySection: String {
    case currentPeriod
    case permanentRewards
    case pullPlan
    case pullPlanRecords
}

enum ActiveSheet: Identifiable, Equatable {
    case editInventory
    case history
    case historyStatistics
    case consumption
    case increase
    case pullPlanRecord(String)
    case pullPlanRecordDetails(String)
    case generalPoolRecord

    var id: String {
        switch self {
        case .editInventory: return "edit-inventory"
        case .history: return "history"
        case .historyStatistics: return "history-statistics"
        case .consumption: return "consumption"
        case .increase: return "increase"
        case .pullPlanRecord(let bannerID): return "pull-plan-record-\(bannerID)"
        case .pullPlanRecordDetails(let poolTitle): return "pull-plan-record-details-\(poolTitle)"
        case .generalPoolRecord: return "general-pool-record"
        }
    }
}

