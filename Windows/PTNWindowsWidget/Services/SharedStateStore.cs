using System.IO;
using System.Text.Json;
using PTNWindowsWidget.Models;

namespace PTNWindowsWidget.Services;

public sealed class SharedStateStore
{
    private const string SettingsDirectoryName = "PTNWindowsWidget";
    private const string SettingsFileName = "settings.json";
    private readonly string settingsPath;
    private readonly JsonSerializerOptions jsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        WriteIndented = true
    };

    public string SharedFilePath { get; private set; }

    public SharedStateStore()
    {
        var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var settingsDirectory = Path.Combine(appData, SettingsDirectoryName);
        Directory.CreateDirectory(settingsDirectory);
        settingsPath = Path.Combine(settingsDirectory, SettingsFileName);
        SharedFilePath = ReadConfiguredPath() ?? Path.Combine(FindOneDriveRoot() ?? settingsDirectory, "PTN", "ptn-shared-state.json");
    }

    public AppStateSnapshot? Load()
    {
        if (!File.Exists(SharedFilePath)) return null;

        try
        {
            using var stream = new FileStream(SharedFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            return JsonSerializer.Deserialize<AppStateSnapshot>(stream, jsonOptions);
        }
        catch (IOException)
        {
            return null;
        }
        catch (JsonException)
        {
            return null;
        }
    }

    public DateTime? LastWriteTimeUtc()
    {
        try
        {
            return File.Exists(SharedFilePath) ? File.GetLastWriteTimeUtc(SharedFilePath) : null;
        }
        catch (IOException)
        {
            return null;
        }
    }

    public bool Save(AppStateSnapshot snapshot, out string error)
    {
        error = "";
        try
        {
            var directory = Path.GetDirectoryName(SharedFilePath)!;
            Directory.CreateDirectory(directory);
            var temporaryPath = SharedFilePath + ".tmp";
            var json = JsonSerializer.Serialize(snapshot, jsonOptions);
            File.WriteAllText(temporaryPath, json);

            if (File.Exists(SharedFilePath))
            {
                File.Replace(temporaryPath, SharedFilePath, null);
            }
            else
            {
                File.Move(temporaryPath, SharedFilePath);
            }
            return true;
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            error = exception.Message;
            return false;
        }
    }

    public void ConfigureSharedFile(string path)
    {
        SharedFilePath = Path.GetFullPath(path);
        var configured = new ConfiguredPath { SharedFilePath = SharedFilePath };
        File.WriteAllText(settingsPath, JsonSerializer.Serialize(configured, jsonOptions));
    }

    private string? ReadConfiguredPath()
    {
        try
        {
            if (!File.Exists(settingsPath)) return null;
            var configured = JsonSerializer.Deserialize<ConfiguredPath>(File.ReadAllText(settingsPath), jsonOptions);
            return string.IsNullOrWhiteSpace(configured?.SharedFilePath) ? null : configured.SharedFilePath;
        }
        catch
        {
            return null;
        }
    }

    private static string? FindOneDriveRoot()
    {
        var candidates = new[]
        {
            Environment.GetEnvironmentVariable("OneDriveCommercial"),
            Environment.GetEnvironmentVariable("OneDriveConsumer"),
            Environment.GetEnvironmentVariable("OneDrive")
        }.Where(path => !string.IsNullOrWhiteSpace(path));

        foreach (var candidate in candidates)
        {
            if (Directory.Exists(candidate)) return candidate!;
        }

        var profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        try
        {
            return Directory.GetDirectories(profile, "OneDrive*", SearchOption.TopDirectoryOnly)
                .OrderByDescending(path => path.Contains("TUM", StringComparison.OrdinalIgnoreCase))
                .FirstOrDefault();
        }
        catch (IOException)
        {
            return null;
        }
    }

    private sealed class ConfiguredPath
    {
        public string SharedFilePath { get; set; } = "";
    }
}
