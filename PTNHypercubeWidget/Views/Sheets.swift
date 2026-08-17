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
    let onSave: (Int, Int, Int, Int) -> Void
    let onClose: () -> Void

    @State private var giftTicketDraft: String
    @State private var blueTicketDraft: String
    @State private var upCountDraft: String
    @State private var upTotalDraft: String
    @State private var upTotalManuallyEdited: Bool

    init(
        bannerTitle: String,
        currentGiftTickets: Int,
        currentBlueTickets: Int,
        availableBlueTickets: Int,
        currentUpCount: Int,
        currentUpTotal: Int,
        onSave: @escaping (Int, Int, Int, Int) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.bannerTitle = bannerTitle
        self.currentGiftTickets = currentGiftTickets
        self.currentBlueTickets = currentBlueTickets
        self.availableBlueTickets = availableBlueTickets
        self.currentUpCount = currentUpCount
        self.currentUpTotal = currentUpTotal
        self.onSave = onSave
        self.onClose = onClose
        _giftTicketDraft = State(initialValue: currentGiftTickets == 0 ? "" : String(currentGiftTickets))
        _blueTicketDraft = State(initialValue: currentBlueTickets == 0 ? "" : String(currentBlueTickets))
        _upCountDraft = State(initialValue: currentUpCount == 0 ? "" : String(currentUpCount))
        _upTotalDraft = State(initialValue: currentUpTotal == 0 ? "" : String(currentUpTotal))
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

    private var isValid: Bool {
        blueTickets >= 0 && blueTickets <= availableBlueTickets
    }

    private var hasChanges: Bool {
        giftTickets != currentGiftTickets ||
            blueTickets != currentBlueTickets ||
            upCount != currentUpCount ||
            upTotal != currentUpTotal
    }

    private var canConfirm: Bool {
        isValid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelHeader("记录·\(bannerTitle)", onClose: onClose)

            HStack(spacing: 10) {
                ticketField("赠送票", text: $giftTicketDraft, onSubmit: submit)
                ticketField("蓝票", text: $blueTicketDraft, onSubmit: submit)
            }

            HStack(spacing: 10) {
                ticketField("UP数", text: $upCountDraft, onSubmit: submit)
                ticketField("UP总数", text: upTotalEditingBinding, onSubmit: submit)
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
        guard isValid else { return }
        if hasChanges {
            onSave(giftTickets, blueTickets, upCount, upTotal)
        } else {
            onClose()
        }
    }

    private func ticketField(
        _ title: String,
        text: Binding<String>,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.titlePrimary)

            TextField("0", text: text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onSubmit)
        }
        .frame(maxWidth: .infinity)
    }

    private func filteredNumber(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(4))
    }
}

struct HistorySheetView: View {
    @ObservedObject var store: AppStateStore
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelHeader("历史记录", onClose: onClose)

            if store.history.isEmpty {
                ContentUnavailableView(
                    "还没有历史记录",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    Spacer()
                    Button("撤销最近一条") {
                        store.undoLatestHistoryEntry()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WidgetPalette.pink)
                }

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

@ViewBuilder
@MainActor
private func panelHeader(_ title: String, onClose: @escaping () -> Void) -> some View {
    HStack {
        Text(title)
            .font(.title3.weight(.semibold))

        Spacer()

        Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}
