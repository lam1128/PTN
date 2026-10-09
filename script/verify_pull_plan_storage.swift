import Foundation

@main
@MainActor
struct PullPlanStorageVerification {
    static func main() {
        let suiteName = "ptn-verification-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fail("create isolated UserDefaults")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(
            ["pull-plan-pity-event-arrest": 17],
            forKey: "ptn.pullPlanPityValues"
        )

        let now = DayStamp(year: 2026, month: 10, day: 9).date()
        let store = AppStateStore(defaults: defaults)
        store.setInventory(crystals: 0, blueTickets: 300, redTickets: 0, now: now)
        store.setPullPlanTicketRecord(
            for: "event-phanuel",
            giftTickets: 0,
            blueTickets: 17,
            upCount: 0,
            upTotal: 0,
            nonUpCharacters: "",
            now: now
        )
        store.setPullPlanPityValue(for: "event-phanuel", value: 14)
        store.setPullPlanTicketRecord(
            for: "event-phanuel",
            giftTickets: 0,
            blueTickets: 100,
            upCount: 2,
            upTotal: 2,
            nonUpCharacters: "",
            now: now
        )

        let recorded = store.pullPlanTicketRecord(for: "event-phanuel")
        expect(recorded.inheritedPity == 17, "fixed inherited pity")
        expect(recorded.settledDrawCount == 103, "recorded draw count")
        expect(recorded.upTotal == 2, "recorded UP total")
        expect(store.totalBlueTickets == 200, "inventory after record")

        store.undoLatestHistoryEntry(now: now)
        let restored = store.pullPlanTicketRecord(for: "event-phanuel")
        expect(restored.inheritedPity == 17, "inherited pity after undo")
        expect(restored.blueTickets == 17, "recorded tickets after undo")
        expect(restored.settledDrawCount == 17, "settled count after undo")
        expect(store.pullPlanPityValue(for: "event-phanuel") == 14, "pity after undo")
        expect(store.totalBlueTickets == 283, "inventory after undo")

        defaults.removePersistentDomain(forName: suiteName)
        print("pull plan storage: passed")
    }

    private static func expect(_ condition: Bool, _ name: String) {
        guard condition else { fail(name) }
    }

    private static func fail(_ name: String) -> Never {
        fputs("pull plan storage: failed - \(name)\n", stderr)
        exit(1)
    }
}
