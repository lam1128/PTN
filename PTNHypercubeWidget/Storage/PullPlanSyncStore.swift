import Combine
import Foundation

@MainActor
final class PullPlanSyncStore: ObservableObject {
    @Published private(set) var revision = 0

    private static let successfulRefreshSlotKey = "ptn.s1nPullPlanSuccessfulRefreshSlot"
    private let defaults: UserDefaults
    private var lastAttemptAt: Date?
    private var isRefreshing = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func refreshIfNeeded(now: Date = Date()) {
        guard !isRefreshing,
              let refreshSlot = S1NSyncSupport.refreshSlot(at: now),
              defaults.string(forKey: Self.successfulRefreshSlotKey) != refreshSlot else {
            return
        }
        if let lastAttemptAt,
           now.timeIntervalSince(lastAttemptAt) < S1NSyncSupport.retryInterval {
            return
        }

        isRefreshing = true
        lastAttemptAt = now

        Task {
            defer { isRefreshing = false }
            do {
                let fetched = try await Self.fetchConfirmedBanners(at: now)
                let existing = PullPlanBannerCache.load(defaults: defaults)
                let known = RewardSchedule.pullPlanBanners
                let knownIDs = Set(known.map(\.id))
                let knownSourceIDs = Set(known.compactMap(\.sourceID))
                let knownIdentities = Set(known.map(\.syncIdentity))
                let additions = fetched.filter {
                    !knownIDs.contains($0.id)
                        && !knownSourceIDs.contains($0.sourceID ?? -1)
                        && !knownIdentities.contains($0.syncIdentity)
                }

                if !additions.isEmpty {
                    PullPlanBannerCache.save(existing + additions, defaults: defaults)
                    revision += 1
                }
                defaults.set(refreshSlot, forKey: Self.successfulRefreshSlotKey)
            } catch {
                // Existing local and cached banners remain available; retry later in this slot.
            }
        }
    }

    private nonisolated static func fetchConfirmedBanners(at now: Date) async throws -> [PullPlanBanner] {
        let formatter = ISO8601DateFormatter()

        let data = try await S1NSyncSupport.fetch(queryItems: [
            URLQueryItem(name: "type", value: "eq.banner"),
            URLQueryItem(name: "confirmed", value: "eq.true"),
            URLQueryItem(name: "end", value: "gt.\(formatter.string(from: now))"),
            URLQueryItem(name: "select", value: "id,title,banner,start,end,confirmed"),
            URLQueryItem(name: "order", value: "start.asc")
        ])

        let records = try JSONDecoder().decode([RemoteBanner].self, from: data)
        return records.compactMap { makeBanner(from: $0, formatter: formatter) }
    }

    private nonisolated static func makeBanner(
        from record: RemoteBanner,
        formatter: ISO8601DateFormatter
    ) -> PullPlanBanner? {
        guard record.confirmed,
              let start = formatter.date(from: record.start),
              let end = formatter.date(from: record.end),
              let mapping = bannerMapping(type: record.banner, title: record.title) else {
            return nil
        }

        let calendar = S1NSyncSupport.berlinCalendar
        let startParts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start)
        let endParts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: end)
        guard let startYear = startParts.year,
              let startMonth = startParts.month,
              let startDay = startParts.day,
              let endYear = endParts.year,
              let endMonth = endParts.month,
              let endDay = endParts.day else {
            return nil
        }

        return PullPlanBanner(
            id: "s1n-banner-\(record.id)",
            sourceID: record.id,
            title: mapping.title,
            start: DayStamp(year: startYear, month: startMonth, day: startDay),
            end: DayStamp(year: endYear, month: endMonth, day: endDay),
            startHour: startParts.hour ?? 0,
            startMinute: startParts.minute ?? 0,
            endHour: endParts.hour ?? 0,
            endMinute: endParts.minute ?? 0,
            timeZoneIdentifier: "Europe/Berlin",
            endTimeZoneIdentifier: "Europe/Berlin",
            characters: mapping.characters,
            selectionKind: mapping.selectionKind
        )
    }

    private nonisolated static func bannerMapping(
        type rawType: String,
        title rawTitle: String
    ) -> (title: String, characters: [String], selectionKind: PullPlanSelectionKind)? {
        let type = rawType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case "event":
            return (RewardSchedule.activityPoolTitle, [title], .none)
        case "routine":
            return ("复刻池", [removingRerunSuffix(from: title)], .none)
        case "directional":
            return ("定轨池", split(title, separator: "&"), .targetChoice)
        case "collective":
            return ("统合池", split(title, separator: ","), .targetChoice)
        case "exclusive", "exclusive rerun":
            return ("限定池", split(removingRerunSuffix(from: title), separator: "&"), .lockCount)
        default:
            return nil
        }
    }

    private nonisolated static func split(_ value: String, separator: Character) -> [String] {
        value.split(separator: separator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private nonisolated static func removingRerunSuffix(from value: String) -> String {
        value.replacingOccurrences(
            of: #"\s+Rerun$"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    private struct RemoteBanner: Decodable {
        let id: Int
        let title: String
        let banner: String
        let start: String
        let end: String
        let confirmed: Bool
    }
}
