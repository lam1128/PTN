import Foundation

extension AppStateStore {
    static func loadHistory(from data: Data?) -> [HistoryEntry] {
        guard let data else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = (try? decoder.decode([HistoryEntry].self, from: data)) ?? []
        return entries.map { entry in
            let migratedSource = RewardSchedule.migratedHistorySource(
                entry.source,
                claimKey: entry.claimKey
            )
            guard migratedSource != entry.source else {
                return entry
            }
            return HistoryEntry(
                id: entry.id,
                timestamp: entry.timestamp,
                source: migratedSource,
                value: entry.value,
                claimKey: entry.claimKey,
                amountTextOverride: entry.amountTextOverride,
                generalPoolRecordBeforeChange: entry.generalPoolRecordBeforeChange,
                pullPlanRecordBeforeChange: entry.pullPlanRecordBeforeChange,
                pullPlanPityValueBeforeChange: entry.pullPlanPityValueBeforeChange
            )
        }
    }

    static func loadPullPlanTicketRecords(from data: Data?) -> [String: PullPlanTicketRecord] {
        guard let data else { return [:] }
        return (try? JSONDecoder().decode([String: PullPlanTicketRecord].self, from: data)) ?? [:]
    }

    static func loadGeneralPoolRecord(from data: Data?) -> GeneralPoolRecord {
        guard let data else { return .empty }
        return (try? JSONDecoder().decode(GeneralPoolRecord.self, from: data)) ?? .empty
    }

    static func migratedPullPlanPityValues(from rawValues: [String: Int]) -> [String: Int] {
        guard !rawValues.isEmpty else { return rawValues }

        var migrated = rawValues
        let legacySharedKey = "pull-plan-pity-single-arrest"
        if let sharedValue = migrated.removeValue(forKey: legacySharedKey) {
            for key in ["pull-plan-pity-event-arrest", "pull-plan-pity-routine-arrest"]
                where migrated[key] == nil {
                migrated[key] = sharedValue
            }
        }

        for banner in RewardSchedule.pullPlanBanners {
            let legacyKey = "pull-plan-pity-\(banner.id)"
            let groupKey = RewardSchedule.pullPlanPityKey(for: banner.id)

            guard legacyKey != groupKey else { continue }
            guard let legacyValue = migrated[legacyKey] else { continue }
            guard migrated[groupKey] == nil else { continue }

            migrated[groupKey] = legacyValue
        }

        return migrated
    }
}
