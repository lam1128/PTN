import Combine
import Foundation

#if os(macOS)
@MainActor
final class OneDriveStateSync: ObservableObject {
    private weak var store: AppStateStore?
    nonisolated(unsafe) private var observer: NSObjectProtocol?
    private var writeTask: Task<Void, Never>?
    private var fileURL: URL?
    private var lastFileModificationDate: Date?
    private var hasStarted = false

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        writeTask?.cancel()
    }

    func start(store: AppStateStore) {
        self.store = store
        guard !hasStarted else { return }
        hasStarted = true
        fileURL = Self.sharedFileURL()

        observer = NotificationCenter.default.addObserver(
            forName: .appStateDidChange,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scheduleWrite()
            }
        }

        synchronizeOnLaunch()
    }

    func refreshIfNeeded() {
        guard let fileURL,
              let modificationDate = Self.modificationDate(for: fileURL),
              modificationDate > (lastFileModificationDate ?? .distantPast),
              let data = try? Data(contentsOf: fileURL),
              let store else {
            return
        }

        if data != store.cloudSnapshotData,
           store.applyCloudSnapshotData(data) {
            store.markCloudSyncCompleted()
        }
        lastFileModificationDate = modificationDate
    }

    var sharedFileDescription: String {
        fileURL?.path ?? "未找到 OneDrive 文件夹"
    }

    private func synchronizeOnLaunch() {
        guard let fileURL, let store else { return }

        if let data = try? Data(contentsOf: fileURL),
           store.applyCloudSnapshotData(data) {
            store.markCloudSyncCompleted()
            lastFileModificationDate = Self.modificationDate(for: fileURL)
            return
        }

        guard store.hasMeaningfulLocalState else { return }
        writeCurrentState()
    }

    private func scheduleWrite() {
        writeTask?.cancel()
        writeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            self?.writeCurrentState()
        }
    }

    private func writeCurrentState() {
        guard let fileURL,
              let store,
              let data = store.cloudSnapshotData else {
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let temporaryURL = fileURL.appendingPathExtension("tmp")
            try data.write(to: temporaryURL, options: .atomic)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: temporaryURL)
            } else {
                try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
            }
            lastFileModificationDate = Self.modificationDate(for: fileURL)
            store.markCloudSyncCompleted()
        } catch {
            // OneDrive may be offline or not installed. The local UserDefaults
            // copy remains authoritative until the file becomes available.
        }
    }

    private static func sharedFileURL() -> URL? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        var roots: [URL] = [
            home.appendingPathComponent("OneDrive - TUM", isDirectory: true),
            home.appendingPathComponent("OneDrive", isDirectory: true)
        ]

        let cloudStorage = home.appendingPathComponent("Library/CloudStorage", isDirectory: true)
        if let entries = try? fileManager.contentsOfDirectory(
            at: cloudStorage,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            roots.append(contentsOf: entries.filter { $0.lastPathComponent.hasPrefix("OneDrive") })
        }

        guard let root = roots.first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            return nil
        }
        let folder = root.appendingPathComponent("PTN", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("ptn-shared-state.json")
    }

    private static func modificationDate(for url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}
#else

@MainActor
final class OneDriveStateSync: ObservableObject {
    func start(store: AppStateStore) {}
    func refreshIfNeeded() {}
    var sharedFileDescription: String { "仅 macOS 端自动同步" }
}
#endif
