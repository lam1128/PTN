import SwiftUI

struct EditInventorySheet: View {
    let currentCrystals: Int
    let currentBlueTickets: Int
    let currentRedTickets: Int
    let onSave: (Int, Int, Int) -> Void
    let onClose: () -> Void

    @State private var crystalDraft: String
    @State private var blueTicketDraft: String
    @State private var redTicketDraft: String

    init(
        currentCrystals: Int,
        currentBlueTickets: Int,
        currentRedTickets: Int,
        onSave: @escaping (Int, Int, Int) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.currentCrystals = currentCrystals
        self.currentBlueTickets = currentBlueTickets
        self.currentRedTickets = currentRedTickets
        self.onSave = onSave
        self.onClose = onClose
        _crystalDraft = State(initialValue: String(currentCrystals))
        _blueTicketDraft = State(initialValue: String(currentBlueTickets))
        _redTicketDraft = State(initialValue: String(currentRedTickets))
    }

    private var parsedCrystals: Int? {
        Int(crystalDraft.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedBlueTickets: Int? {
        Int(blueTicketDraft.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedRedTickets: Int? {
        Int(redTicketDraft.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            panelHeader("修改当前库存", onClose: onClose)

            VStack(alignment: .leading, spacing: 10) {
                Text("异方晶")
                    .font(.subheadline.weight(.medium))
                TextField("输入当前异方晶总数", text: $crystalDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submit)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("蓝票")
                    .font(.subheadline.weight(.medium))
                TextField("输入当前蓝票数", text: $blueTicketDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submit)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("红票")
                    .font(.subheadline.weight(.medium))
                TextField("输入当前红票数", text: $redTicketDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submit)
            }

            HStack {
                Button("取消", action: onClose)

                Spacer()

                Button("保存") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    parsedCrystals == nil ||
                    parsedBlueTickets == nil ||
                    parsedRedTickets == nil ||
                    (
                        parsedCrystals == currentCrystals &&
                        parsedBlueTickets == currentBlueTickets &&
                        parsedRedTickets == currentRedTickets
                    )
                )
            }
        }
        .padding(18)
    }

    private func submit() {
        guard let parsedCrystals, let parsedBlueTickets, let parsedRedTickets else { return }
        let hasChanges = parsedCrystals != currentCrystals
            || parsedBlueTickets != currentBlueTickets
            || parsedRedTickets != currentRedTickets

        if hasChanges {
            onSave(parsedCrystals, parsedBlueTickets, parsedRedTickets)
        } else {
            onClose()
        }
    }
}

struct PullPlanTicketRecordSheet: View {
    let bannerTitle: String
    let currentGiftTickets: Int
    let currentBlueTickets: Int
    let availableBlueTickets: Int
    let currentUpCount: Int
    let currentUpTotal: Int
    let currentNonUpCharacters: String
    let onSave: (Int, Int, Int, Int, String) -> Void
    let onClose: () -> Void

    @State private var giftTicketDraft: String
    @State private var blueTicketDraft: String
    @State private var upCountDraft: String
    @State private var upTotalDraft: String
    @State private var nonUpCharactersDraft: String
    @State private var upTotalManuallyEdited: Bool

    init(
        bannerTitle: String,
        currentGiftTickets: Int,
        currentBlueTickets: Int,
        availableBlueTickets: Int,
        currentUpCount: Int,
        currentUpTotal: Int,
        currentNonUpCharacters: String,
        onSave: @escaping (Int, Int, Int, Int, String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.bannerTitle = bannerTitle
        self.currentGiftTickets = currentGiftTickets
        self.currentBlueTickets = currentBlueTickets
        self.availableBlueTickets = availableBlueTickets
        self.currentUpCount = currentUpCount
        self.currentUpTotal = currentUpTotal
        self.currentNonUpCharacters = currentNonUpCharacters
        self.onSave = onSave
        self.onClose = onClose
        _giftTicketDraft = State(initialValue: currentGiftTickets == 0 ? "" : String(currentGiftTickets))
        _blueTicketDraft = State(initialValue: currentBlueTickets == 0 ? "" : String(currentBlueTickets))
        _upCountDraft = State(initialValue: currentUpCount == 0 ? "" : String(currentUpCount))
        _upTotalDraft = State(initialValue: currentUpTotal == 0 ? "" : String(currentUpTotal))
        _nonUpCharactersDraft = State(initialValue: currentNonUpCharacters)
        _upTotalManuallyEdited = State(initialValue: currentUpTotal != currentUpCount)
    }

    private var giftTickets: Int {
        Int(giftTicketDraft) ?? 0
    }

    private var blueTickets: Int {
        Int(blueTicketDraft) ?? 0
    }

    private var upCount: Int {
        Int(upCountDraft) ?? 0
    }

    private var upTotal: Int {
        Int(upTotalDraft) ?? 0
    }

    private var nonUpCount: Int {
        max(0, upTotal - upCount)
    }

    private var isValid: Bool {
        blueTickets >= 0 && blueTickets <= availableBlueTickets
    }

    private var hasChanges: Bool {
        giftTickets != currentGiftTickets ||
            blueTickets != currentBlueTickets ||
            upCount != currentUpCount ||
            upTotal != currentUpTotal ||
            normalizedNonUpCharacters != currentNonUpCharacters
    }

    private var canConfirm: Bool {
        isValid && (nonUpCount == 0 || !normalizedNonUpCharacters.isEmpty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelHeader("记录·\(bannerTitle)", onClose: onClose)

            HStack(spacing: 10) {
                RecordNumberField(title: "赠送票", text: $giftTicketDraft, onSubmit: submit)
                RecordNumberField(title: "蓝票", text: $blueTicketDraft, onSubmit: submit)
            }

            HStack(spacing: 10) {
                RecordNumberField(title: "UP数", text: $upCountDraft, onSubmit: submit)
                RecordNumberField(title: "UP总数", text: upTotalEditingBinding, onSubmit: submit)
            }

            if nonUpCount > 0 {
                VStack(alignment: .leading, spacing: 7) {
                    Text("非UP角色")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.titlePrimary)

                    TextField("多个角色用顿号分隔", text: $nonUpCharactersDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(submit)
                }
            }

            HStack {
                Button("取消", action: onClose)

                Spacer()

                Button("确认") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .tint(WidgetPalette.pink)
                .disabled(!canConfirm)
            }
        }
        .padding(16)
        .onChange(of: giftTicketDraft) { _, value in
            giftTicketDraft = filteredNumber(value)
        }
        .onChange(of: blueTicketDraft) { _, value in
            blueTicketDraft = filteredNumber(value)
        }
        .onChange(of: upCountDraft) { _, value in
            let filtered = filteredNumber(value)
            upCountDraft = filtered
            if !upTotalManuallyEdited {
                upTotalDraft = filtered
            }
        }
    }

    private var upTotalEditingBinding: Binding<String> {
        Binding(
            get: { upTotalDraft },
            set: { value in
                upTotalManuallyEdited = true
                upTotalDraft = filteredNumber(value)
            }
        )
    }

    private func submit() {
        guard canConfirm else { return }
        if hasChanges {
            onSave(giftTickets, blueTickets, upCount, upTotal, normalizedNonUpCharacters)
        } else {
            onClose()
        }
    }

    private var normalizedNonUpCharacters: String {
        nonUpCount > 0
            ? nonUpCharactersDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
    }

    private func filteredNumber(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(4))
    }
}

struct PullPlanRecordDetailsSheet: View {
    let poolTitle: String
    let details: [PullPlanRecordDetail]
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            panelHeader(poolTitle, onClose: onClose)

            if details.isEmpty {
                Text("暂无UP或非UP记录")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(details) { detail in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(detail.dateText)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(WidgetPalette.mutedText)

                                HStack(spacing: 10) {
                                    if detail.upCount > 0 {
                                        Text(upText(for: detail))
                                    }
                                    if detail.nonUpCount > 0 {
                                        Text(nonUpText(for: detail))
                                    }
                                }
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(WidgetPalette.titlePrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.18))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
    }

    private func upText(for detail: PullPlanRecordDetail) -> String {
        let count = detail.upCount > 1 ? " ×\(detail.upCount)" : ""
        return "UP：\(detail.upCharacter)\(count)"
    }

    private func nonUpText(for detail: PullPlanRecordDetail) -> String {
        let characters = detail.nonUpCharacters.isEmpty
            ? "\(detail.nonUpCount)"
            : detail.nonUpCharacters
        return "非UP：\(characters)"
    }
}

struct GeneralPoolRecordSheet: View {
    let currentRecord: GeneralPoolRecord
    let onSave: (Int, Int, String) -> Void
    let onClose: () -> Void

    @State private var blueTicketDraft: String
    @State private var redTicketDraft: String
    @State private var upCharactersDraft: String

    init(
        currentRecord: GeneralPoolRecord,
        onSave: @escaping (Int, Int, String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.currentRecord = currentRecord
        self.onSave = onSave
        self.onClose = onClose
        _blueTicketDraft = State(initialValue: Self.text(for: currentRecord.blueTickets))
        _redTicketDraft = State(initialValue: Self.text(for: currentRecord.redTickets))
        _upCharactersDraft = State(initialValue: currentRecord.upCharacters)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            panelHeader("记录·普池", onClose: onClose)

            HStack(spacing: 10) {
                RecordNumberField(title: "蓝票", text: $blueTicketDraft, onSubmit: submit)
                RecordNumberField(title: "红票", text: $redTicketDraft, onSubmit: submit)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("UP")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.titlePrimary)

                TextField("多个角色用逗号或空格分隔", text: $upCharactersDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submit)
            }

            HStack {
                Button("取消", action: onClose)
                Spacer()
                Button("确认", action: submit)
                    .buttonStyle(.borderedProminent)
                    .tint(WidgetPalette.pink)
            }
        }
        .padding(16)
    }

    private func submit() {
        onSave(
            Int(blueTicketDraft) ?? 0,
            Int(redTicketDraft) ?? 0,
            upCharactersDraft
        )
    }

    private static func text(for value: Int) -> String {
        value == 0 ? "" : String(value)
    }
}

private struct RecordNumberField: View {
    let title: String
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titlePrimary)

            TextField("0", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onSubmit)
                .onChange(of: text) { _, value in
                    text = String(value.filter(\.isNumber).prefix(4))
                }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CrystalAdjustmentSheet<ProgressContent: View>: View {
    let title: String
    let initialSource: String
    @ViewBuilder let progressContent: () -> ProgressContent
    let onSave: (String, Int) -> Void
    let onClose: () -> Void

    @State private var sourceDraft = ""
    @State private var crystalsDraft = ""

    private var crystals: Int {
        Int(crystalsDraft.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var canConfirm: Bool {
        !sourceDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && crystals > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelHeader(title, onClose: onClose)

            progressContent()

            HStack(spacing: 10) {
                inputField("记录项", text: $sourceDraft, placeholder: "记录项")
                inputField("异方晶", text: $crystalsDraft, placeholder: "0")
            }

            HStack {
                Button("取消", action: onClose)

                Spacer()

                Button("确认") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .tint(WidgetPalette.pink)
                .disabled(!canConfirm)
            }
        }
        .padding(16)
        .onAppear {
            if sourceDraft.isEmpty {
                sourceDraft = initialSource
            }
        }
        .onChange(of: crystalsDraft) { _, value in
            crystalsDraft = filteredNumber(value)
        }
    }

    private func inputField(
        _ title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titlePrimary)

            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)
        }
        .frame(maxWidth: .infinity)
    }

    private func submit() {
        guard canConfirm else { return }
        onSave(
            sourceDraft.trimmingCharacters(in: .whitespacesAndNewlines),
            crystals
        )
    }

    private func filteredNumber(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(7))
    }
}

struct InventoryIncreaseSheet: View {
    let initialSource: String
    let onSave: (String, RewardValue) -> Void
    let onClose: () -> Void

    @State private var sourceDraft = ""
    @State private var crystalsDraft = ""
    @State private var blueTicketsDraft = ""
    @State private var redTicketsDraft = ""

    private var source: String {
        sourceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var value: RewardValue {
        RewardValue(
            crystals: number(from: crystalsDraft),
            blueTickets: number(from: blueTicketsDraft),
            redTickets: number(from: redTicketsDraft)
        )
    }

    private var canConfirm: Bool {
        !source.isEmpty && !value.isZero
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelHeader("增加", onClose: onClose)

            inputField("记录项", text: $sourceDraft, placeholder: "记录项")

            HStack(spacing: 10) {
                inputField("异方晶", text: $crystalsDraft, placeholder: "0")
                inputField("蓝票", text: $blueTicketsDraft, placeholder: "0")
                inputField("红票", text: $redTicketsDraft, placeholder: "0")
            }

            HStack {
                Button("取消", action: onClose)

                Spacer()

                Button("确认") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .tint(WidgetPalette.pink)
                .disabled(!canConfirm)
            }
        }
        .padding(16)
        .onAppear {
            if sourceDraft.isEmpty {
                sourceDraft = initialSource
            }
        }
        .onChange(of: crystalsDraft) { _, value in
            crystalsDraft = filteredNumber(value, limit: 7)
        }
        .onChange(of: blueTicketsDraft) { _, value in
            blueTicketsDraft = filteredNumber(value, limit: 4)
        }
        .onChange(of: redTicketsDraft) { _, value in
            redTicketsDraft = filteredNumber(value, limit: 4)
        }
    }

    private func inputField(
        _ title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titlePrimary)

            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)
        }
        .frame(maxWidth: .infinity)
    }

    private func submit() {
        guard canConfirm else { return }
        onSave(source, value)
    }

    private func number(from text: String) -> Int {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private func filteredNumber(_ value: String, limit: Int) -> String {
        String(value.filter(\.isNumber).prefix(limit))
    }
}

struct HistorySheetView: View {
    @ObservedObject var store: AppStateStore
    let onClose: () -> Void
    let onShowStatistics: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelHeader("历史记录", onClose: onClose) {
                if !store.history.isEmpty {
                    Button("统计", action: onShowStatistics)
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button("撤销最近一条") {
                        store.undoLatestHistoryEntry()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(WidgetPalette.pink)
                }
            }

            if store.history.isEmpty {
                ContentUnavailableView(
                    "还没有历史记录",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(store.history) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(entry.source)
                                        .font(.headline)

                                    Spacer()

                                    Text(entry.amountText)
                                        .font(.headline.weight(.bold))
                                }

                                Text(
                                    entry.timestamp.formatted(
                                        .dateTime
                                            .year()
                                            .month(.twoDigits)
                                            .day(.twoDigits)
                                            .hour(.twoDigits(amPM: .omitted))
                                            .minute(.twoDigits)
                                    )
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.18))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
    }
}

struct HistoryIncomeStatisticsSheet: View {
    @ObservedObject var store: AppStateStore
    let onClose: () -> Void

    private var calendar: Calendar { S1NSyncSupport.berlinCalendar }

    private var weeklyCalendar: Calendar {
        var calendar = self.calendar
        calendar.firstWeekday = 2 // Monday
        calendar.minimumDaysInFirstWeek = 1
        return calendar
    }

    private var monthInterval: DateInterval? {
        calendar.dateInterval(of: .month, for: Date())
    }

    private var weeklyIntervals: [DateInterval] {
        guard let monthInterval else { return [] }

        var result: [DateInterval] = []
        var cursor = monthInterval.start
        while cursor < monthInterval.end {
            guard let week = weeklyCalendar.dateInterval(of: .weekOfYear, for: cursor) else { break }
            if week.start < monthInterval.end && week.end > monthInterval.start {
                result.append(week)
            }
            cursor = week.end
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            panelHeader("收入统计", onClose: onClose)

            statisticsRow(
                title: "月总结",
                date: monthDetail,
                amount: store.incomeCrystalEquivalent(in: monthInterval ?? DateInterval(start: Date(), duration: 0))
            )

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(weeklyIntervals.enumerated()), id: \.offset) { _, interval in
                        statisticsRow(
                            title: "周总结",
                            date: weekDetail(interval),
                            amount: store.incomeCrystalEquivalent(in: interval)
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private func statisticsRow(
        title: String,
        date: String,
        amount: Int
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)

            Text(date)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(amount >= 0 ? "+" : "")\(amount)晶")
                .font(.headline.weight(.bold))
                .foregroundStyle(WidgetPalette.accent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.18))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
        }
    }

    private var monthDetail: String {
        guard let interval = monthInterval else { return "自然月" }
        let formatter = DateFormatter()
        formatter.calendar = weeklyCalendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: interval.start)
    }

    private func weekDetail(_ interval: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日"
        let end = interval.end.addingTimeInterval(-1)
        return "\(formatter.string(from: interval.start)) - \(formatter.string(from: end))"
    }
}

@ViewBuilder
@MainActor
private func panelHeader(_ title: String, onClose: @escaping () -> Void) -> some View {
    panelHeader(title, onClose: onClose) {
        EmptyView()
    }
}

@ViewBuilder
@MainActor
private func panelHeader<Actions: View>(
    _ title: String,
    onClose: @escaping () -> Void,
    @ViewBuilder actions: () -> Actions
) -> some View {
    HStack {
        Text(title)
            .font(.title3.weight(.semibold))

        Spacer()

        actions()

        Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}
