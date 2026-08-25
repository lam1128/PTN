import Combine
import Foundation
#if canImport(CloudKit)
import CloudKit
#endif

struct AppStateCloudSnapshot: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let totalCrystals: Int
    let totalBlueTickets: Int
    let totalRedTickets: Int
    let claimedRewardKeys: [String]
    let history: [HistoryEntry]
    let manualCycleVersions: [String: Int]
    let dailyCycleVersions: [String: Int]
    let pullPlanBannerProgressRawValues: [String: Int]
    let selectedPullPlanUpChoices: [String: String]
    let selectedPullPlanLockChoices: [String: Int]
    let pullPlanPityValues: [String: Int]
    let pullPlanTicketRecords: [String: PullPlanTicketRecord]
    let hasPremiumSecretPass: Bool
    let usesExtraTranslucentBackground: Bool
    let automaticStorageLastUpdateAt: Date?
    let automaticStorageCalibrationVersion: Int

    init(
        totalCrystals: Int,
        totalBlueTickets: Int,
        totalRedTickets: Int,
        claimedRewardKeys: [String],
        history: [HistoryEntry],
        manualCycleVersions: [String: Int],
        dailyCycleVersions: [String: Int],
        pullPlanBannerProgressRawValues: [String: Int],
        selectedPullPlanUpChoices: [String: String],
        selectedPullPlanLockChoices: [String: Int],
        pullPlanPityValues: [String: Int],
        pullPlanTicketRecords: [String: PullPlanTicketRecord],
        hasPremiumSecretPass: Bool,
        usesExtraTranslucentBackground: Bool,
        automaticStorageLastUpdateAt: Date?,
        automaticStorageCalibrationVersion: Int
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.totalCrystals = totalCrystals
        self.totalBlueTickets = totalBlueTickets
        self.totalRedTickets = totalRedTickets
        self.claimedRewardKeys = claimedRewardKeys
        self.history = history
        self.manualCycleVersions = manualCycleVersions
        self.dailyCycleVersions = dailyCycleVersions
        self.pullPlanBannerProgressRawValues = pullPlanBannerProgressRawValues
        self.selectedPullPlanUpChoices = selectedPullPlanUpChoices
        self.selectedPullPlanLockChoices = selectedPullPlanLockChoices
        self.pullPlanPityValues = pullPlanPityValues
        self.pullPlanTicketRecords = pullPlanTicketRecords
        self.hasPremiumSecretPass = hasPremiumSecretPass
        self.usesExtraTranslucentBackground = usesExtraTranslucentBackground
        self.automaticStorageLastUpdateAt = automaticStorageLastUpdateAt
        self.automaticStorageCalibrationVersion = automaticStorageCalibrationVersion
    }
}

extension Notification.Name {
    static let appStateDidChange = Notification.Name("PTNAppStateDidChange")
}

#if canImport(CloudKit)
@MainActor
final class CloudKitStateSync: ObservableObject {
    private static let recordType = "PTNAppState"
    private static let recordName = "personal-state"

    private let database: CKDatabase
    private weak var store: AppStateStore?
    private var observer: NSObjectProtocol?
    private var uploadTask: Task<Void, Never>?
    private var hasStarted = false

    init() {
        database = CKContainer.default().privateCloudDatabase
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        uploadTask?.cancel()
    }

    func start(store: AppStateStore) {
        self.store = store
        guard !hasStarted else { return }
        hasStarted = true

        observer = NotificationCenter.default.addObserver(
            forName: .appStateDidChange,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scheduleUpload()
            }
        }

        Task { [weak self] in
            await self?.synchronizeOnLaunch()
        }
    }

    private func synchronizeOnLaunch() async {
        guard let store else { return }

        do {
            let record = try await database.record(
                for: CKRecord.ID(recordName: Self.recordName)
            )

            guard let data = record["snapshot"] as? Data else { return }

            // The private CloudKit database is the shared source for a new
            // device. Local state is only uploaded when no cloud record exists.
            if !store.hasCompletedCloudSync || !store.hasMeaningfulLocalState {
                if store.applyCloudSnapshotData(data) {
                    store.markCloudSyncCompleted()
                }
            } else if let localData = store.cloudSnapshotData,
                      localData != data {
                // With one personal account, the latest state visible in
                // CloudKit wins when returning to an already-synced device.
                if store.applyCloudSnapshotData(data) {
                    store.markCloudSyncCompleted()
                }
            }
        } catch let error as CKError where error.code == .unknownItem {
            await uploadCurrentStateIfAvailable()
        } catch {
            // iCloud may be unavailable or disabled. Local UserDefaults keeps
            // the app fully usable and the next launch retries synchronization.
        }
    }

    private func scheduleUpload() {
        uploadTask?.cancel()
        uploadTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await self?.uploadCurrentStateIfAvailable()
        }
    }

    private func uploadCurrentStateIfAvailable() async {
        guard let store,
              store.hasMeaningfulLocalState,
              let data = store.cloudSnapshotData else {
            return
        }

        let recordID = CKRecord.ID(recordName: Self.recordName)
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
            record["snapshot"] = data as CKRecordValue
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: Self.recordType, recordID: recordID)
            record["snapshot"] = data as CKRecordValue
        } catch {
            return
        }

        do {
            _ = try await database.save(record)
            store.markCloudSyncCompleted()
        } catch {
            // Keep the local data and retry on the next local change or launch.
        }
    }
}
#else

@MainActor
final class CloudKitStateSync: ObservableObject {
    func start(store: AppStateStore) {}
}
#endif
