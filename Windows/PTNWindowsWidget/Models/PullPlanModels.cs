namespace PTNWindowsWidget.Models;

public enum PullPlanSelectionKind
{
    None,
    TargetChoice,
    LockCount
}

public enum PullPlanProgress
{
    None,
    Planned,
    Completed
}

public sealed record PullPlanBanner(
    string Id,
    string Title,
    DateTime Start,
    DateTime End,
    IReadOnlyList<string> Characters,
    PullPlanSelectionKind SelectionKind = PullPlanSelectionKind.None,
    int StartHour = 15,
    int StartMinute = 0,
    int EndHour = 13,
    int EndMinute = 59,
    string? TimeZoneId = null,
    string? EndTimeZoneId = "China Standard Time"
)
{
    public bool SupportsSelection => SelectionKind != PullPlanSelectionKind.None;
}

public static class PullPlanSchedule
{
    public static readonly IReadOnlyList<PullPlanBanner> Banners =
    [
        new("event-celine", "活动池", new(2026, 8, 7), new(2026, 9, 10), ["Celine"]),
        new("event-isomer", "活动池", new(2026, 8, 7), new(2026, 9, 10), ["Isomer"]),
        new("collective-owo-coquelic-raven-eirene", "统合池", new(2026, 8, 7), new(2026, 9, 10), ["OwO", "Coquelic", "Raven", "Eirene"], PullPlanSelectionKind.TargetChoice),
        new("directional-eve-bianca", "定轨池", new(2026, 8, 14), new(2026, 9, 10), ["Eve", "Bianca"], PullPlanSelectionKind.TargetChoice, 5, 0, 13, 59, "China Standard Time", "China Standard Time"),
        new("routine-rust", "复刻池", new(2026, 8, 27), new(2026, 9, 10), ["Rust"]),
        new("routine-margaret", "复刻池", new(2026, 8, 27), new(2026, 9, 10), ["Margaret"]),
        new("event-chengxiao", "活动池", new(2026, 9, 10), new(2026, 10, 8), ["Chengxiao"]),
        new("directional-parfait-korryn", "定轨池", new(2026, 9, 17), new(2026, 10, 8), ["Parfait", "Korryn"], PullPlanSelectionKind.TargetChoice),
        new("routine-lichen", "复刻池", new(2026, 9, 24), new(2026, 10, 8), ["Lichen"]),
        new("event-phanuel", "活动池", new(2026, 10, 8), new(2026, 11, 5), ["Phanuel"]),
        new("collective-owo-bianca-angell-cabernet", "统合池", new(2026, 10, 8), new(2026, 11, 5), ["OwO", "Bianca", "Angell", "Cabernet"], PullPlanSelectionKind.TargetChoice),
        new("directional-moore-lady-pearl", "定轨池", new(2026, 10, 15), new(2026, 11, 5), ["Moore", "Lady Pearl"], PullPlanSelectionKind.TargetChoice),
        new("routine-xiaofeng", "复刻池", new(2026, 10, 22), new(2026, 11, 5), ["Xiaofeng"]),
        new("event-requiem", "限定池", new(2026, 11, 5), new(2026, 12, 3), ["Requiem"], PullPlanSelectionKind.LockCount),
        new("event-famorene-eirene", "活动池", new(2026, 11, 5), new(2026, 12, 3), ["Famorene Eirene"])
    ];
}
