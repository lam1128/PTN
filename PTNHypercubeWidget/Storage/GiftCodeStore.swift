import Combine
import Foundation

@MainActor
final class GiftCodeStore: ObservableObject {
    @Published private(set) var codes: [GiftCode]

    private static let cacheKey = "ptn.s1nGiftCodes"
    private static let successfulRefreshSlotKey = "ptn.s1nGiftCodesSuccessfulRefreshSlot"
    private nonisolated static let refreshWindowDays = 7

    private let defaults: UserDefaults
    private var lastAttemptAt: Date?
    private var isRefreshing = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.codes = Self.loadCachedCodes(from: defaults) ?? Self.fallbackCodes
    }

    func activeCodes(
        for anchorStart: Date?,
        limit: Int,
        now: Date = Date()
    ) -> [GiftCode] {
        guard limit > 0 else { return [] }
        let calendar = Self.refreshCalendar
        let lowerBound = anchorStart.flatMap {
            calendar.date(byAdding: .day, value: -Self.refreshWindowDays, to: $0)
        }
        let upperBound = anchorStart.flatMap {
            calendar.date(byAdding: .day, value: Self.refreshWindowDays, to: $0)
        }

        return Array(codes
            .filter { code in
                guard code.isActive(at: now) else { return false }
                if let lowerBound, code.startsAt < lowerBound { return false }
                if let upperBound, code.startsAt > upperBound { return false }
                return true
            }
            .sorted {
                if $0.startsAt != $1.startsAt { return $0.startsAt < $1.startsAt }
                return $0.id < $1.id
            }
            .prefix(limit))
    }

    func refreshIfNeeded(now: Date = Date()) {
        guard !isRefreshing,
              let refreshSlot = Self.refreshSlot(at: now),
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
                let fetchedCodes = try await Self.fetchActiveEnglishCodes(at: now)
                codes = fetchedCodes
                Self.save(fetchedCodes, to: defaults)
                defaults.set(refreshSlot, forKey: Self.successfulRefreshSlotKey)
            } catch {
                // Keep the last successful cache or bundled fallback when S1N is unavailable.
            }
        }
    }

    private nonisolated static var refreshCalendar: Calendar {
        S1NSyncSupport.berlinCalendar
    }

    private nonisolated static func refreshSlot(at date: Date) -> String? {
        let calendar = refreshCalendar
        let day = calendar.startOfDay(for: date)
        let isInsideRefreshWindow = RewardSchedule.pullPlanBanners.contains { banner in
            guard banner.title == RewardSchedule.activityPoolTitle || banner.title == "限定池" else {
                return false
            }
            let startDay = calendar.startOfDay(for: banner.startsAt(in: calendar))
            let distance = abs(calendar.dateComponents([.day], from: startDay, to: day).day ?? .max)
            return distance <= refreshWindowDays
        }
        guard isInsideRefreshWindow else { return nil }

        return S1NSyncSupport.refreshSlot(at: date)
    }

    private nonisolated static func fetchActiveEnglishCodes(at now: Date) async throws -> [GiftCode] {
        let formatter = ISO8601DateFormatter()
        let futureLimit = now.addingTimeInterval(20 * 24 * 60 * 60)

        let data = try await S1NSyncSupport.fetch(queryItems: [
            URLQueryItem(name: "type", value: "eq.Gift Code"),
            URLQueryItem(name: "select", value: "id,title,start,end"),
            URLQueryItem(name: "end", value: "gt.\(formatter.string(from: now))"),
            URLQueryItem(name: "start", value: "lt.\(formatter.string(from: futureLimit))")
        ])

        let records = try JSONDecoder().decode([RemoteGiftCode].self, from: data)
        return records.compactMap { record in
            guard isEnglishCode(record.title),
                  let startsAt = formatter.date(from: record.start),
                  let endsAt = formatter.date(from: record.end),
                  startsAt <= now,
                  now < endsAt else {
                return nil
            }
            return GiftCode(id: record.id, code: record.title, startsAt: startsAt, endsAt: endsAt)
        }
    }

    private nonisolated static func isEnglishCode(_ value: String) -> Bool {
        !value.isEmpty && value.unicodeScalars.allSatisfy {
            $0.isASCII && CharacterSet.alphanumerics.contains($0)
        }
    }

    private static func loadCachedCodes(from defaults: UserDefaults) -> [GiftCode]? {
        guard let data = defaults.data(forKey: cacheKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([GiftCode].self, from: data)
    }

    private static func save(_ codes: [GiftCode], to defaults: UserDefaults) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(codes) {
            defaults.set(data, forKey: cacheKey)
        }
    }

    private struct RemoteGiftCode: Decodable {
        let id: Int
        let title: String
        let start: String
        let end: String
    }

    private static let fallbackCodes: [GiftCode] = {
        let formatter = ISO8601DateFormatter()
        let end = formatter.date(from: "2026-08-26T05:59:59Z")!
        return [
            GiftCode(
                id: 359,
                code: "DisCityRisingAcademicStar",
                startsAt: formatter.date(from: "2026-08-04T06:00:00Z")!,
                endsAt: end
            ),
            GiftCode(
                id: 362,
                code: "IntheZone",
                startsAt: formatter.date(from: "2026-08-05T06:00:00Z")!,
                endsAt: end
            ),
            GiftCode(
                id: 365,
                code: "KnowledgeIsPower",
                startsAt: formatter.date(from: "2026-08-06T06:00:00Z")!,
                endsAt: end
            ),
            GiftCode(
                id: 370,
                code: "UNDERBLUE",
                startsAt: formatter.date(from: "2026-08-08T06:00:00Z")!,
                endsAt: end
            )
        ]
    }()
}
