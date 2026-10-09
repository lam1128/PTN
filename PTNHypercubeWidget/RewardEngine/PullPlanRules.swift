import Foundation

enum PullPlanRules {
    static func settledDrawCount(
        actualDraws: Int,
        inheritedPity: Int,
        remainingPity: Int
    ) -> Int {
        max(0, actualDraws + inheritedPity - remainingPity)
    }

    static func collectiveInventoryCost(for blueTickets: Int) -> Int {
        let draws = max(0, blueTickets)
        let discountedDraws = min(3, max(0, draws - 7))
        return draws - discountedDraws
    }

    static func recordForSave(
        previous: PullPlanTicketRecord,
        giftTickets: Int,
        blueTickets: Int,
        upCount: Int,
        upTotal: Int,
        nonUpCharacters: String,
        inheritedPity: Int,
        currentPity: Int
    ) -> PullPlanTicketRecord {
        let sanitizedGiftTickets = max(0, giftTickets)
        let sanitizedBlueTickets = max(0, blueTickets)
        let recordedTickets = sanitizedGiftTickets + sanitizedBlueTickets
        let fixedInheritedPity = max(0, inheritedPity)
        let hasRecordValues = recordedTickets > 0

        return PullPlanTicketRecord(
            giftTickets: sanitizedGiftTickets,
            blueTickets: sanitizedBlueTickets,
            upCount: hasRecordValues ? max(0, upCount) : 0,
            upTotal: hasRecordValues ? max(0, upTotal) : 0,
            nonUpCharacters: hasRecordValues
                ? nonUpCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                : "",
            basePullCount: hasRecordValues ? fixedInheritedPity + recordedTickets : 0,
            inheritedPity: hasRecordValues ? fixedInheritedPity : nil,
            settledDrawCount: hasRecordValues
                ? settledDrawCount(
                    actualDraws: recordedTickets,
                    inheritedPity: fixedInheritedPity,
                    remainingPity: max(0, currentPity)
                )
                : nil,
            consumedBlueTickets: previous.consumedBlueTickets,
            consumedCrystals: previous.consumedCrystals
        )
    }

    static func recordAfterPityIncrease(
        previous: PullPlanTicketRecord,
        previousPity: Int?,
        inheritedPity: Int,
        currentPity: Int
    ) -> PullPlanTicketRecord? {
        let oldPity = max(0, previousPity ?? 0)
        let newPity = max(0, currentPity)
        let drawIncrease = newPity - oldPity
        guard drawIncrease > 0 else { return nil }

        let recordedTickets = previous.giftTickets + previous.blueTickets + drawIncrease
        let fixedInheritedPity = max(0, inheritedPity)
        return PullPlanTicketRecord(
            giftTickets: previous.giftTickets,
            blueTickets: previous.blueTickets + drawIncrease,
            upCount: previous.upCount,
            upTotal: previous.upTotal,
            nonUpCharacters: previous.nonUpCharacters,
            basePullCount: fixedInheritedPity + recordedTickets,
            inheritedPity: fixedInheritedPity,
            settledDrawCount: settledDrawCount(
                actualDraws: recordedTickets,
                inheritedPity: fixedInheritedPity,
                remainingPity: newPity
            ),
            consumedBlueTickets: previous.consumedBlueTickets,
            consumedCrystals: previous.consumedCrystals
        )
    }
}
