import Foundation

@main
struct PullPlanRulesVerification {
    static func main() {
        expect(
            PullPlanRules.settledDrawCount(actualDraws: 100, inheritedPity: 17, remainingPity: 14) == 103,
            "settled draw count"
        )
        expect(PullPlanRules.collectiveInventoryCost(for: 7) == 7, "collective cost at 7")
        expect(PullPlanRules.collectiveInventoryCost(for: 10) == 7, "collective cost at 10")
        expect(PullPlanRules.collectiveInventoryCost(for: 11) == 8, "collective cost at 11")
        expect(PullPlanRules.collectiveInventoryCost(for: 12) == 9, "collective cost at 12")

        let previous = PullPlanTicketRecord(
            giftTickets: 0,
            blueTickets: 7,
            basePullCount: 24,
            settledDrawCount: 0,
            consumedBlueTickets: 7
        )
        let saved = PullPlanRules.recordForSave(
            previous: previous,
            giftTickets: 0,
            blueTickets: 100,
            upCount: 2,
            upTotal: 2,
            nonUpCharacters: "",
            inheritedPity: 17,
            currentPity: 14
        )
        expect(saved.settledDrawCount == 103, "record save formula")

        let pityPrevious = PullPlanTicketRecord(
            giftTickets: 0,
            blueTickets: 7,
            basePullCount: 7,
            settledDrawCount: 0,
            consumedBlueTickets: 7
        )
        let pityUpdated = PullPlanRules.recordAfterPityIncrease(
            previous: pityPrevious,
            previousPity: 7,
            inheritedPity: 0,
            currentPity: 17
        )
        expect(pityUpdated?.blueTickets == 17, "direct pity ticket count")
        expect(pityUpdated?.settledDrawCount == 0, "direct pity settled count")

        print("pull plan rules: passed")
    }

    private static func expect(_ condition: Bool, _ name: String) {
        guard condition else {
            fputs("pull plan rules: failed - \(name)\n", stderr)
            exit(1)
        }
    }
}
