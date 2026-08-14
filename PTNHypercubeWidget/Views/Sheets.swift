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
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("蓝票")
                    .font(.subheadline.weight(.medium))
                TextField("输入当前蓝票数", text: $blueTicketDraft)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("红票")
                    .font(.subheadline.weight(.medium))
                TextField("输入当前红票数", text: $redTicketDraft)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("取消", action: onClose)

                Spacer()

                Button("保存") {
                    if let parsedCrystals, let parsedBlueTickets, let parsedRedTickets {
                        onSave(parsedCrystals, parsedBlueTickets, parsedRedTickets)
                    }
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
