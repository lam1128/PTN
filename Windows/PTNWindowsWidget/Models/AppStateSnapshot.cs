using System.Text.Json.Serialization;

namespace PTNWindowsWidget.Models;

public sealed class RewardValue
{
    public int Crystals { get; set; }
    public int BlueTickets { get; set; }
    public int RedTickets { get; set; }

    [JsonIgnore]
    public bool IsZero => Crystals == 0 && BlueTickets == 0 && RedTickets == 0;

    public RewardValue Clone() => new()
    {
        Crystals = Crystals,
        BlueTickets = BlueTickets,
        RedTickets = RedTickets
    };

    public string Display()
    {
        var parts = new List<string>();
        if (Crystals != 0) parts.Add($"{(Crystals > 0 ? "+" : "")}{Crystals} 晶");
        if (BlueTickets != 0) parts.Add($"{(BlueTickets > 0 ? "+" : "")}{BlueTickets} 蓝票");
        if (RedTickets != 0) parts.Add($"{(RedTickets > 0 ? "+" : "")}{RedTickets} 红票");
        return parts.Count == 0 ? "+0" : string.Join("  ", parts);
    }
}

public sealed class HistoryEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTimeOffset Timestamp { get; set; }
    public string Source { get; set; } = "";
    public RewardValue Value { get; set; } = new();
    public string? ClaimKey { get; set; }
    public string? AmountTextOverride { get; set; }
}

public sealed class PullPlanTicketRecord
{
    public int GiftTickets { get; set; }
    public int BlueTickets { get; set; }
    public int UpCount { get; set; }
    public int UpTotal { get; set; }
    public int BasePullCount { get; set; }
    public int ConsumedBlueTickets { get; set; }
    public int ConsumedCrystals { get; set; }

    [JsonIgnore]
    public bool IsEmpty => GiftTickets == 0 && BlueTickets == 0 && UpCount == 0 && UpTotal == 0 && BasePullCount == 0;
}

public sealed class GeneralPoolRecord
{
    public int BlueTickets { get; set; }
    public int RedTickets { get; set; }
    public int UpCount { get; set; }
    public int ConsumedBlueTickets { get; set; }
    public int ConsumedRedTickets { get; set; }

    [JsonIgnore]
    public bool IsEmpty => BlueTickets == 0 && RedTickets == 0 && UpCount == 0;
}

public sealed class AppStateSnapshot
{
    public int SchemaVersion { get; set; } = 1;
    public int TotalCrystals { get; set; }
    public int TotalBlueTickets { get; set; }
    public int TotalRedTickets { get; set; }
    public List<string> ClaimedRewardKeys { get; set; } = [];
    public List<HistoryEntry> History { get; set; } = [];
    public Dictionary<string, int> ManualCycleVersions { get; set; } = [];
    public Dictionary<string, int> DailyCycleVersions { get; set; } = [];
    public Dictionary<string, int> PullPlanBannerProgressRawValues { get; set; } = [];
    public Dictionary<string, string> SelectedPullPlanUpChoices { get; set; } = [];
    public Dictionary<string, int> SelectedPullPlanLockChoices { get; set; } = [];
    public Dictionary<string, int> PullPlanPityValues { get; set; } = [];
    public Dictionary<string, PullPlanTicketRecord> PullPlanTicketRecords { get; set; } = [];
    public GeneralPoolRecord? GeneralPoolRecord { get; set; }
    public bool HasPremiumSecretPass { get; set; }
    public bool UsesExtraTranslucentBackground { get; set; }
    public DateTimeOffset? AutomaticStorageLastUpdateAt { get; set; }
    public int AutomaticStorageCalibrationVersion { get; set; }
}
