using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using Microsoft.Win32;
using PTNWindowsWidget.Models;
using PTNWindowsWidget.Services;

namespace PTNWindowsWidget;

public partial class MainWindow : Window
{
    private readonly SharedStateStore stateStore = new();
    private readonly DispatcherTimer externalChangeTimer;
    private AppStateSnapshot snapshot;
    private DateTime? lastSeenFileWrite;
    private bool isRefreshing;
    private Panel activePanel = null!;

    private static readonly Brush InkBrush = new SolidColorBrush(Color.FromRgb(88, 38, 62));
    private static readonly Brush MutedBrush = new SolidColorBrush(Color.FromRgb(145, 98, 118));
    private static readonly Brush AccentBrush = new SolidColorBrush(Color.FromRgb(217, 78, 134));

    public MainWindow()
    {
        InitializeComponent();
        snapshot = stateStore.Load() ?? new AppStateSnapshot();
        if (ApplyAutomaticStorage())
            stateStore.Save(snapshot, out _);
        externalChangeTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(5) };
        externalChangeTimer.Tick += (_, _) => ReloadIfChanged();
        Loaded += (_, _) =>
        {
            PositionWindow();
            externalChangeTimer.Start();
            RefreshView();
        };
        Closed += (_, _) => externalChangeTimer.Stop();
    }

    private void PositionWindow()
    {
        var workArea = SystemParameters.WorkArea;
        Left = workArea.Right - Width - 18;
        Top = workArea.Bottom - Height - 18;
    }

    private void RefreshView()
    {
        if (isRefreshing) return;
        isRefreshing = true;
        try
        {
            var today = BerlinNow().Date;
            DateText.Text = today.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            TotalDrawsText.Text = Math.Floor(snapshot.TotalCrystals / 180.0 + snapshot.TotalBlueTickets).ToString("N0");
            InventoryText.Text = $"{snapshot.TotalCrystals} 晶  ·  {snapshot.TotalBlueTickets} 蓝票  ·  {snapshot.TotalRedTickets} 红票  ·  计划UP {TotalPlannedUpCount()}";
            TodayIncomeText.Text = TodayIncomeTextValue(today);
            SyncStatusText.Text = $"同步：{stateStore.SharedFilePath}";

            BuildCurrentPanel(today);
            BuildPermanentPanel(today);
            BuildPullPlanPanel(today);
            BuildRecordsPanel();
        }
        finally
        {
            isRefreshing = false;
        }
    }

    private void BuildCurrentPanel(DateTime today)
    {
        activePanel = RewardPanel;
        activePanel.Children.Clear();
        AddSectionHeader("当前周期");
        AddAutomaticStorageRow();

        var weekStart = MondayOf(today);
        AddReward("每日监察任务", new RewardValue { Crystals = 40 }, $"daily-fixed-{today:yyyy-MM-dd}", "每日监察任务");
        AddReward("每周分享", new RewardValue { Crystals = 60 }, $"weekly-share-{weekStart:yyyy-MM-dd}", "每周分享");
        AddReward("商店兑换", new RewardValue { BlueTickets = 8, RedTickets = 5 }, $"shop-exchange-{today:yyyy-MM-01}", "商店兑换");

        if (today.Day is 8 or 9)
            AddReward("情绪检测·第8天", new RewardValue { Crystals = 100 }, $"emotion-day-8-{today:yyyy-MM-01}", "情绪检测·第8天");
        if (today.Day is 15 or 16)
            AddReward("情绪检测·第15天", new RewardValue { BlueTickets = 1 }, $"emotion-day-15-{today:yyyy-MM-01}", "情绪检测·第15天");

        AddDarkZoneRewards(today);
        AddReward("情绪检测", new RewardValue { Crystals = 20 }, $"daily-emotion-detection-{today:yyyy-MM-dd}", "情绪检测");
        AddReward("监管事件", new RewardValue { Crystals = 20 }, $"regulatory-event-{today:yyyy-MM-dd}", "监管事件");
        AddEventTrialReward(today);

        AddSectionHeader("日常进度");
        AddProgress("派遣", new[] { 15, 20, 40 }, "daily-dispatch-daily-dispatch-dispatch", "派遣");
        AddProgress("审查·狂级", new[] { 80, 80, 50, 80 }, "daily-review-daily-review-orange", "审查·狂级禁闭者");
        AddProgress("审查·危级", new[] { 60, 50, 60 }, "daily-review-daily-review-purple", "审查·危级禁闭者");
        AddProgress("服从度", new[] { 60, 30, 20, 10, 10, 5 }, "daily-obedience-daily-obedience", "服从度", new[] { "orange-0", "orange-40", "purple-0", "purple-40", "blue-0", "blue-40" });
        AddProgress("周监察任务", new[] { 20, 20, 20, 40, 50 }, $"weekly-inspection-progress-{weekStart:yyyy-MM-dd}-weekly-inspection", "周监察任务");
        var rerun = PullPlanSchedule.Banners.Where(banner => banner.Title == "复刻池" && BannerInstant(banner, true) <= DateTimeOffset.UtcNow)
            .OrderByDescending(banner => BannerInstant(banner, true)).FirstOrDefault();
        if (rerun is not null)
            AddProgress("活动·复刻", new[] { 600, 0, 0, 0 }, $"activity-rerun-{rerun.Start:yyyy-MM-dd}", "活动·复刻", new[] { "crystals", "blue-ticket", "blue-ticket-2", "blue-ticket-3" }, new[] { 1, 2, 3 });

        AddSectionHeader("额外记录");
        AddManualProgress("监察密令·渡鸦", "secret-society-pass", 6, new RewardValue { BlueTickets = snapshot.HasPremiumSecretPass ? 2 : 1 }, true, "密令");
        AddManualProgress("活动·小游戏", "event-mini-game", 5, new RewardValue { Crystals = 50 }, false, "活动·小游戏");
        AddManualProgress("留影兑换", "photo-exchange", 3, new RewardValue { Crystals = -150 }, false, "留影兑换");
        var anchor = CurrentPermanentAnchor();
        if (anchor is not null && PullPlanSchedule.Banners.Count(banner => banner.Title == "活动池" && banner.Start == anchor.Start) >= 2)
            AddManualProgress("主线签到·主线双狂", $"mainline-sign-in-{anchor.Id}", 3, new RewardValue { Crystals = 60 }, false, "主线签到");
        if (anchor?.Title == "限定池")
            AddManualProgress("周年庆签到·周年庆", $"anniversary-sign-in-{anchor.Id}", 3, new RewardValue { Crystals = 60 }, false, "周年庆签到");
        AddManualReward("情绪检测·随机一天", "emotion-random", new RewardValue { BlueTickets = 1 }, true);

        AddNote("Windows 版已对齐 Mac 的主要奖励、进度模块、卡池规划和抽卡记录；卡池日期仍以 Mac 端同步后的配置为准。建议同一时间只在一台设备上修改。");
    }

    private bool ApplyAutomaticStorage()
    {
        var now = DateTimeOffset.UtcNow;
        var last = snapshot.AutomaticStorageLastUpdateAt;
        if (last is null)
        {
            snapshot.AutomaticStorageLastUpdateAt = now;
            return true;
        }

        const double interval = 3 * 60 * 60 + 50 * 60 + 24;
        var cycles = Math.Max(0, (int)Math.Floor((now - last.Value).TotalSeconds / interval));
        if (cycles == 0) return false;

        snapshot.TotalCrystals += cycles * 4;
        for (var index = 1; index <= cycles; index++)
        {
            snapshot.History.Insert(0, new HistoryEntry
            {
                Timestamp = last.Value.AddSeconds(interval * index),
                Source = "基地监管",
                Value = new RewardValue { Crystals = 4 },
                ClaimKey = "automatic-storage"
            });
        }
        snapshot.AutomaticStorageLastUpdateAt = last.Value.AddSeconds(interval * cycles);
        return true;
    }

    private void BuildPermanentPanel(DateTime today)
    {
        activePanel = PermanentPanel;
        activePanel.Children.Clear();
        AddSectionHeader("常驻奖励");
        AddProgress("派遣", new[] { 15, 20, 40 }, "daily-dispatch-daily-dispatch-dispatch", "派遣");
        AddProgress("审查·狂级", new[] { 80, 80, 50, 80 }, "daily-review-daily-review-orange", "审查·狂级禁闭者");
        AddProgress("审查·危级", new[] { 60, 50, 60 }, "daily-review-daily-review-purple", "审查·危级禁闭者");
        AddProgress("服从度", new[] { 60, 30, 20, 10, 10, 5 }, "daily-obedience-daily-obedience", "服从度", new[] { "orange-0", "orange-40", "purple-0", "purple-40", "blue-0", "blue-40" });

        AddSectionHeader("N9 / N10 / 核心危机");
        AddProgress("N9", Enumerable.Repeat(70, 8).Concat(Enumerable.Repeat(35, 3)).Concat(Enumerable.Repeat(20, 3)).ToArray(), "n9-n9", "N9", Enumerable.Range(1, 14).Select(i => $"n9-{i}").ToArray());
        AddProgress("N10", Enumerable.Repeat(70, 8).Concat(Enumerable.Repeat(35, 3)).Concat(Enumerable.Repeat(20, 3)).ToArray(), "n10-n10", "N10", Enumerable.Range(1, 14).Select(i => $"n10-{i}").ToArray());
        AddProgress("核心危机·N9N10", new[] { 50, 50, 0, 50, 50, 0 }, "core-crisis-n9-n10-core-crisis-n9-n10", "核心危机·N9N10", Enumerable.Range(1, 7).Select(i => $"core-crisis-n9-n10-{i}").Take(6).ToArray(), new[] { 2, 5 });

        AddSectionHeader("常驻手动奖励");
        AddManualReward("更新维护", "update-maintenance", new RewardValue { Crystals = 200 }, false);
        AddManualReward("问题修复", "bug-fix", new RewardValue { Crystals = 180 }, false);
        AddManualReward("问卷调查·随机", "questionnaire-random", new RewardValue { Crystals = 180 }, false);
        AddRedemptionCodeProgress(today);
        AddNote("N9、N10 和核心危机的已领取状态与 Mac 共用；每个圆点可单独点击取消。");
    }

    private void BuildPullPlanPanel(DateTime today)
    {
        activePanel = PullPlanPanel;
        activePanel.Children.Clear();
        AddSectionHeader("抽卡规划");
        AddNote("点击左侧圆点切换未规划 / 已规划 / 已完成；目标池可选择角色，限定池可选择锁数。垫抽和抽卡记录会直接影响 Mac 端的同一份存档。");
        foreach (var banner in PullPlanSchedule.Banners)
            AddPullPlanBanner(banner, today);
    }

    private void BuildRecordsPanel()
    {
        activePanel = RecordsPanel;
        activePanel.Children.Clear();
        AddSectionHeader("抽卡记录汇总");
        foreach (var title in new[] { "活动池", "复刻池", "定轨池", "统合池", "限定池" })
        {
            var banners = PullPlanSchedule.Banners.Where(banner => banner.Title == title).ToList();
            var records = banners.Select(banner => snapshot.PullPlanTicketRecords.GetValueOrDefault(banner.Id) ?? new PullPlanTicketRecord()).ToList();
            var draws = records.Sum(record => Math.Max(0, record.BasePullCount - GetPity(banners[records.IndexOf(record)].Id)));
            var ups = records.Sum(record => record.UpCount);
            var total = records.Count == 0 ? 0 : records.Max(record => record.UpTotal);
            AddRecordSummary(title, draws, ups, total);
        }
        AddRecordSummary("普池", GetGeneralPoolDrawCount(), snapshot.GeneralPoolRecord?.UpCount ?? 0, 0, isGeneral: true);
        AddNote("修改某个卡池的记录会先恢复旧记录消耗，再按照新记录重新扣除库存，避免重复扣票。");
    }

    private void AddRecordSummary(string title, int draws, int upCount, int upTotal, bool isGeneral = false)
    {
        var panel = new StackPanel { Margin = new Thickness(0, 0, 0, 8) };
        panel.Children.Add(new TextBlock { Text = title, FontSize = 13, FontWeight = FontWeights.SemiBold, Foreground = InkBrush });
        panel.Children.Add(new TextBlock { Text = $"抽数 {draws}  ·  UP数 {upCount}  ·  UP总数 {upTotal}", Margin = new Thickness(0, 3, 0, 5), Foreground = MutedBrush });
        var button = new Button { Content = isGeneral ? "编辑普池记录" : "在抽卡规划中编辑具体池子", Padding = new Thickness(8, 4, 8, 4), HorizontalAlignment = HorizontalAlignment.Left };
        if (isGeneral) button.Click += (_, _) => EditGeneralPoolRecord();
        else button.Click += (_, _) => MainTabs.SelectedIndex = 2;
        panel.Children.Add(button);
        activePanel.Children.Add(panel);
    }

    private int TotalPlannedUpCount()
    {
        return PullPlanSchedule.Banners.Sum(banner => GetBannerProgress(banner.Id) == PullPlanProgress.Planned
            ? banner.SelectionKind == PullPlanSelectionKind.LockCount
                ? snapshot.SelectedPullPlanLockChoices.GetValueOrDefault(banner.Id) + 1
                : 1
            : 0);
    }

    private int GetGeneralPoolDrawCount()
    {
        var record = snapshot.GeneralPoolRecord;
        return record is null ? 0 : record.BlueTickets + record.RedTickets;
    }

    private int GetPity(string bannerID) => snapshot.PullPlanPityValues.GetValueOrDefault(PityGroupKey(bannerID));

    private static string PityGroupKey(string bannerID)
    {
        var banner = PullPlanSchedule.Banners.FirstOrDefault(item => item.Id == bannerID);
        return banner?.Title switch
        {
            "活动池" => "pull-plan-pity-event-arrest",
            "复刻池" => "pull-plan-pity-routine-arrest",
            "定轨池" => "pull-plan-pity-directional-arrest",
            "统合池" => "pull-plan-pity-collective-arrest",
            "限定池" => "pull-plan-pity-limited-arrest",
            _ => $"pull-plan-pity-{bannerID}"
        };
    }

    private void AddAutomaticStorageRow()
    {
        var lastUpdate = snapshot.AutomaticStorageLastUpdateAt ?? DateTimeOffset.UtcNow;
        var fullAt = lastUpdate.AddSeconds(3 * 60 * 60 + 50 * 60 + 24 * 12);
        var row = new StackPanel { Margin = new Thickness(0, 0, 0, 8) };
        row.Children.Add(new TextBlock { Text = "基地监管", FontSize = 12, FontWeight = FontWeights.SemiBold, Foreground = InkBrush });
        row.Children.Add(new TextBlock { Text = $"每周期 +4 晶  ·  预计满仓：{fullAt.ToLocalTime():MM-dd HH:mm}", Margin = new Thickness(0, 3, 0, 0), FontSize = 10, Foreground = MutedBrush });
        activePanel.Children.Add(row);
    }

    private void AddEventTrialReward(DateTime today)
    {
        var now = BerlinNow();
        var active = PullPlanSchedule.Banners.Where(banner => banner.Title is "活动池" or "限定池")
            .Where(banner => IsBannerActive(banner, now)).ToList();
        if (active.Count == 0) return;
        var title = active.Count == 2 && active.All(banner => banner.Id is "event-celine" or "event-isomer")
            ? "主线双狂"
            : string.Join(" / ", active.SelectMany(banner => banner.Characters));
        var value = new RewardValue { Crystals = active.Count * 50 + 10 };
        AddReward($"试用·{title}", value, $"event-trial-{string.Join("-", active.Select(banner => banner.Id).OrderBy(id => id))}", $"试用·{title}");
    }

    private void AddManualReward(string title, string sourceID, RewardValue value, bool monthly, string? claimKeyOverride = null)
    {
        var cycleVersion = snapshot.ManualCycleVersions.GetValueOrDefault(sourceID);
        var claimKey = claimKeyOverride ?? (monthly
            ? $"{sourceID}-{BerlinNow():yyyy-MM-01}"
            : $"{sourceID}-manual-v{cycleVersion}");
        AddReward(title, value, claimKey, title);
        if (monthly) return;

        var reset = new Button { Content = "下一轮", Padding = new Thickness(7, 3, 7, 3), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, -3, 0, 8) };
        reset.Click += (_, _) =>
        {
            snapshot.ManualCycleVersions[sourceID] = cycleVersion + 1;
            SaveAndRefresh();
        };
        activePanel.Children.Add(reset);
    }

    private void AddManualProgress(string title, string moduleID, int slotCount, RewardValue value, bool hasPremium, string source)
    {
        var version = snapshot.ManualCycleVersions.GetValueOrDefault(moduleID);
        var section = new StackPanel { Margin = new Thickness(0, 0, 0, 9) };
        var header = new DockPanel();
        header.Children.Add(new TextBlock { Text = title, FontSize = 12, FontWeight = FontWeights.SemiBold, Foreground = InkBrush });
        var controls = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right };
        if (hasPremium)
        {
            var premium = new Button { Content = snapshot.HasPremiumSecretPass ? "高级已购" : "高级", Padding = new Thickness(6, 2, 6, 2), Margin = new Thickness(5, 0, 0, 0) };
            premium.Click += (_, _) => { snapshot.HasPremiumSecretPass = !snapshot.HasPremiumSecretPass; SaveAndRefresh(); };
            controls.Children.Add(premium);
        }
        var reset = new Button { Content = "↻", Padding = new Thickness(6, 2, 6, 2), Margin = new Thickness(5, 0, 0, 0) };
        reset.Click += (_, _) => { snapshot.ManualCycleVersions[moduleID] = version + 1; SaveAndRefresh(); };
        controls.Children.Add(reset);
        DockPanel.SetDock(controls, Dock.Right);
        header.Children.Add(controls);
        section.Children.Add(header);

        var row = new WrapPanel { Margin = new Thickness(0, 5, 0, 0) };
        var claimedCount = 0;
        for (var index = 1; index <= slotCount; index++)
        {
            var claimKey = $"{moduleID}-v{version}-slot-{index}";
            var isClaimed = snapshot.ClaimedRewardKeys.Contains(claimKey);
            if (isClaimed) claimedCount++;
            AddProgressSlot(row, claimKey, value, $"{value.Display()}\n{index}", source);
            if (hasPremium && snapshot.HasPremiumSecretPass && (index == 2 || index == 5))
            {
                var premiumValue = index == 2 ? new RewardValue { Crystals = 200 } : new RewardValue { Crystals = 680 };
                var premiumKey = $"{moduleID}-v{version}-premium-bonus-{premiumValue.Crystals}";
                AddProgressSlot(row, premiumKey, premiumValue, $"高级\n+{premiumValue.Crystals}晶", source);
            }
        }
        section.Children.Add(row);
        section.Children.Add(new TextBlock { Text = $"{claimedCount}/{slotCount}  {value.Display()}", FontSize = 10, Foreground = MutedBrush });
        activePanel.Children.Add(section);
    }

    private void AddRedemptionCodeProgress(DateTime today)
    {
        var anchor = PullPlanSchedule.Banners.FirstOrDefault(banner => IsBannerActive(banner, BerlinNow()) && (banner.Title is "活动池" or "限定池"));
        if (anchor is null) return;
        var start = BannerDate(anchor, true).Date.AddHours(8);
        var end = start.AddDays(19).AddHours(9).AddMinutes(59);
        if (BerlinNow() < start || BerlinNow() >= end) return;
        AddManualProgress($"兑换码·{anchor.Characters.FirstOrDefault() ?? anchor.Title}", $"redemption-code-{anchor.Id}", anchor.Title is "限定池" || PullPlanSchedule.Banners.Count(banner => banner.Title == "活动池" && banner.Start == anchor.Start) >= 2 ? 3 : 1, new RewardValue { Crystals = 200 }, false, "兑换码");
    }

    private void AddProgressSlot(Panel parent, string claimKey, RewardValue value, string label, string source)
    {
        var claimed = snapshot.ClaimedRewardKeys.Contains(claimKey);
        var button = new Button
        {
            Content = claimed ? $"✓\n{label}" : label,
            Padding = new Thickness(7, 5, 7, 5),
            Margin = new Thickness(0, 0, 5, 5),
            FontSize = 9,
            Foreground = claimed ? new SolidColorBrush(Color.FromRgb(78, 137, 117)) : AccentBrush,
            Background = claimed ? new SolidColorBrush(Color.FromRgb(224, 245, 238)) : new SolidColorBrush(Color.FromRgb(255, 247, 251)),
            Tag = new RewardAction(claimKey, value, source)
        };
        button.Click += RewardButtonClick;
        parent.Children.Add(button);
    }

    private void AddPullPlanBanner(PullPlanBanner banner, DateTime today)
    {
        var now = BerlinNow();
        var progress = GetBannerProgress(banner.Id);
        var row = new StackPanel { Margin = new Thickness(0, 0, 0, 9) };
        var header = new DockPanel();
        var toggle = new Button
        {
            Content = progress switch { PullPlanProgress.None => "○", PullPlanProgress.Planned => "●", _ => "✓" },
            Width = 26,
            Height = 26,
            Padding = new Thickness(0),
            Margin = new Thickness(0, 0, 7, 0),
            Foreground = progress == PullPlanProgress.None ? MutedBrush : AccentBrush
        };
        toggle.Click += (_, _) => TogglePullPlanBanner(banner);
        DockPanel.SetDock(toggle, Dock.Left);
        header.Children.Add(toggle);

        var title = new TextBlock
        {
            Text = $"{banner.Title} · {string.Join(" / ", banner.Characters)}",
            FontSize = 12,
            FontWeight = FontWeights.SemiBold,
            Foreground = progress == PullPlanProgress.Completed ? new SolidColorBrush(Color.FromRgb(78, 137, 117)) : InkBrush
        };
        header.Children.Add(title);
        var record = new Button { Content = "记录", Padding = new Thickness(6, 2, 6, 2), Margin = new Thickness(5, 0, 0, 0) };
        record.Click += (_, _) => EditPullPlanRecord(banner);
        DockPanel.SetDock(record, Dock.Right);
        header.Children.Add(record);
        row.Children.Add(header);

        var timing = new TextBlock
        {
            Text = $"{BannerDate(banner, true):yyyy-MM-dd HH:mm} - {BannerDate(banner, false):yyyy-MM-dd HH:mm}  ·  {ProgressLabel(progress)}",
            Margin = new Thickness(33, 2, 0, 4),
            FontSize = 10,
            Foreground = MutedBrush
        };
        row.Children.Add(timing);

        var controls = new WrapPanel { Margin = new Thickness(33, 0, 0, 0) };
        if (banner.SelectionKind == PullPlanSelectionKind.TargetChoice)
        {
            foreach (var character in banner.Characters)
            {
                var selected = snapshot.SelectedPullPlanUpChoices.GetValueOrDefault(banner.Id) == character;
                var choice = new Button { Content = selected ? $"✓ {character}" : character, Padding = new Thickness(6, 3, 6, 3), Margin = new Thickness(0, 0, 5, 5) };
                choice.Click += (_, _) =>
                {
                    if (selected) snapshot.SelectedPullPlanUpChoices.Remove(banner.Id);
                    else snapshot.SelectedPullPlanUpChoices[banner.Id] = character;
                    SaveAndRefresh();
                };
                controls.Children.Add(choice);
            }
        }
        else if (banner.SelectionKind == PullPlanSelectionKind.LockCount)
        {
            for (var lockLevel = 0; lockLevel <= 4; lockLevel++)
            {
                var selected = snapshot.SelectedPullPlanLockChoices.GetValueOrDefault(banner.Id) == lockLevel;
                var choice = new Button { Content = selected ? $"✓ {lockLevel}锁" : $"{lockLevel}锁", Padding = new Thickness(6, 3, 6, 3), Margin = new Thickness(0, 0, 5, 5) };
                choice.Click += (_, _) =>
                {
                    if (selected)
                    {
                        snapshot.SelectedPullPlanLockChoices.Remove(banner.Id);
                        snapshot.PullPlanBannerProgressRawValues.Remove(banner.Id);
                    }
                    else
                    {
                        snapshot.SelectedPullPlanLockChoices[banner.Id] = lockLevel;
                        snapshot.PullPlanBannerProgressRawValues[banner.Id] = 1;
                    }
                    SaveAndRefresh();
                };
                controls.Children.Add(choice);
            }
        }

        var pity = new Button { Content = $"垫抽 {GetPity(banner.Id)}", Padding = new Thickness(6, 3, 6, 3), Margin = new Thickness(0, 0, 5, 5) };
        pity.Click += (_, _) =>
        {
            var value = PromptForInteger("编辑垫抽", "当前垫抽", GetPity(banner.Id));
            if (value is not null)
            {
                snapshot.PullPlanPityValues[PityGroupKey(banner.Id)] = Math.Max(0, value.Value);
                SaveAndRefresh();
            }
        };
        controls.Children.Add(pity);
        row.Children.Add(controls);
        activePanel.Children.Add(row);
    }

    private PullPlanProgress GetBannerProgress(string bannerID)
    {
        return snapshot.PullPlanBannerProgressRawValues.GetValueOrDefault(bannerID) switch
        {
            1 => PullPlanProgress.Planned,
            2 => PullPlanProgress.Completed,
            _ => PullPlanProgress.None
        };
    }

    private void TogglePullPlanBanner(PullPlanBanner banner)
    {
        var current = GetBannerProgress(banner.Id);
        var next = current switch
        {
            PullPlanProgress.None => PullPlanProgress.Planned,
            PullPlanProgress.Planned when IsBannerActive(banner, BerlinNow()) => PullPlanProgress.Completed,
            PullPlanProgress.Planned => PullPlanProgress.None,
            _ => PullPlanProgress.None
        };
        if (next == PullPlanProgress.None) snapshot.PullPlanBannerProgressRawValues.Remove(banner.Id);
        else snapshot.PullPlanBannerProgressRawValues[banner.Id] = (int)next;
        SaveAndRefresh();
    }

    private static string ProgressLabel(PullPlanProgress progress) => progress switch
    {
        PullPlanProgress.Planned => "已规划",
        PullPlanProgress.Completed => "已完成",
        _ => "未规划"
    };

    private static bool IsBannerActive(PullPlanBanner banner, DateTime now)
    {
        var utcNow = DateTimeOffset.UtcNow;
        return BannerInstant(banner, true) <= utcNow && utcNow < BannerInstant(banner, false);
    }

    private static DateTimeOffset BannerInstant(PullPlanBanner banner, bool start)
    {
        var zone = TimeZoneInfo.FindSystemTimeZoneById(start ? (banner.TimeZoneId ?? "W. Europe Standard Time") : (banner.EndTimeZoneId ?? banner.TimeZoneId ?? "W. Europe Standard Time"));
        var date = start ? banner.Start : banner.End;
        var local = DateTime.SpecifyKind(date.Date.AddHours(start ? banner.StartHour : banner.EndHour).AddMinutes(start ? banner.StartMinute : banner.EndMinute), DateTimeKind.Unspecified);
        return new DateTimeOffset(local, zone.GetUtcOffset(local)).ToUniversalTime();
    }

    private static DateTime BannerDate(PullPlanBanner banner, bool start)
    {
        return TimeZoneInfo.ConvertTime(BannerInstant(banner, start), TimeZoneInfo.FindSystemTimeZoneById("W. Europe Standard Time")).DateTime;
    }

    private static PullPlanBanner? CurrentPermanentAnchor()
    {
        return PullPlanSchedule.Banners
            .Where(banner => (banner.Title is "活动池" or "限定池") && IsBannerActive(banner, BerlinNow()))
            .OrderByDescending(banner => BannerInstant(banner, true))
            .ThenByDescending(banner => banner.Id)
            .FirstOrDefault();
    }

    private void EditPullPlanRecord(PullPlanBanner banner)
    {
        var old = snapshot.PullPlanTicketRecords.GetValueOrDefault(banner.Id) ?? new PullPlanTicketRecord();
        var giftTickets = PromptForInteger("抽卡记录", "赠送票", old.GiftTickets);
        if (giftTickets is null) return;
        var blueTickets = PromptForInteger("抽卡记录", "蓝票消耗", old.BlueTickets);
        if (blueTickets is null) return;
        var upCount = PromptForInteger("抽卡记录", "本池 UP 数", old.UpCount);
        if (upCount is null) return;
        var upTotal = PromptForInteger("抽卡记录", "UP 总数", old.UpTotal);
        if (upTotal is null) return;

        var previous = old;
        var available = snapshot.TotalBlueTickets + snapshot.TotalCrystals / 180 + previous.ConsumedBlueTickets + previous.ConsumedCrystals / 180;
        if (blueTickets.Value < 0 || blueTickets.Value > available)
        {
            MessageBox.Show(this, $"蓝票消耗不能超过当前可用抽卡等价物：{available}。", "抽卡记录", MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }

        RestorePullPlanConsumption(banner.Id, previous);
        var consumedBlue = Math.Min(blueTickets.Value, snapshot.TotalBlueTickets);
        var consumedCrystals = (blueTickets.Value - consumedBlue) * 180;
        snapshot.TotalBlueTickets -= consumedBlue;
        snapshot.TotalCrystals -= consumedCrystals;
        var updated = new PullPlanTicketRecord
        {
            GiftTickets = Math.Max(0, giftTickets.Value),
            BlueTickets = Math.Max(0, blueTickets.Value),
            UpCount = Math.Max(0, upCount.Value),
            UpTotal = Math.Max(0, upTotal.Value),
            BasePullCount = GetPity(banner.Id) + Math.Max(0, blueTickets.Value) + Math.Max(0, giftTickets.Value),
            ConsumedBlueTickets = consumedBlue,
            ConsumedCrystals = consumedCrystals
        };
        var key = $"pull-plan-record-{banner.Id}";
        snapshot.History.RemoveAll(entry => entry.ClaimKey == key);
        if (updated.IsEmpty)
            snapshot.PullPlanTicketRecords.Remove(banner.Id);
        else
        {
            snapshot.PullPlanTicketRecords[banner.Id] = updated;
            snapshot.History.Insert(0, new HistoryEntry
            {
                Timestamp = DateTimeOffset.UtcNow,
                Source = $"抽卡记录·{snapshot.SelectedPullPlanUpChoices.GetValueOrDefault(banner.Id, banner.Characters.FirstOrDefault() ?? banner.Title)}",
                Value = new RewardValue { BlueTickets = -consumedBlue, Crystals = -consumedCrystals },
                ClaimKey = key,
                AmountTextOverride = RecordAmountText(giftTickets.Value, consumedBlue, consumedCrystals)
            });
        }
        SaveAndRefresh();
    }

    private void RestorePullPlanConsumption(string bannerID, PullPlanTicketRecord record)
    {
        if (record.IsEmpty) return;
        snapshot.TotalBlueTickets += record.ConsumedBlueTickets;
        snapshot.TotalCrystals += record.ConsumedCrystals;
        snapshot.History.RemoveAll(entry => entry.ClaimKey == $"pull-plan-record-{bannerID}");
    }

    private static string RecordAmountText(int giftTickets, int blueTickets, int crystals)
    {
        var parts = new List<string>();
        if (giftTickets > 0) parts.Add($"-{giftTickets}赠送票");
        if (blueTickets > 0) parts.Add($"-{blueTickets}蓝票");
        if (crystals > 0) parts.Add($"-{crystals}晶");
        return parts.Count == 0 ? "已记录" : string.Join(" · ", parts);
    }

    private void EditGeneralPoolRecord()
    {
        var old = snapshot.GeneralPoolRecord ?? new GeneralPoolRecord();
        var blue = PromptForInteger("普池记录", "蓝票", old.BlueTickets);
        if (blue is null) return;
        var red = PromptForInteger("普池记录", "红票", old.RedTickets);
        if (red is null) return;
        var up = PromptForInteger("普池记录", "UP 数", old.UpCount);
        if (up is null) return;
        var availableBlue = snapshot.TotalBlueTickets + old.ConsumedBlueTickets;
        var availableRed = snapshot.TotalRedTickets + old.ConsumedRedTickets;
        if (blue.Value < 0 || blue.Value > availableBlue || red.Value < 0 || red.Value > availableRed)
        {
            MessageBox.Show(this, $"可用票不足。蓝票上限 {availableBlue}，红票上限 {availableRed}。", "普池记录", MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }
        snapshot.TotalBlueTickets += old.ConsumedBlueTickets;
        snapshot.TotalRedTickets += old.ConsumedRedTickets;
        snapshot.History.RemoveAll(entry => entry.ClaimKey == "general-pool-record");
        var updated = new GeneralPoolRecord
        {
            BlueTickets = Math.Max(0, blue.Value),
            RedTickets = Math.Max(0, red.Value),
            UpCount = Math.Max(0, up.Value),
            ConsumedBlueTickets = Math.Max(0, blue.Value),
            ConsumedRedTickets = Math.Max(0, red.Value)
        };
        snapshot.TotalBlueTickets -= updated.ConsumedBlueTickets;
        snapshot.TotalRedTickets -= updated.ConsumedRedTickets;
        snapshot.GeneralPoolRecord = updated.IsEmpty ? null : updated;
        if (!updated.IsEmpty)
        {
            snapshot.History.Insert(0, new HistoryEntry
            {
                Timestamp = DateTimeOffset.UtcNow,
                Source = "抽卡记录·普池",
                Value = new RewardValue { BlueTickets = -updated.ConsumedBlueTickets, RedTickets = -updated.ConsumedRedTickets },
                ClaimKey = "general-pool-record",
                AmountTextOverride = $"-{updated.ConsumedBlueTickets}蓝票 · -{updated.ConsumedRedTickets}红票"
            });
        }
        SaveAndRefresh();
    }

    private int? PromptForInteger(string title, string field, int value)
    {
        var dialog = new Window
        {
            Owner = this,
            Title = title,
            Width = 280,
            Height = 155,
            WindowStartupLocation = WindowStartupLocation.CenterOwner,
            ResizeMode = ResizeMode.NoResize
        };
        var layout = new StackPanel { Margin = new Thickness(16) };
        layout.Children.Add(new TextBlock { Text = field, Margin = new Thickness(0, 0, 0, 6) });
        var box = new TextBox { Text = value.ToString(CultureInfo.InvariantCulture), Margin = new Thickness(0, 0, 0, 12) };
        layout.Children.Add(box);
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right };
        int? result = null;
        var cancel = new Button { Content = "取消", Padding = new Thickness(10, 4, 10, 4), Margin = new Thickness(0, 0, 6, 0) };
        cancel.Click += (_, _) => dialog.Close();
        var confirm = new Button { Content = "确认", Padding = new Thickness(10, 4, 10, 4) };
        confirm.Click += (_, _) =>
        {
            if (int.TryParse(box.Text, out var parsed))
            {
                result = parsed;
                dialog.Close();
            }
        };
        buttons.Children.Add(cancel);
        buttons.Children.Add(confirm);
        layout.Children.Add(buttons);
        dialog.Content = layout;
        dialog.ShowDialog();
        return result;
    }
    private string TodayIncomeTextValue(DateTime today)
    {
        var total = snapshot.History
            .Where(entry => entry.Timestamp.ToLocalTime().Date == today)
            .Sum(entry => entry.Value.Crystals + entry.Value.BlueTickets * 180 + entry.Value.RedTickets * 180);
        return total == 0 ? "" : $"今日 {total:+#;-#;0} 晶";
    }

    private void AddDarkZoneRewards(DateTime today)
    {
        var anchor = new DateTime(2026, 8, 10);
        var weekStart = MondayOf(today);
        var weekOffset = (int)Math.Floor((weekStart - anchor).TotalDays / 7.0);
        var seasonOffset = FloorDiv(weekOffset, 6);
        var weekIndex = PositiveMod(weekOffset, 6) + 1;
        var season = 31 + seasonOffset;
        AddReward($"暗域·第{season}期第{weekIndex}周", new RewardValue { Crystals = 510 }, $"dark-zone-{season}-week-{weekIndex}", $"暗域·第{season}期第{weekIndex}周");

        for (var pastSeason = 31; pastSeason <= season; pastSeason++)
        {
            var seasonStart = anchor.AddDays((pastSeason - 31) * 42);
            if (seasonStart > today) continue;
            var claimKey = $"dark-zone-season-{pastSeason}";
            if (pastSeason == season || !snapshot.ClaimedRewardKeys.Contains(claimKey))
                AddReward($"暗域·第{pastSeason}期赛季奖励", new RewardValue { Crystals = 450 }, claimKey, $"暗域·第{pastSeason}期赛季奖励");
        }
    }

    private void AddProgress(
        string title,
        IReadOnlyList<int> values,
        string keyPrefix,
        string source,
        IReadOnlyList<string>? slotIds = null,
        IReadOnlyList<int>? blueTicketIndices = null
    )
    {
        var panel = new StackPanel { Margin = new Thickness(0, 0, 0, 9) };
        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = 12,
            FontWeight = FontWeights.SemiBold,
            Foreground = InkBrush,
            Margin = new Thickness(2, 0, 0, 5)
        };
        panel.Children.Add(titleBlock);
        var row = new WrapPanel { Orientation = Orientation.Horizontal };
        for (var index = 0; index < values.Count; index++)
        {
            var value = blueTicketIndices?.Contains(index) == true
                ? new RewardValue { BlueTickets = 1 }
                : new RewardValue { Crystals = values[index] };
            var slotID = slotIds?.ElementAtOrDefault(index) ?? (index + 1).ToString(CultureInfo.InvariantCulture);
            var claimKey = slotIds is null ? $"{keyPrefix}-{index + 1}" : $"{keyPrefix}-{slotID}-1";
            AddSmallReward(row, value, claimKey, $"{source}·第{index + 1}项");
        }
        panel.Children.Add(row);
        activePanel.Children.Add(panel);
    }

    private void AddSectionHeader(string text)
    {
        activePanel.Children.Add(new TextBlock
        {
            Text = text,
            FontSize = 13,
            FontWeight = FontWeights.Bold,
            Foreground = AccentBrush,
            Margin = new Thickness(2, 4, 0, 7)
        });
    }

    private void AddReward(string title, RewardValue value, string claimKey, string source)
    {
        var claimed = snapshot.ClaimedRewardKeys.Contains(claimKey);
        var button = new Button
        {
            Padding = new Thickness(12, 9, 12, 9),
            Margin = new Thickness(0, 0, 0, 7),
            HorizontalContentAlignment = HorizontalAlignment.Stretch,
            Background = claimed ? new SolidColorBrush(Color.FromRgb(224, 245, 238)) : new SolidColorBrush(Color.FromRgb(255, 247, 251)),
            BorderBrush = claimed ? new SolidColorBrush(Color.FromRgb(120, 193, 171)) : new SolidColorBrush(Color.FromRgb(237, 194, 213)),
            Tag = new RewardAction(claimKey, value, source)
        };
        button.Content = RewardContent(title, value, claimed);
        button.Click += RewardButtonClick;
        activePanel.Children.Add(button);
    }

    private static void AddSmallReward(Panel parent, RewardValue value, string claimKey, string source)
    {
        var owner = new SmallRewardHost(claimKey, value, source);
        var button = new Button
        {
            Content = value.Display().Replace("晶", ""),
            Padding = new Thickness(8, 5, 8, 5),
            Margin = new Thickness(0, 0, 5, 5),
            FontSize = 10,
            Tag = owner
        };
        button.Click += (sender, _) =>
        {
            if (sender is not Button clicked || clicked.Tag is not SmallRewardHost action) return;
            var window = Window.GetWindow(clicked) as MainWindow;
            window?.ToggleReward(action.ClaimKey, action.Value, action.Source);
        };
        parent.Children.Add(button);
    }

    private void AddNote(string text)
    {
        activePanel.Children.Add(new TextBlock
        {
            Text = text,
            TextWrapping = TextWrapping.Wrap,
            FontSize = 10,
            Foreground = MutedBrush,
            Margin = new Thickness(2, 0, 2, 8)
        });
    }

    private static StackPanel RewardContent(string title, RewardValue value, bool claimed)
    {
        var content = new StackPanel();
        content.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 12,
            FontWeight = FontWeights.SemiBold,
            Foreground = claimed ? new SolidColorBrush(Color.FromRgb(78, 137, 117)) : InkBrush
        });
        content.Children.Add(new TextBlock
        {
            Text = value.Display(),
            FontSize = 11,
            Margin = new Thickness(0, 3, 0, 0),
            Foreground = claimed ? new SolidColorBrush(Color.FromRgb(78, 137, 117)) : AccentBrush
        });
        return content;
    }

    private void RewardButtonClick(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: RewardAction action })
            ToggleReward(action.ClaimKey, action.Value, action.Source);
    }

    private void ToggleReward(string claimKey, RewardValue value, string source)
    {
        if (snapshot.ClaimedRewardKeys.Contains(claimKey))
        {
            snapshot.ClaimedRewardKeys.Remove(claimKey);
            ApplyValue(new RewardValue { Crystals = -value.Crystals, BlueTickets = -value.BlueTickets, RedTickets = -value.RedTickets });
            snapshot.History.RemoveAll(entry => entry.ClaimKey == claimKey);
        }
        else
        {
            snapshot.ClaimedRewardKeys.Add(claimKey);
            ApplyValue(value);
            snapshot.History.Insert(0, new HistoryEntry
            {
                Timestamp = DateTimeOffset.UtcNow,
                Source = source,
                Value = value.Clone(),
                ClaimKey = claimKey
            });
        }
        SaveAndRefresh();
    }

    private void ApplyValue(RewardValue value)
    {
        snapshot.TotalCrystals = Math.Max(0, snapshot.TotalCrystals + value.Crystals);
        snapshot.TotalBlueTickets = Math.Max(0, snapshot.TotalBlueTickets + value.BlueTickets);
        snapshot.TotalRedTickets = Math.Max(0, snapshot.TotalRedTickets + value.RedTickets);
    }

    private void EditInventoryClick(object sender, RoutedEventArgs e)
    {
        var dialog = new Window
        {
            Owner = this,
            Title = "编辑库存",
            Width = 300,
            Height = 245,
            WindowStartupLocation = WindowStartupLocation.CenterOwner,
            ResizeMode = ResizeMode.NoResize
        };
        var grid = new Grid { Margin = new Thickness(18) };
        for (var i = 0; i < 4; i++) grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        var fields = new[] { ("异方晶", snapshot.TotalCrystals), ("蓝票", snapshot.TotalBlueTickets), ("红票", snapshot.TotalRedTickets) };
        var boxes = new List<TextBox>();
        for (var i = 0; i < fields.Length; i++)
        {
            var row = new Grid { Margin = new Thickness(0, 0, 0, 8) };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(70) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.Children.Add(new TextBlock { Text = fields[i].Item1, VerticalAlignment = VerticalAlignment.Center });
            var box = new TextBox { Text = fields[i].Item2.ToString(CultureInfo.InvariantCulture) };
            Grid.SetColumn(box, 1);
            row.Children.Add(box);
            Grid.SetRow(row, i);
            grid.Children.Add(row);
            boxes.Add(box);
        }
        var save = new Button { Content = "保存", Padding = new Thickness(12, 5, 12, 5), HorizontalAlignment = HorizontalAlignment.Right };
        save.Click += (_, _) =>
        {
            if (!int.TryParse(boxes[0].Text, out var crystals) || !int.TryParse(boxes[1].Text, out var blue) || !int.TryParse(boxes[2].Text, out var red)) return;
            var delta = new RewardValue { Crystals = crystals - snapshot.TotalCrystals, BlueTickets = blue - snapshot.TotalBlueTickets, RedTickets = red - snapshot.TotalRedTickets };
            snapshot.TotalCrystals = Math.Max(0, crystals);
            snapshot.TotalBlueTickets = Math.Max(0, blue);
            snapshot.TotalRedTickets = Math.Max(0, red);
            if (!delta.IsZero)
            {
                snapshot.History.Insert(0, new HistoryEntry { Timestamp = DateTimeOffset.UtcNow, Source = "手动调整库存", Value = delta, ClaimKey = null });
            }
            dialog.Close();
            SaveAndRefresh();
        };
        Grid.SetRow(save, 3);
        grid.Children.Add(save);
        dialog.Content = grid;
        dialog.ShowDialog();
    }

    private void HistoryClick(object sender, RoutedEventArgs e)
    {
        if (snapshot.History.Count == 0)
        {
            MessageBox.Show(this, "还没有历史记录。", "历史", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        var lines = snapshot.History.Take(15).Select(entry =>
            $"{entry.Timestamp.ToLocalTime():MM-dd HH:mm}  {entry.Source}  {entry.Value.Display()}");
        var result = MessageBox.Show(this, string.Join(Environment.NewLine, lines) + "\n\n是否撤销最新一条？", "历史记录", MessageBoxButton.YesNo, MessageBoxImage.Information);
        if (result == MessageBoxResult.Yes)
        {
            var latest = snapshot.History.FirstOrDefault(entry => entry.ClaimKey is null || entry.ClaimKey != "automatic-storage");
            if (latest is null) return;
            if (latest.ClaimKey == "general-pool-record")
            {
                var general = snapshot.GeneralPoolRecord;
                if (general is not null)
                {
                    snapshot.TotalBlueTickets += general.ConsumedBlueTickets;
                    snapshot.TotalRedTickets += general.ConsumedRedTickets;
                    snapshot.GeneralPoolRecord = null;
                }
                snapshot.History.Remove(latest);
                SaveAndRefresh();
                return;
            }
            if (latest.ClaimKey?.StartsWith("pull-plan-record-", StringComparison.Ordinal) == true)
            {
                var bannerID = latest.ClaimKey["pull-plan-record-".Length..];
                if (snapshot.PullPlanTicketRecords.Remove(bannerID, out var record))
                    RestorePullPlanConsumption(bannerID, record);
                snapshot.History.Remove(latest);
                SaveAndRefresh();
                return;
            }
            ApplyValue(new RewardValue { Crystals = -latest.Value.Crystals, BlueTickets = -latest.Value.BlueTickets, RedTickets = -latest.Value.RedTickets });
            if (latest.ClaimKey is not null) snapshot.ClaimedRewardKeys.Remove(latest.ClaimKey);
            snapshot.History.Remove(latest);
            SaveAndRefresh();
        }
    }

    private void ChooseSyncFileClick(object sender, RoutedEventArgs e)
    {
        var dialog = new SaveFileDialog
        {
            Title = "选择 Mac 与 Windows 共用的同步文件",
            FileName = "ptn-shared-state.json",
            Filter = "PTN 同步文件|ptn-shared-state.json|JSON 文件|*.json"
        };
        if (dialog.ShowDialog(this) == true)
        {
            stateStore.ConfigureSharedFile(dialog.FileName);
            SaveAndRefresh();
        }
    }

    private void RefreshClick(object sender, RoutedEventArgs e) => ReloadIfChanged(force: true);

    private void ReloadIfChanged(bool force = false)
    {
        var writeTime = stateStore.LastWriteTimeUtc();
        if (!force && (writeTime is null || writeTime <= lastSeenFileWrite)) return;
        var loaded = stateStore.Load();
        if (loaded is null) return;
        snapshot = loaded;
        if (ApplyAutomaticStorage())
            stateStore.Save(snapshot, out _);
        lastSeenFileWrite = writeTime;
        RefreshView();
    }

    private void SaveAndRefresh()
    {
        snapshot.ClaimedRewardKeys = snapshot.ClaimedRewardKeys.Distinct().OrderBy(key => key).ToList();
        if (stateStore.Save(snapshot, out var error))
        {
            lastSeenFileWrite = stateStore.LastWriteTimeUtc();
        }
        else
        {
            SyncStatusText.Text = $"同步失败：{error}";
        }
        RefreshView();
    }

    private void HeaderMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.LeftButton == MouseButtonState.Pressed) DragMove();
    }

    private void CloseButtonClick(object sender, RoutedEventArgs e) => Close();

    private static DateTime BerlinNow()
    {
        var zone = TimeZoneInfo.FindSystemTimeZoneById("W. Europe Standard Time");
        return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, zone);
    }

    private static DateTime MondayOf(DateTime date)
    {
        var offset = ((int)date.DayOfWeek + 6) % 7;
        return date.Date.AddDays(-offset);
    }

    private static int FloorDiv(int value, int divisor) => (int)Math.Floor(value / (double)divisor);
    private static int PositiveMod(int value, int divisor) => ((value % divisor) + divisor) % divisor;

    private sealed record RewardAction(string ClaimKey, RewardValue Value, string Source);
    private sealed record SmallRewardHost(string ClaimKey, RewardValue Value, string Source);
}
