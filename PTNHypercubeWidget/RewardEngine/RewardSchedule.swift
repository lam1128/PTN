import Foundation

struct DataGapWindow: Identifiable, Hashable {
    let id: String
    let title: String
    let start: DayStamp
    let days: Int
    let dailyValue: RewardValue
}

struct ManualUnknownSourceDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let value: RewardValue
}

struct TimedMonthlySource: Identifiable, Hashable {
    let id: String
    let title: String
    let dayOfMonth: Int
    let visibleDays: Int
    let value: RewardValue
}

struct EventTrialTitleOverride: Hashable {
    let bannerIDs: Set<String>
    let title: String
}

enum RewardSchedule {
    static let darkZoneAnchorSeason = 31
    static let darkZoneAnchorMonday = DayStamp(year: 2026, month: 7, day: 20)
    static let darkZoneCycleWeeks = 6
    static let darkZoneWeeklyValue = RewardValue(crystals: 510)
    static let darkZoneSeasonOpeningBonus = RewardValue(crystals: 450)

    static let dailyFixedClaimSource = "每日固定"

    static let dailySources: [(id: String, title: String, value: RewardValue)] = [
        ("daily-inspection", "每日监察任务", RewardValue(crystals: 40)),
        ("daily-base", "基地监管", RewardValue(crystals: 24))
    ]

    static let weeklySources: [(id: String, title: String, value: RewardValue)] = [
        ("weekly-inspection", "周监察任务", RewardValue(crystals: 150)),
        ("weekly-share", "每周分享", RewardValue(crystals: 60))
    ]

    static let monthlySources: [(id: String, title: String, value: RewardValue)] = [
        ("shop-exchange", "商店兑换", RewardValue(blueTickets: 8, redTickets: 5))
    ]

    static let timedMonthlySources: [TimedMonthlySource] = [
        TimedMonthlySource(
            id: "emotion-day-8",
            title: "情绪检测·第8天",
            dayOfMonth: 8,
            visibleDays: 2,
            value: RewardValue(crystals: 100)
        ),
        TimedMonthlySource(
            id: "emotion-day-15",
            title: "情绪检测·第15天",
            dayOfMonth: 15,
            visibleDays: 2,
            value: RewardValue(blueTickets: 1)
        )
    ]

    static let dataGapWindows: [DataGapWindow] = [
        DataGapWindow(
            id: "season-9-upper",
            title: "数据间隙·第9赛季上半",
            start: DayStamp(year: 2026, month: 8, day: 19),
            days: 3,
            dailyValue: RewardValue(crystals: 420)
        )
    ]

    static let manualUnknownSources: [ManualUnknownSourceDefinition] = [
        ManualUnknownSourceDefinition(
            id: "emotion-random",
            title: "情绪检测·随机一天",
            value: RewardValue(blueTickets: 1)
        ),
        ManualUnknownSourceDefinition(
            id: "data-gap-future",
            title: "数据间隙·第8赛季下",
            value: RewardValue(crystals: 1260)
        )
    ]

    static let eventTrialBaseCrystalsPerBanner = 50
    static let eventTrialBonusCrystals = 10
    static let eventTrialTitleOverrides: [EventTrialTitleOverride] = [
        EventTrialTitleOverride(
            bannerIDs: ["event-celine", "event-isomer"],
            title: "主线双狂"
        )
    ]

    // 抽卡规划按 s1n.gg/banners 当前可见卡池录入。
    // 规则：
    // - 1 个橙色头像：event Arrest -> 活动池，routine Arrest -> 复刻池
    // - 2 个橙色头像：directional Arrest -> 定轨池
    // - 4 个橙色头像：collective Arrest -> 统合池
    // - 只保留橙色头像角色名，紫色角色不显示
    static let pullPlanBanners: [PullPlanBanner] = [
        PullPlanBanner(
            id: "event-celine",
            title: "活动池",
            start: DayStamp(year: 2026, month: 8, day: 7),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Celine"]
        ),
        PullPlanBanner(
            id: "event-isomer",
            title: "活动池",
            start: DayStamp(year: 2026, month: 8, day: 7),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Isomer"]
        ),
        PullPlanBanner(
            id: "collective-owo-coquelic-raven-eirene",
            title: "统合池",
            start: DayStamp(year: 2026, month: 8, day: 7),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["OwO", "Coquelic", "Raven", "Eirene"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "directional-eve-bianca",
            title: "定轨池",
            start: DayStamp(year: 2026, month: 8, day: 14),
            end: DayStamp(year: 2026, month: 9, day: 10),
            startHour: 5,
            startMinute: 0,
            endHour: 13,
            endMinute: 59,
            timeZoneIdentifier: "Asia/Shanghai",
            characters: ["Eve", "Bianca"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "routine-rust",
            title: "复刻池",
            start: DayStamp(year: 2026, month: 8, day: 20),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Rust"]
        ),
        PullPlanBanner(
            id: "routine-margaret",
            title: "复刻池",
            start: DayStamp(year: 2026, month: 8, day: 20),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Margaret"]
        ),
        PullPlanBanner(
            id: "event-chengxiao",
            title: "活动池",
            start: DayStamp(year: 2026, month: 9, day: 10),
            end: DayStamp(year: 2026, month: 10, day: 8),
            characters: ["Chengxiao"]
        ),
        PullPlanBanner(
            id: "directional-parfait-korryn",
            title: "定轨池",
            start: DayStamp(year: 2026, month: 9, day: 17),
            end: DayStamp(year: 2026, month: 10, day: 8),
            characters: ["Parfait", "Korryn"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "routine-lichen",
            title: "复刻池",
            start: DayStamp(year: 2026, month: 9, day: 24),
            end: DayStamp(year: 2026, month: 10, day: 8),
            characters: ["Lichen"]
        ),
        PullPlanBanner(
            id: "event-phanuel",
            title: "活动池",
            start: DayStamp(year: 2026, month: 10, day: 8),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["Phanuel"]
        ),
        PullPlanBanner(
            id: "collective-owo-bianca-angell-cabernet",
            title: "统合池",
            start: DayStamp(year: 2026, month: 10, day: 8),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["OwO", "Bianca", "Angell", "Cabernet"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "directional-moore-lady-pearl",
            title: "定轨池",
            start: DayStamp(year: 2026, month: 10, day: 15),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["Moore", "Lady Pearl"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "routine-xiaofeng",
            title: "复刻池",
            start: DayStamp(year: 2026, month: 10, day: 22),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["Xiaofeng"]
        ),
        PullPlanBanner(
            id: "event-requiem",
            title: "限定池",
            start: DayStamp(year: 2026, month: 11, day: 5),
            end: DayStamp(year: 2026, month: 12, day: 3),
            characters: ["Requiem"],
            selectionKind: .lockCount
        ),
        PullPlanBanner(
            id: "event-famorene-eirene",
            title: "活动池",
            start: DayStamp(year: 2026, month: 11, day: 5),
            end: DayStamp(year: 2026, month: 12, day: 3),
            characters: ["Famorene Eirene"]
        )
    ]

    // 抽卡规划的“垫抽数”按实际卡池体系共用：
    // - 活动池 / 复刻池：共用同一套垫抽
    // - 定轨池：共用同一套垫抽
    // - 统合池：共用同一套垫抽
    // - 限定池：共用同一套垫抽
    // 这样同期开启或前后连续的同体系卡池都会自动同步。
    static let pullPlanPityKeyByBannerID: [String: String] = {
        var result: [String: String] = [:]
        for banner in pullPlanBanners {
            result[banner.id] = pullPlanPityGroupKey(for: banner)
        }
        return result
    }()

    static func pullPlanPityKey(for bannerID: String) -> String {
        pullPlanPityKeyByBannerID[bannerID] ?? "pull-plan-pity-\(bannerID)"
    }

    static func pullPlanPityGroupKey(for banner: PullPlanBanner) -> String {
        switch banner.title {
        case "活动池", "复刻池":
            return "pull-plan-pity-single-arrest"
        case "定轨池":
            return "pull-plan-pity-directional-arrest"
        case "统合池":
            return "pull-plan-pity-collective-arrest"
        case "限定池":
            return "pull-plan-pity-limited-arrest"
        default:
            return "pull-plan-pity-\(banner.id)"
        }
    }

    static let secretPassID = "secret-society-pass"
    static let secretPassTitle = "监察密令·渡鸦"
    static let secretPassSlotValue = RewardValue(blueTickets: 1)
    static let secretPassTotalSlots = 6
    static let secretPassRemainingText = "31天16小时"

    static let miniGameID = "event-mini-game"
    static let miniGameTitle = "活动·小游戏"
    static let miniGameSlotValue = RewardValue(crystals: 50)
    static let miniGameTotalSlots = 5
    static let miniGameRemainingText: String? = nil

    static let referenceNote = "2026-08-13 为暗域第31期第4周，且该周奖励已领取。"

    static func eventTrialTitle(for banners: [PullPlanBanner]) -> String {
        let bannerIDSet = Set(banners.map(\.id))

        if let override = eventTrialTitleOverrides.first(where: { $0.bannerIDs == bannerIDSet }) {
            return override.title
        }

        if banners.count == 1, let character = banners.first?.characters.first {
            return character
        }

        let mergedNames = banners
            .flatMap(\.characters)
            .joined(separator: " / ")

        return mergedNames.isEmpty ? "活动池" : mergedNames
    }

    static func eventTrialValue(for banners: [PullPlanBanner]) -> RewardValue {
        RewardValue(
            crystals: banners.count * eventTrialBaseCrystalsPerBanner + eventTrialBonusCrystals
        )
    }
}
