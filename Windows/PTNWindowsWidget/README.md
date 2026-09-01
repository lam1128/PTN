# PTN Windows Widget

这是 PTN 的 Windows 桌面悬浮版，使用一个 OneDrive JSON 文件与 Mac 版共享库存、领取记录、历史、奖励进度和抽卡规划。

当前 Windows 版包含当前周期、常驻奖励、抽卡规划和抽卡记录四个主区；支持目标角色、锁数、垫抽、每池记录、普池记录、密令高级奖励、N9/N10、兑换码和历史撤销。

## 构建

需要安装 .NET 8 SDK，然后在本目录运行：

```powershell
dotnet build -c Release
dotnet run -c Release
```

程序默认使用 OneDrive 文件夹下的 `PTN\ptn-shared-state.json`。如果自动定位失败，可以在程序底部点击“同步文件”，选择与 Mac 共用的 JSON 文件。

建议同一时间只在一台设备上修改，避免 OneDrive 产生冲突副本。
