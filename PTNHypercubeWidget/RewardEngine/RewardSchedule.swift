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
    let showsAdvanceCycleButton: Bool

    init(
        id: String,
        title: String,
        value: RewardValue,
        showsAdvanceCycleButton: Bool = true
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.showsAdvanceCycleButton = showsAdvanceCycleButton
    }
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

struct DailyProgressDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let slots: [DailyProgressSlotDefinition]
    let display: DailyProgressDisplay
}

enum RewardSchedule {
    // 暗域锚点：
    // 2026-07-20 是第 31 期第 1 周的周一，之后严格按 6 周一赛季循环。
    static let darkZoneAnchorSeason = 31
    static let darkZoneAnchorMonday = DayStamp(year: 2026, month: 7, day: 20)
    static let darkZoneCycleWeeks = 6
    static let darkZoneWeeklyValue = RewardValue(crystals: 510)
    static let darkZoneSeasonOpeningBonus = RewardValue(crystals: 450)

    static let dailyFixedClaimSource = "每日固定"

    static let regulatoryEventTitle = "监管事件"
    static let regulatoryEventValue = RewardValue(crystals: 20)
    static let activityPoolTitle = "活动池"
    static let dailyDispatchID = "daily-dispatch"
    static let dailyReviewID = "daily-review"
    static let emotionRandomSourceID = "emotion-random"
    static let dataGapManualSourceID = "data-gap-future"
    static let bugFixRewardID = "bug-fix"
    static let randomQuestionnaireRewardID = "questionnaire-random"
    static let maintenanceRewardID = "maintenance-compensation"
    static let questionnaireRewardID = "new-version-questionnaire"
    static let permanentManualSourceOrder = [
        bugFixRewardID,
        randomQuestionnaireRewardID
    ]

    static let dailyProgressDefinitions: [DailyProgressDefinition] = [
        DailyProgressDefinition(
            id: dailyDispatchID,
            title: "派遣",
            slots: [5, 15, 25].enumerated().map { index, value in
                DailyProgressSlotDefinition(
                    id: "dispatch-\(index + 1)",
                    value: RewardValue(crystals: value),
                    maxCount: 1,
                    tint: .neutral,
                    completionBonus: .zero
                )
            },
            display: .value
        ),
        DailyProgressDefinition(
            id: dailyReviewID,
            title: "审查",
            slots: [
                DailyProgressSlotDefinition(
                    id: "orange",
                    value: RewardValue(crystals: 50),
                    maxCount: 4,
                    tint: .orange,
                    completionBonus: RewardValue(crystals: 90)
                ),
                DailyProgressSlotDefinition(
                    id: "purple",
                    value: RewardValue(crystals: 50),
                    maxCount: 3,
                    tint: .purple,
                    completionBonus: RewardValue(crystals: 10)
                )
            ],
            display: .count
        )
    ]

    static let dailySources: [RewardSourceDefinition] = [
        RewardSourceDefinition(id: "daily-inspection", title: "每日监察任务", value: RewardValue(crystals: 40)),
        RewardSourceDefinition(id: "daily-base", title: "基地监管", value: RewardValue(crystals: 24))
    ]

    static let weeklySources: [RewardSourceDefinition] = [
        RewardSourceDefinition(id: "weekly-inspection", title: "周监察任务", value: RewardValue(crystals: 150)),
        RewardSourceDefinition(id: "weekly-share", title: "每周分享", value: RewardValue(crystals: 60))
    ]

    static let monthlySources: [RewardSourceDefinition] = [
        RewardSourceDefinition(id: "shop-exchange", title: "商店兑换", value: RewardValue(blueTickets: 8, redTickets: 5))
    ]

    // visibleDays = 2 表示只显示当天和次日，第三天自动消失。
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

    // 数据间隙只录入已知窗口；未知后续档期不做自动推算。
    static let dataGapWindows: [DataGapWindow] = [
        DataGapWindow(
            id: "season-9-upper",
            title: "数据间隙·第9赛季上半",
            start: DayStamp(year: 2026, month: 8, day: 19),
            days: 3,
            dailyValue: RewardValue(crystals: 420)
        )
    ]

    // 这些来源奖励总量已知，但用户要求保留为手动领取，不自动推日期。
    static let manualUnknownSources: [ManualUnknownSourceDefinition] = [
        ManualUnknownSourceDefinition(
            id: emotionRandomSourceID,
            title: "情绪检测·随机一天",
            value: RewardValue(blueTickets: 1),
            showsAdvanceCycleButton: false
        ),
        ManualUnknownSourceDefinition(
            id: dataGapManualSourceID,
            title: "数据间隙·第8赛季下",
            value: RewardValue(crystals: 1260),
            showsAdvanceCycleButton: false
        ),
        ManualUnknownSourceDefinition(
            id: bugFixRewardID,
            title: "问题修复",
            value: RewardValue(crystals: 180)
        ),
        ManualUnknownSourceDefinition(
            id: randomQuestionnaireRewardID,
            title: "问卷调查·随机",
            value: RewardValue(crystals: 180)
        )
    ]

    // 活动试用规则：每个活动池 50 晶，额外固定 +10 晶。
    static let eventTrialBaseCrystalsPerBanner = 50
    static let eventTrialBonusCrystals = 10
    static let eventTrialTitleOverrides: [EventTrialTitleOverride] = [
        EventTrialTitleOverride(
            bannerIDs: ["event-celine", "event-isomer"],
            title: "主线双狂"
        )
    ]

    // 常驻奖励跟随当前活动池更新；时间关系集中配置，避免写死具体日期。
    static let permanentRewardDefinitions: [PermanentRewardDefinition] = [
        PermanentRewardDefinition(
            id: maintenanceRewardID,
            title: "停服维护",
            value: RewardValue(crystals: 200),
            sortOrder: 100,
            timing: .maintenance
        ),
        PermanentRewardDefinition(
            id: questionnaireRewardID,
            title: "问卷调查",
            value: RewardValue(crystals: 180),
            sortOrder: 110,
            timing: .questionnaire
        ),
    ]
    static let questionnaireStartOffsetDays = 7
    static let questionnaireStartHour = 12
    static let questionnaireStartMinute = 0
    static let questionnaireEndOffsetDays = 13
    static let questionnaireEndHour = 11
    static let questionnaireEndMinute = 59
    static let maintenanceStartOffsetHours = 5
    static let maintenanceWindowDays = 7

    // 抽卡规划按 s1n.gg/banners 当前可见卡池录入。
    // 规则：
    // - 1 个橙色头像：event Arrest -> 活动池，routine Arrest -> 复刻池
    // - 2 个橙色头像：directional Arrest -> 定轨池
    // - 4 个橙色头像：collective Arrest -> 统合池
    // - 只保留橙色头像角色名，紫色角色不显示
    static let pullPlanBanners: [PullPlanBanner] = [
        PullPlanBanner(
            id: "event-celine",
            title: activityPoolTitle,
            start: DayStamp(year: 2026, month: 8, day: 7),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Celine"]
        ),
        PullPlanBanner(
            id: "event-isomer",
            title: activityPoolTitle,
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
            endTimeZoneIdentifier: "Asia/Shanghai",
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
            title: activityPoolTitle,
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
            title: activityPoolTitle,
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
            title: activityPoolTitle,
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

    static let secretPassDefinition = ProgressModuleDefinition(
        kind: .secretPass,
        id: "secret-society-pass",
        title: "监察密令·渡鸦",
        slotValue: RewardValue(blueTickets: 1),
        slotCount: 6,
        showsCycleAdvanceButton: false
    )
    static let secretPassSeasonEnd = DayStamp(year: 2026, month: 9, day: 14)
    static let secretPassSeasonEndHour = 4
    static let secretPassSeasonEndMinute = 59
    static let secretPassSeasonTimeZoneIdentifier = "Asia/Shanghai"

    static let miniGameDefinition = ProgressModuleDefinition(
        kind: .miniGame,
        id: "event-mini-game",
        title: "活动·小游戏",
        slotValue: RewardValue(crystals: 50),
        slotCount: 5,
        showsCycleAdvanceButton: true
    )

    static let redemptionCodeDefinition = ProgressModuleDefinition(
        kind: .redemptionCode,
        id: "redemption-code",
        title: "兑换码",
        slotValue: RewardValue(crystals: 200),
        slotCount: 0,
        showsCycleAdvanceButton: false
    )
    static let redemptionCodeStartHour = 8
    static let redemptionCodeStartMinute = 0
    // 2026-08-07 08:00 Europe/Berlin -> 2026-08-26 15:59 UTC+0。
    static let redemptionCodeDuration: TimeInterval =
        (19 * 24 * 60 * 60) + (9 * 60 * 60) + (59 * 60)

    static let dataGapCurrentSeasonEnd = DayStamp(year: 2026, month: 8, day: 18)
    static let dataGapCurrentSeasonEndHour = 4
    static let dataGapCurrentSeasonEndMinute = 0

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
