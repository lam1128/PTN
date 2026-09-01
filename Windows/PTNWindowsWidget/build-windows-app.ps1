$ErrorActionPreference = "Stop"

$project = Join-Path $PSScriptRoot "PTNWindowsWidget.csproj"
$output = Join-Path $PSScriptRoot "bin\publish"

$sdks = @(dotnet --list-sdks 2>$null)
if ($sdks.Count -eq 0) {
    throw "No .NET SDK detected. Install the .NET 8 SDK, then run this script again."
}

& dotnet publish $project -c Release -r win-x64 --self-contained false -o $output
if ($LASTEXITCODE -ne 0) {
    throw "Windows build failed. The app was not started; check the compiler output above."
}

$executable = Join-Path $output "PTNWindowsWidget.exe"
if (-not (Test-Path $executable)) {
    throw "Build finished but the executable was not found: $executable"
}
Start-Process $executable
