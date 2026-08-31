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
    let showsCycleAdvanceButton: Bool
    let resetsDaily: Bool
    let rowCapacity: Int?

    init(
        id: String,
        title: String,
        slots: [DailyProgressSlotDefinition],
        display: DailyProgressDisplay,
        showsCycleAdvanceButton: Bool = false,
        resetsDaily: Bool = true,
        rowCapacity: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.slots = slots
        self.display = display
        self.showsCycleAdvanceButton = showsCycleAdvanceButton
        self.resetsDaily = resetsDaily
        self.rowCapacity = rowCapacity
    }
}

enum RewardSchedule {
    // 暗域锚点：
    // 2026-08-10 是第 31 期第 1 周的周一，之后严格按 6 周一赛季循环。
    static let darkZoneAnchorSeason = 31
    static let darkZoneAnchorMonday = DayStamp(year: 2026, month: 8, day: 10)
    static let darkZoneCycleWeeks = 6
    static let darkZoneWeeklyValue = RewardValue(crystals: 510)
    static let darkZoneSeasonOpeningBonus = RewardValue(crystals: 450)

    static let dailyFixedClaimSource = "每日监察任务"
    static let historySourceAliases = [
        "每日固定": dailyFixedClaimSource,
        "派遣 第1项": "派遣·5异方晶",
        "派遣 第2项": "派遣·15异方晶",
        // Keep the legacy history label accurate; new records use the configured 40 value.
        "派遣 第3项": "派遣·25异方晶",
        "服从度 第1项": "服从度·获得狂级禁闭者",
        "服从度 第2项": "服从度·狂级禁闭者40%",
        "服从度 第3项": "服从度·获得危级禁闭者",
        "服从度 第4项": "服从度·危级禁闭者40%",
        "服从度 第5项": "服从度·获得普级禁闭者",
        "服从度 第6项": "服从度·普级禁闭者40%"
    ]

    static func migratedHistorySource(_ source: String, claimKey: String?) -> String {
        if let claimKey, claimKey.hasPrefix("daily-obedience-") {
            let obedienceSources = [
                "-orange-0-": "服从度·获得狂级禁闭者",
                "-orange-40-": "服从度·狂级禁闭者40%",
                "-purple-0-": "服从度·获得危级禁闭者",
                "-purple-40-": "服从度·危级禁闭者40%",
                "-blue-0-": "服从度·获得普级禁闭者",
                "-blue-40-": "服从度·普级禁闭者40%"
            ]
            if let migrated = obedienceSources.first(where: { claimKey.contains($0.key) })?.value {
                return migrated
            }
        }

        if let claimKey,
           claimKey.hasPrefix("daily-review-"),
           !claimKey.hasSuffix("-completion"),
           let stage = claimKey.split(separator: "-").last.flatMap({ Int($0) }),
           (1...4).contains(stage) {
            let grade = claimKey.contains("-orange") ? "狂级" : "危级"
            return "审查·\(grade)禁闭者\(["第一", "第二", "第三", "第四"][stage - 1])阶段"
        }

        if let alias = historySourceAliases[source] {
            return alias
        }
        return source
    }

    static let dailyExtraSources: [RewardSourceDefinition] = [
        RewardSourceDefinition(
            id: "daily-emotion-detection",
            title: "情绪检测",
            value: RewardValue(crystals: 20)
        ),
        RewardSourceDefinition(
            id: "regulatory-event",
            title: "监管事件",
            value: RewardValue(crystals: 20)
        )
    ]
    static let activityPoolTitle = "活动池"
    static let pullPlanRecordPoolTitles = [
        activityPoolTitle,
        "复刻池",
        "统合池",
        "定轨池",
        "限定池"
    ]
    static let dailyDispatchID = "daily-dispatch"
    static let dailyReviewID = "daily-review"
    static let dataGapProgressID = "data-gap-current"
    static let emotionRandomSourceID = "emotion-random"
    static let dataGapManualSourceID = "data-gap-future"
    static let bugFixRewardID = "bug-fix"
    static let updateMaintenanceRewardID = "update-maintenance"
    static let randomQuestionnaireRewardID = "questionnaire-random"
    static let maintenanceRewardID = "maintenance-compensation"
    static let questionnaireRewardID = "new-version-questionnaire"
    static let permanentManualSourceOrder = [
        updateMaintenanceRewardID,
        bugFixRewardID,
        randomQuestionnaireRewardID
    ]

    static let dailyProgressDefinitions: [DailyProgressDefinition] = [
        DailyProgressDefinition(
            id: dailyDispatchID,
            title: "派遣",
            slots: [15, 20, 40].enumerated().map { index, value in
                DailyProgressSlotDefinition(
                    id: "dispatch-\(index + 1)",
                    value: RewardValue(crystals: value),
                    historySources: ["派遣·\(value)异方晶"],
                    maxCount: 1,
                    tint: .neutral,
                    completionBonus: .zero
                )
            },
            display: .value,
            showsCycleAdvanceButton: true,
            resetsDaily: false
        ),
        DailyProgressDefinition(
            id: dailyReviewID,
            title: "审查",
            slots: [
                DailyProgressSlotDefinition(
                    id: "orange",
                    value: RewardValue(crystals: 80),
                    rewardValues: [
                        RewardValue(crystals: 80),
                        RewardValue(crystals: 80),
                        RewardValue(crystals: 50),
                        RewardValue(crystals: 80)
                    ],
                    historySources: [
                        "审查·狂级禁闭者第一阶段",
                        "审查·狂级禁闭者第二阶段",
                        "审查·狂级禁闭者第三阶段",
                        "审查·狂级禁闭者第四阶段"
                    ],
                    maxCount: 4,
                    tint: .orange,
                    completionBonus: .zero
                ),
                DailyProgressSlotDefinition(
                    id: "purple",
                    value: RewardValue(crystals: 60),
                    rewardValues: [
                        RewardValue(crystals: 60),
                        RewardValue(crystals: 50),
                        RewardValue(crystals: 60)
                    ],
                    historySources: [
                        "审查·危级禁闭者第一阶段",
                        "审查·危级禁闭者第二阶段",
                        "审查·危级禁闭者第三阶段"
                    ],
                    maxCount: 3,
                    tint: .purple,
                    completionBonus: .zero
                )
            ],
            display: .count,
            showsCycleAdvanceButton: true,
            resetsDaily: false
        ),
        DailyProgressDefinition(
            id: "daily-obedience",
            title: "服从度",
            slots: [
                DailyProgressSlotDefinition(
                    id: "orange-0",
                    value: RewardValue(crystals: 60),
                    labels: ["0"],
                    historySources: ["服从度·获得狂级禁闭者"],
                    maxCount: 1,
                    tint: .orange,
                    completionBonus: .zero
                ),
                DailyProgressSlotDefinition(
                    id: "orange-40",
                    value: RewardValue(crystals: 30),
                    labels: ["40"],
                    historySources: ["服从度·狂级禁闭者40%"],
                    maxCount: 1,
                    tint: .orange,
                    completionBonus: .zero
                ),
                DailyProgressSlotDefinition(
                    id: "purple-0",
                    value: RewardValue(crystals: 20),
                    labels: ["0"],
                    historySources: ["服从度·获得危级禁闭者"],
                    maxCount: 1,
                    tint: .purple,
                    completionBonus: .zero
                ),
                DailyProgressSlotDefinition(
                    id: "purple-40",
                    value: RewardValue(crystals: 10),
                    labels: ["40"],
                    historySources: ["服从度·危级禁闭者40%"],
                    maxCount: 1,
                    tint: .purple,
                    completionBonus: .zero
                ),
                DailyProgressSlotDefinition(
                    id: "blue-0",
                    value: RewardValue(crystals: 10),
                    labels: ["0"],
                    historySources: ["服从度·获得普级禁闭者"],
                    maxCount: 1,
                    tint: .blue,
                    completionBonus: .zero
                ),
                DailyProgressSlotDefinition(
                    id: "blue-40",
                    value: RewardValue(crystals: 5),
                    labels: ["40"],
                    historySources: ["服从度·普级禁闭者40%"],
                    maxCount: 1,
                    tint: .blue,
                    completionBonus: .zero
                )
            ],
            display: .value,
            showsCycleAdvanceButton: true,
            resetsDaily: false
        )
    ]

    static let dailySources: [RewardSourceDefinition] = [
        RewardSourceDefinition(id: "daily-inspection", title: "每日监察任务", value: RewardValue(crystals: 40))
    ]

    static let automaticStorageTitle = "基地监管"
    static let automaticStorageBatchValue = RewardValue(crystals: 4)
    static let automaticStorageInterval: TimeInterval = 3 * 60 * 60 + 50 * 60 + 24
    static let automaticStorageCapacity = 48
    // Calibration: at 2026-08-18 00:02 (Europe/Berlin), the warehouse was 0/48.
    static let automaticStorageReferenceStart: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: 23,
            minute: 50,
            second: 12
        ))!
    }()
    static let automaticStorageHistoryKey = "automatic-storage"

    static let weeklySources: [RewardSourceDefinition] = [
        RewardSourceDefinition(id: "weekly-share", title: "每周分享", value: RewardValue(crystals: 60))
    ]

    static let weeklyInspectionProgressDefinition = DailyProgressDefinition(
        id: "weekly-inspection-progress",
        title: "周监察任务",
        slots: [20, 20, 20, 40, 50].enumerated().map { index, value in
            DailyProgressSlotDefinition(
                id: "weekly-inspection-\(index + 1)",
                value: RewardValue(crystals: value),
                historySources: ["周监察任务·第\(index + 1)项"],
                maxCount: 1,
                tint: .neutral,
                completionBonus: .zero
            )
        },
        display: .value
    )

    static let activityRerunDefinition = DailyProgressDefinition(
        id: "activity-rerun",
        title: "活动·复刻",
        slots: [
            DailyProgressSlotDefinition(
                id: "crystals",
                value: RewardValue(crystals: 600),
                labels: ["600"],
                historySources: ["活动·复刻·600异方晶"],
                maxCount: 1,
                tint: .neutral,
                completionBonus: .zero,
                shape: .capsule
            ),
            DailyProgressSlotDefinition(
                id: "blue-ticket",
                value: RewardValue(blueTickets: 1),
                labels: ["1"],
                historySources: ["活动·复刻·1蓝票"],
                maxCount: 1,
                tint: .neutral,
                completionBonus: .zero,
                showsCheckmark: true,
                shape: .circle
            ),
            DailyProgressSlotDefinition(
                id: "blue-ticket-2",
                value: RewardValue(blueTickets: 1),
                historySources: ["活动·复刻·1蓝票"],
                maxCount: 1,
                tint: .neutral,
                completionBonus: .zero,
                showsCheckmark: true,
                shape: .circle
            ),
            DailyProgressSlotDefinition(
                id: "blue-ticket-3",
                value: RewardValue(blueTickets: 1),
                historySources: ["活动·复刻·1蓝票"],
                maxCount: 1,
                tint: .neutral,
                completionBonus: .zero,
                showsCheckmark: true,
                shape: .circle
            )
        ],
        display: .value,
        showsCycleAdvanceButton: false,
        resetsDaily: false
    )

    static let permanentProgressDefinitions: [DailyProgressDefinition] = [
        makePermanentProgressDefinition(
            id: "n9",
            title: "N9",
            values: Array(repeating: 70, count: 8) + Array(repeating: 35, count: 3) + Array(repeating: 20, count: 3),
            labels: Array((1...8).map { Optional(String($0)) })
                + Array(repeating: Optional("Re"), count: 3)
                + Array(repeating: Optional("K"), count: 3),
            sequentialUnlock: true,
            rowCapacity: 7
        ),
        makePermanentProgressDefinition(
            id: "n10",
            title: "N10",
            values: Array(repeating: 70, count: 8) + Array(repeating: 35, count: 3) + Array(repeating: 20, count: 3),
            labels: Array((1...8).map { Optional(String($0)) })
                + Array(repeating: Optional("Re"), count: 3)
                + Array(repeating: Optional("K"), count: 3),
            sequentialUnlock: true,
            rowCapacity: 7
        ),
        makePermanentProgressDefinition(
            id: "core-crisis-n9-n10",
            title: "核心危机·N9N10",
            values: [50, 50, 0, 50, 50, 0],
            labels: ["2", "5", "8", "3", "6", "9"],
            blueTicketIndices: [2, 5],
            rowCapacity: 6
        )
    ]

    private static func makePermanentProgressDefinition(
        id: String,
        title: String,
        values: [Int],
        labels: [String?],
        showsCheckmark: [Bool] = [],
        blueTicketIndices: Set<Int> = [],
        sequentialUnlock: Bool = false,
        rowCapacity: Int
    ) -> DailyProgressDefinition {
        DailyProgressDefinition(
            id: id,
            title: title,
            slots: values.indices.map { index in
                let value = blueTicketIndices.contains(index)
                    ? RewardValue(blueTickets: 1)
                    : RewardValue(crystals: values[index])
                return DailyProgressSlotDefinition(
                    id: "\(id)-\(index + 1)",
                    value: value,
                    labels: labels[index].map { [$0] } ?? [],
                    historySources: [historySource(
                        id: id,
                        title: title,
                        index: index,
                        label: labels[index]
                    )],
                    maxCount: 1,
                    tint: .neutral,
                    completionBonus: .zero,
                    showsCheckmark: showsCheckmark.indices.contains(index) && showsCheckmark[index],
                    unlockedBySlotIndex: sequentialUnlock && index > 0 && index < 8
                        ? index
                        : labels[index] == "K" ? index - 5 : nil
                )
            },
            display: .value,
            rowCapacity: rowCapacity
        )
    }

    private static func historySource(
        id: String,
        title: String,
        index: Int,
        label: String?
    ) -> String {
        if id == "n9" || id == "n10" {
            if index < 8 {
                return "\(title)·第\(index + 1)关"
            }
            if index < 11 {
                return "\(title)·困难\(index - 7)"
            }
            return "\(title)·Re\(index - 10)"
        }

        if id == "core-crisis-n9-n10", let label {
            let denominator = ["2", "5", "8"].contains(label) ? 8 : 9
            return "\(title)·\(label)/\(denominator)"
        }

        return "\(title)·\(label ?? "第\(index + 1)项")"
    }

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
    static let dataGapWindows: [DataGapWindow] = []

    static let dataGapCurrentStart = DayStamp(year: 2026, month: 8, day: 18)
    static let dataGapCurrentStartHour = 15
    static let dataGapCurrentUnlockHour = 5
    static let dataGapProgressDefinition = DailyProgressDefinition(
        id: dataGapProgressID,
        title: "数据间隙·第9赛季上半",
        slots: [150, 340, 160, 340, 110, 340].enumerated().map { index, value in
            DailyProgressSlotDefinition(
                id: "data-gap-\(index + 1)",
                value: RewardValue(crystals: value),
                labels: [String(value)],
                historySources: ["数据间隙·第9赛季上半 第\(index + 1)项"],
                maxCount: 1,
                tint: .neutral,
                completionBonus: .zero,
                shape: index.isMultiple(of: 2) ? .circle : .capsule
            )
        },
        display: .value,
        rowCapacity: 6
    )

    // 这些来源奖励总量已知，但用户要求保留为手动领取，不自动推日期。
    static let manualUnknownSources: [ManualUnknownSourceDefinition] = [
        ManualUnknownSourceDefinition(
            id: updateMaintenanceRewardID,
            title: "更新维护",
            value: RewardValue(crystals: 200)
        ),
        ManualUnknownSourceDefinition(
            id: emotionRandomSourceID,
            title: "情绪检测·随机一天",
            value: RewardValue(blueTickets: 1),
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
    private static let bundledPullPlanBanners: [PullPlanBanner] = [
        PullPlanBanner(
            id: "event-celine",
            sourceID: 338,
            title: activityPoolTitle,
            start: DayStamp(year: 2026, month: 8, day: 7),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Celine"]
        ),
        PullPlanBanner(
            id: "event-isomer",
            sourceID: 337,
            title: activityPoolTitle,
            start: DayStamp(year: 2026, month: 8, day: 7),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Isomer"]
        ),
        PullPlanBanner(
            id: "collective-owo-coquelic-raven-eirene",
            sourceID: 343,
            title: "统合池",
            start: DayStamp(year: 2026, month: 8, day: 7),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["OwO", "Coquelic", "Raven", "Eirene"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "directional-eve-bianca",
            sourceID: 344,
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
            sourceID: 342,
            title: "复刻池",
            start: DayStamp(year: 2026, month: 8, day: 27),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Rust"]
        ),
        PullPlanBanner(
            id: "routine-margaret",
            sourceID: 341,
            title: "复刻池",
            start: DayStamp(year: 2026, month: 8, day: 27),
            end: DayStamp(year: 2026, month: 9, day: 10),
            characters: ["Margaret"]
        ),
        PullPlanBanner(
            id: "event-chengxiao",
            sourceID: 339,
            title: activityPoolTitle,
            start: DayStamp(year: 2026, month: 9, day: 10),
            end: DayStamp(year: 2026, month: 10, day: 8),
            characters: ["Chengxiao"]
        ),
        PullPlanBanner(
            id: "directional-parfait-korryn",
            sourceID: 348,
            title: "定轨池",
            start: DayStamp(year: 2026, month: 9, day: 17),
            end: DayStamp(year: 2026, month: 10, day: 8),
            characters: ["Parfait", "Korryn"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "routine-lichen",
            sourceID: 349,
            title: "复刻池",
            start: DayStamp(year: 2026, month: 9, day: 24),
            end: DayStamp(year: 2026, month: 10, day: 8),
            characters: ["Lichen"]
        ),
        PullPlanBanner(
            id: "event-phanuel",
            sourceID: 353,
            title: activityPoolTitle,
            start: DayStamp(year: 2026, month: 10, day: 8),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["Phanuel"]
        ),
        PullPlanBanner(
            id: "collective-owo-bianca-angell-cabernet",
            sourceID: 354,
            title: "统合池",
            start: DayStamp(year: 2026, month: 10, day: 8),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["OwO", "Bianca", "Angell", "Cabernet"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "directional-moore-lady-pearl",
            sourceID: 356,
            title: "定轨池",
            start: DayStamp(year: 2026, month: 10, day: 15),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["Moore", "Lady Pearl"],
            selectionKind: .targetChoice
        ),
        PullPlanBanner(
            id: "routine-xiaofeng",
            sourceID: 357,
            title: "复刻池",
            start: DayStamp(year: 2026, month: 10, day: 22),
            end: DayStamp(year: 2026, month: 11, day: 5),
            characters: ["Xiaofeng"]
        ),
        PullPlanBanner(
            id: "event-requiem",
            sourceID: 368,
            title: "限定池",
            start: DayStamp(year: 2026, month: 11, day: 5),
            end: DayStamp(year: 2026, month: 12, day: 3),
            characters: ["Requiem"],
            selectionKind: .lockCount
        ),
        PullPlanBanner(
            id: "event-famorene-eirene",
            sourceID: 369,
            title: activityPoolTitle,
            start: DayStamp(year: 2026, month: 11, day: 5),
            end: DayStamp(year: 2026, month: 12, day: 3),
            characters: ["Famorene Eirene"]
        )
    ]

    static var pullPlanBanners: [PullPlanBanner] {
        let overrides = Dictionary(
            uniqueKeysWithValues: PullPlanDateOverrideCache.load().map { ($0.sourceID, $0) }
        )
        let bundledBanners = bundledPullPlanBanners.map { banner in
            guard let sourceID = banner.sourceID, let override = overrides[sourceID] else {
                return banner
            }
            return banner.applyingDateOverride(override)
        }
        let bundledIdentities = Set(bundledBanners.map(\.syncIdentity))
        let bundledIDs = Set(bundledBanners.map(\.id))
        let bundledSourceIDs = Set(bundledBanners.compactMap(\.sourceID))
        let appendedBanners = PullPlanBannerCache.load().filter {
            !bundledIDs.contains($0.id)
                && !bundledSourceIDs.contains($0.sourceID ?? -1)
                && !bundledIdentities.contains($0.syncIdentity)
        }
        return bundledBanners + appendedBanners
    }

    static func currentPermanentRewardAnchor(
        at date: Date,
        calendar: Calendar = .rewardCalendar
    ) -> PullPlanBanner? {
        pullPlanBanners
            .filter { banner in
                (banner.title == activityPoolTitle || banner.title == "限定池")
                    && banner.isActive(at: date, calendar: calendar)
            }
            .max { lhs, rhs in
                let lhsStart = lhs.startsAt(in: calendar)
                let rhsStart = rhs.startsAt(in: calendar)
                if lhsStart != rhsStart { return lhsStart < rhsStart }
                return lhs.id < rhs.id
            }
    }

    // 同一开始日期的复刻池共用一个奖励周期，下一组复刻池开始时自动换周期。
    static func activityRerunCycleKey(
        at date: Date,
        calendar: Calendar = .rewardCalendar
    ) -> String {
        activityRerunCycleBanners(at: date, calendar: calendar).first?.start.key
            ?? "activity-rerun"
    }

    // 同期开启的复刻池（例如 Rust 与 Margaret）共享同一组开始和结束时间。
    static func currentActivityRerunWindow(
        at date: Date,
        calendar: Calendar = .rewardCalendar
    ) -> (start: Date, end: Date)? {
        let banners = activityRerunCycleBanners(at: date, calendar: calendar)
        guard let first = banners.first,
              let end = banners.map({ $0.endsAt(in: calendar) }).max() else {
            return nil
        }
        return (first.startsAt(in: calendar), end)
    }

    private static func activityRerunCycleBanners(
        at date: Date,
        calendar: Calendar
    ) -> [PullPlanBanner] {
        let rerunBanners = pullPlanBanners.filter { $0.title == "复刻池" }
        guard let start = rerunBanners
            .map({ $0.startsAt(in: calendar) })
            .filter({ $0 <= date })
            .max() else {
            return []
        }
        return rerunBanners.filter { $0.startsAt(in: calendar) == start }
    }

    // 抽卡规划的“垫抽数”按池子规则分别保存：
    // - 活动池、复刻池：各自独立计算
    // - 定轨池：共用同一套垫抽
    // - 统合池：共用同一套垫抽
    // - 限定池：共用同一套垫抽
    // 这样同期开启或前后连续的同体系卡池都会自动同步。
    static func pullPlanPityKey(for bannerID: String) -> String {
        guard let banner = pullPlanBanners.first(where: { $0.id == bannerID }) else {
            return "pull-plan-pity-\(bannerID)"
        }
        return pullPlanPityGroupKey(for: banner)
    }

    static func pullPlanPityGroupKey(for banner: PullPlanBanner) -> String {
        switch banner.title {
        case "活动池":
            return "pull-plan-pity-event-arrest"
        case "复刻池":
            return "pull-plan-pity-routine-arrest"
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
    static let secretPassPremiumThirdBonus = RewardValue(crystals: 200)
    static let secretPassPremiumSecondLastBonus = RewardValue(crystals: 680)
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

    static let photoExchangeDefinition = ProgressModuleDefinition(
        kind: .photoExchange,
        id: "photo-exchange",
        title: "留影兑换",
        slotValue: RewardValue(crystals: -150),
        slotCount: 3,
        showsCycleAdvanceButton: true
    )

    static let mainlineSignInDefinition = ProgressModuleDefinition(
        kind: .mainlineSignIn,
        id: "mainline-sign-in",
        title: "主线签到·主线双狂",
        slotValue: RewardValue(crystals: 60),
        slotCount: 3,
        showsCycleAdvanceButton: false
    )
    static let mainlineSignInUnlockDays = [9, 11, 13]

    static let anniversarySignInDefinition = ProgressModuleDefinition(
        kind: .anniversarySignIn,
        id: "anniversary-sign-in",
        title: "周年庆签到·周年庆",
        slotValue: RewardValue(crystals: 60),
        slotCount: 3,
        showsCycleAdvanceButton: false
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
