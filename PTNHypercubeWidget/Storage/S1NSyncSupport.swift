import Foundation

enum S1NSyncSupport {
    static let endpoint = "https://qcropwcwnvrflrzlsucj.supabase.co/rest/v1/timeline"
    // S1N publishes this read-only key in its website client.
    static let apiKey = "sb_publishable_Om6Y9pQ7xSn2Ppv1HqMrLQ_dtkHSV7X"
    static let retryInterval: TimeInterval = 30 * 60

    static var berlinCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    static func refreshSlot(at date: Date) -> String? {
        refreshSlot(at: date, dailyTimes: [(8, 0), (16, 0)])
    }

    static func pullPlanRefreshSlot(at date: Date) -> String? {
        refreshSlot(at: date, dailyTimes: [(12, 50), (13, 10)])
    }

    private static func refreshSlot(
        at date: Date,
        dailyTimes: [(hour: Int, minute: Int)]
    ) -> String? {
        let calendar = berlinCalendar
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let currentMinute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        guard let slot = dailyTimes.last(where: { currentMinute >= $0.hour * 60 + $0.minute }) else {
            return nil
        }
        return String(
            format: "%04d-%02d-%02d-%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            slot.hour,
            slot.minute
        )
    }

    static func fetch(queryItems: [URLQueryItem]) async throws -> Data {
        guard var components = URLComponents(string: endpoint) else {
            throw URLError(.badURL)
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

struct PullPlanDateOverride: Codable, Hashable {
    let sourceID: Int
    let start: DayStamp
    let end: DayStamp
    let startHour: Int?
    let startMinute: Int?
    let endHour: Int?
    let endMinute: Int?
    let timeZoneIdentifier: String?
}

enum PullPlanDateOverrideCache {
    private static let key = "ptn.s1nPullPlanDateOverrides"

    static func load(defaults: UserDefaults = .standard) -> [PullPlanDateOverride] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([PullPlanDateOverride].self, from: data)) ?? []
    }

    static func save(_ overrides: [PullPlanDateOverride], defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(overrides) else { return }
        defaults.set(data, forKey: key)
    }
}

enum PullPlanBannerCache {
    private static let key = "ptn.s1nAppendedPullPlanBanners"

    static func load(defaults: UserDefaults = .standard) -> [PullPlanBanner] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([PullPlanBanner].self, from: data)) ?? []
    }

    static func save(_ banners: [PullPlanBanner], defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(banners) else { return }
        defaults.set(data, forKey: key)
    }
}
