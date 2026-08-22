import Foundation

enum RewardCategory: String, Codable, Hashable {
    case daily
    case weekly
    case monthly
    case eventTrial
    case darkZone
    case dataGap
    case unknownSchedule
    case manualAdjustment
}

enum PullPlanSelectionKind: String, Codable, Hashable {
    case none
    case targetChoice
    case lockCount
}

enum PullPlanBannerProgress: Int, Codable, Hashable {
    case none = 0
    case planned = 1
    case completed = 2
}

struct RewardValue: Codable, Hashable {
    let crystals: Int
    let blueTickets: Int
    let redTickets: Int

    init(crystals: Int = 0, blueTickets: Int = 0, redTickets: Int = 0) {
        self.crystals = crystals
        self.blueTickets = blueTickets
        self.redTickets = redTickets
    }

    // UI 顶部的“总抽数”按当前约定统计蓝票和红票，
    // 与下方“今日折合晶数”的显示口径不同，后者统一换算成异方晶。
    var drawEquivalent: Double {
        Double(crystals) / 180.0 + Double(blueTickets + redTickets)
    }

    var isZero: Bool {
        crystals == 0 && blueTickets == 0 && redTickets == 0
    }

    static let zero = RewardValue()

    static func + (lhs: RewardValue, rhs: RewardValue) -> RewardValue {
        RewardValue(
            crystals: lhs.crystals + rhs.crystals,
            blueTickets: lhs.blueTickets + rhs.blueTickets,
            redTickets: lhs.redTickets + rhs.redTickets
        )
    }

    static func - (lhs: RewardValue, rhs: RewardValue) -> RewardValue {
        RewardValue(
            crystals: lhs.crystals - rhs.crystals,
            blueTickets: lhs.blueTickets - rhs.blueTickets,
            redTickets: lhs.redTickets - rhs.redTickets
        )
    }

    private enum CodingKeys: String, CodingKey {
        case crystals
        case blueTickets
        case redTickets
        case tickets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let crystals = try container.decodeIfPresent(Int.self, forKey: .crystals) ?? 0
        let blueTickets = try container.decodeIfPresent(Int.self, forKey: .blueTickets)
            ?? container.decodeIfPresent(Int.self, forKey: .tickets)
            ?? 0
        let redTickets = try container.decodeIfPresent(Int.self, forKey: .redTickets) ?? 0
        self.init(crystals: crystals, blueTickets: blueTickets, redTickets: redTickets)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(crystals, forKey: .crystals)
        try container.encode(blueTickets, forKey: .blueTickets)
        try container.encode(redTickets, forKey: .redTickets)
    }
}

struct DayStamp: Codable, Hashable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    func date(in calendar: Calendar = .rewardCalendar) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12
        )
        guard let date = calendar.date(from: components) else {
            fatalError("Unable to construct date for \(key)")
        }
        return date
    }

    static func from(_ date: Date, calendar: Calendar = .rewardCalendar) -> DayStamp {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return DayStamp(
            year: components.year ?? 1970,
            month: components.month ?? 1,
            day: components.day ?? 1
        )
    }

    static func rewardDay(from date: Date, calendar: Calendar = .rewardCalendar) -> DayStamp {
        DayStamp.from(calendar.rewardReferenceDate(for: date), calendar: calendar)
    }

    // 抽卡规划与普通奖励不是同一刷新点，单独保留一个“卡池日”口径。
    static func bannerDay(from date: Date, calendar: Calendar = .rewardCalendar) -> DayStamp {
        DayStamp.from(calendar.bannerReferenceDate(for: date), calendar: calendar)
    }

    static func < (lhs: DayStamp, rhs: DayStamp) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}

struct RewardItem: Identifiable, Hashable {
    let id: String
    let category: RewardCategory
    let title: String
    let footnote: String?
    let displayValue: RewardValue
    let claimValue: RewardValue
    let claimSource: String
    let claimKey: String
    let sortOrder: Int
    let isClaimed: Bool
}

struct RewardSourceDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let value: RewardValue
}

struct GiftCode: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let code: String
    let startsAt: Date
    let endsAt: Date

    func isActive(at date: Date) -> Bool {
        startsAt <= date && date < endsAt
    }
}

struct PullPlanTicketRecord: Codable, Hashable {
    let giftTickets: Int
    let blueTickets: Int
    let upCount: Int
    let upTotal: Int
    let basePullCount: Int
    let consumedBlueTickets: Int
    let consumedCrystals: Int

    static let empty = PullPlanTicketRecord(
        giftTickets: 0,
        blueTickets: 0,
        upCount: 0,
        upTotal: 0,
        basePullCount: 0,
        consumedBlueTickets: 0,
        consumedCrystals: 0
    )

    var isEmpty: Bool {
        giftTickets == 0 && blueTickets == 0 && upCount == 0 && upTotal == 0 && basePullCount == 0
    }

    init(
        giftTickets: Int,
        blueTickets: Int,
        upCount: Int = 0,
        upTotal: Int = 0,
        basePullCount: Int = 0,
        consumedBlueTickets: Int? = nil,
        consumedCrystals: Int = 0
    ) {
        self.giftTickets = giftTickets
        self.blueTickets = blueTickets
        self.upCount = upCount
        self.upTotal = upTotal
        self.basePullCount = basePullCount
        self.consumedBlueTickets = consumedBlueTickets ?? blueTickets
        self.consumedCrystals = consumedCrystals
    }

    private enum CodingKeys: String, CodingKey {
        case giftTickets
        case blueTickets
        case upCount
        case upTotal
        case basePullCount
        case consumedBlueTickets
        case consumedCrystals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            giftTickets: try container.decodeIfPresent(Int.self, forKey: .giftTickets) ?? 0,
            blueTickets: try container.decodeIfPresent(Int.self, forKey: .blueTickets) ?? 0,
            upCount: try container.decodeIfPresent(Int.self, forKey: .upCount) ?? 0,
            upTotal: try container.decodeIfPresent(Int.self, forKey: .upTotal) ?? 0,
            basePullCount: try container.decodeIfPresent(Int.self, forKey: .basePullCount) ?? 0,
            consumedBlueTickets: try container.decodeIfPresent(Int.self, forKey: .consumedBlueTickets),
            consumedCrystals: try container.decodeIfPresent(Int.self, forKey: .consumedCrystals) ?? 0
        )
    }
}

struct PullPlanRecordSummary: Identifiable, Hashable {
    let id: String
    let title: String
    let drawCount: Int
    let upCount: Int
    let upTotal: Int
}


struct ManualUnknownReward: Identifiable, Hashable {
    let id: String
    let title: String
    let value: RewardValue
    let claimSource: String
    let claimKey: String
    let cycleVersion: Int
    let remainingText: String?
    let showsAdvanceCycleButton: Bool
    let isClaimed: Bool
}

enum PermanentRewardTiming: Hashable {
    case maintenance
    case questionnaire
}

struct PermanentRewardDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let value: RewardValue
    let sortOrder: Int
    let timing: PermanentRewardTiming
}

enum DailyProgressDisplay: String, Hashable {
    case value
    case count
}

enum DailyProgressTint: String, Hashable {
    case neutral
    case orange
    case purple
    case blue
}

enum DailyProgressSlotShape: String, Hashable {
    case circle
    case capsule
}

struct DailyProgressSlotDefinition: Hashable {
    let id: String
    let value: RewardValue
    let rewardValues: [RewardValue]
    let labels: [String]
    let historySources: [String]
    let maxCount: Int
    let tint: DailyProgressTint
    let completionBonus: RewardValue
    let showsCheckmark: Bool
    let unlockedBySlotIndex: Int?
    let shape: DailyProgressSlotShape?

    init(
        id: String,
        value: RewardValue,
        rewardValues: [RewardValue]? = nil,
        labels: [String] = [],
        historySources: [String] = [],
        maxCount: Int,
        tint: DailyProgressTint,
        completionBonus: RewardValue,
        showsCheckmark: Bool = false,
        unlockedBySlotIndex: Int? = nil,
        shape: DailyProgressSlotShape? = nil
    ) {
        self.id = id
        self.value = value
        self.rewardValues = rewardValues ?? Array(repeating: value, count: maxCount)
        self.labels = labels
        self.historySources = historySources
        self.maxCount = maxCount
        self.tint = tint
        self.completionBonus = completionBonus
        self.showsCheckmark = showsCheckmark
        self.unlockedBySlotIndex = unlockedBySlotIndex
        self.shape = shape
    }
}

struct DailyProgressSlot: Identifiable, Hashable {
    let id: String
    let index: Int
    let value: RewardValue
    let claimKeys: [String]
    let claimedStages: [Bool]
    let count: Int
    let rewardValues: [RewardValue]
    let labels: [String]
    let historySources: [String]
    let tint: DailyProgressTint
    let completionBonus: RewardValue
    let completionClaimKey: String?
    let isCompletionClaimed: Bool
    let showsCheckmark: Bool
    let isUnlocked: Bool
    let shape: DailyProgressSlotShape?

    var isClaimed: Bool {
        count > 0
    }

    func isStageClaimed(at index: Int) -> Bool {
        claimedStages.indices.contains(index) && claimedStages[index]
    }

    var isComplete: Bool {
        count == claimKeys.count
    }

    var canComplete: Bool {
        isComplete && !isCompletionClaimed && completionClaimKey != nil
    }

    var isDisplayedClaimed: Bool {
        isClaimed && !isCompletionClaimed
    }

    var maxCount: Int {
        claimKeys.count
    }

    var claimedValue: RewardValue {
        rewardValues.prefix(count).reduce(.zero, +)
    }

    var displayLabel: String? {
        guard !labels.isEmpty else { return nil }
        return labels[min(count, labels.count - 1)]
    }

    func historySource(moduleTitle: String, rewardIndex: Int) -> String {
        guard historySources.indices.contains(rewardIndex) else {
            return "\(moduleTitle) 第\(index)项"
        }
        return historySources[rewardIndex]
    }
}

struct DailyProgress: Identifiable, Hashable {
    let id: String
    let title: String
    let slots: [DailyProgressSlot]
    let display: DailyProgressDisplay
    let showsCycleAdvanceButton: Bool
    let rowCapacity: Int?

    var isCompleted: Bool {
        display != .count && slots.allSatisfy(\.isComplete)
    }

    var claimedValue: RewardValue {
        slots.reduce(.zero) { partial, slot in
            partial + slot.claimedValue + (slot.isCompletionClaimed ? slot.completionBonus : .zero)
        }
    }
}

struct PullPlanBanner: Identifiable, Codable, Hashable {
    let id: String
    let sourceID: Int?
    let title: String
    let start: DayStamp
    let end: DayStamp
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let timeZoneIdentifier: String?
    let endTimeZoneIdentifier: String?
    let characters: [String]
    let selectionKind: PullPlanSelectionKind

    init(
        id: String,
        sourceID: Int? = nil,
        title: String,
        start: DayStamp,
        end: DayStamp,
        startHour: Int = 15,
        startMinute: Int = 0,
        endHour: Int = 13,
        endMinute: Int = 59,
        timeZoneIdentifier: String? = nil,
        endTimeZoneIdentifier: String? = "Asia/Shanghai",
        characters: [String],
        selectionKind: PullPlanSelectionKind = .none
    ) {
        self.id = id
        self.sourceID = sourceID
        self.title = title
        self.start = start
        self.end = end
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.timeZoneIdentifier = timeZoneIdentifier
        self.endTimeZoneIdentifier = endTimeZoneIdentifier
        self.characters = characters
        self.selectionKind = selectionKind
    }

    var supportsPopupSelection: Bool {
        selectionKind != .none
    }

    var usesPreciseTimeDisplay: Bool {
        timeZoneIdentifier != nil
            || startHour != Calendar.rewardCalendar.bannerRefreshHour
            || startMinute != 0
            || endHour != Calendar.rewardCalendar.bannerRefreshHour
            || endMinute != 0
    }

    func startsAt(in calendar: Calendar = .rewardCalendar) -> Date {
        var resolvedCalendar = calendar
        if let timeZoneIdentifier, let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            resolvedCalendar.timeZone = timeZone
        }

        var components = DateComponents()
        components.year = start.year
        components.month = start.month
        components.day = start.day
        components.hour = startHour
        components.minute = startMinute
        components.second = 0
        return resolvedCalendar.date(from: components) ?? start.date(in: resolvedCalendar)
    }

    func endsAt(in calendar: Calendar = .rewardCalendar) -> Date {
        var resolvedCalendar = calendar
        if let timeZoneIdentifier = endTimeZoneIdentifier ?? timeZoneIdentifier,
           let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            resolvedCalendar.timeZone = timeZone
        }

        var components = DateComponents()
        components.year = end.year
        components.month = end.month
        components.day = end.day
        components.hour = endHour
        components.minute = endMinute
        components.second = 0
        return resolvedCalendar.date(from: components) ?? end.date(in: resolvedCalendar)
    }

    func isActive(at date: Date, calendar: Calendar = .rewardCalendar) -> Bool {
        let startDate = startsAt(in: calendar)
        let endDate = endsAt(in: calendar)
        return date >= startDate && date < endDate
    }

    func isUpcoming(at date: Date, calendar: Calendar = .rewardCalendar) -> Bool {
        date < startsAt(in: calendar)
    }

    func localDisplayRange(locale: Locale = Locale.autoupdatingCurrent) -> String {
        let startDate = startsAt()
        let endDate = endsAt()

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var syncIdentity: String {
        let characterKey = characters
            .map { value in
                value.lowercased().unicodeScalars
                    .filter { CharacterSet.alphanumerics.contains($0) }
                    .map(String.init)
                    .joined()
            }
            .sorted()
            .joined(separator: ",")
        return "\(title)|\(characterKey)"
    }
}

struct SecretPassSlot: Identifiable, Hashable {
    let id: String
    let index: Int
    let baseClaimKey: String
    let premiumClaimKey: String
    let rewardValue: RewardValue?
    let label: String?
    let isPremiumOnly: Bool
    let isClaimed: Bool
    let isUnlocked: Bool
}

enum ProgressModuleKind: String, Codable, Hashable {
    case secretPass
    case miniGame
    case photoExchange
    case redemptionCode
    case mainlineSignIn
    case anniversarySignIn
}

struct ProgressModuleDefinition: Hashable {
    let kind: ProgressModuleKind
    let id: String
    let title: String
    let slotValue: RewardValue
    let slotCount: Int
    let showsCycleAdvanceButton: Bool
}

struct SecretPassProgress: Hashable {
    let id: String
    let kind: ProgressModuleKind
    let title: String
    let slotValue: RewardValue
    let cycleVersion: Int
    let slots: [SecretPassSlot]
    let remainingText: String?
    let isPremiumPurchased: Bool
    let showsCycleAdvanceButton: Bool

    var claimedCount: Int {
        slots.filter(\.isClaimed).count
    }

    var isCompleted: Bool {
        claimedCount == slots.count
    }

    var displayedClaimedCount: Int {
        claimedCount
    }

    var displayedTotalCount: Int {
        slots.count
    }
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let source: String
    let value: RewardValue
    let claimKey: String?
    let amountTextOverride: String?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        source: String,
        value: RewardValue,
        claimKey: String?,
        amountTextOverride: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.value = value
        self.claimKey = claimKey
        self.amountTextOverride = amountTextOverride
    }

    var amountText: String {
        amountTextOverride ?? value.inlineDescription(withPlusSign: true)
    }
}

extension RewardValue {
    var crystalEquivalent: Int {
        crystals + (blueTickets + redTickets) * 180
    }

    func crystalEquivalentDescription(withPlusSign: Bool) -> String {
        let value = crystalEquivalent
        let sign = withPlusSign && value >= 0 ? "+" : ""
        return "\(sign)\(value)晶"
    }

    func inlineDescription(withPlusSign: Bool) -> String {
        let crystalSign = withPlusSign && crystals >= 0 ? "+" : ""
        let blueTicketSign = withPlusSign && blueTickets >= 0 ? "+" : ""
        let redTicketSign = withPlusSign && redTickets >= 0 ? "+" : ""
        var components: [String] = []

        if crystals != 0 {
            components.append("\(crystalSign)\(crystals)晶")
        }

        if blueTickets != 0 {
            components.append("\(blueTicketSign)\(blueTickets)蓝票")
        }

        if redTickets != 0 {
            components.append("\(redTicketSign)\(redTickets)红票")
        }

        if components.isEmpty {
            return withPlusSign ? "+0" : "0"
        }

        return components.joined(separator: " · ")
    }
}

extension Calendar {
    static var rewardCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        calendar.firstWeekday = 2
        return calendar
    }

    // 固定资源按游戏日结算：每天 04:00 刷新。
    var rewardRefreshHour: Int { 4 }

    // 抽卡规划按当前记录口径使用本地 15:00 作为默认切日点。
    // 个别卡池如果提供了明确时区与时分，会在 PullPlanBanner 内覆盖。
    var bannerRefreshHour: Int { 15 }

    func rewardReferenceDate(for date: Date) -> Date {
        let refreshStart = self.date(bySettingHour: rewardRefreshHour, minute: 0, second: 0, of: date) ?? date
        if date < refreshStart {
            return self.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return date
    }

    func bannerReferenceDate(for date: Date) -> Date {
        let refreshStart = self.date(bySettingHour: bannerRefreshHour, minute: 0, second: 0, of: date) ?? date
        if date < refreshStart {
            return self.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return date
    }
}
