# PTN

《无期迷途》异方晶 macOS / Windows 桌面小组件。

## 安装运行

1. 下载仓库源码并进入项目目录。
2. 运行：

```bash
./build-release-app.sh
```

3. 脚本会生成并打开 `dist/PTNHypercubeWidget.app`。
4. 以后可直接双击这个 `.app`，不需要打开 VS Code 或重新编译。
5. 如需移动到应用程序文件夹，可将 `.app` 拖入 macOS 的“应用程序”。

## 备注

- Mac 版继续保留本机 `UserDefaults`，并会将主状态同步到 OneDrive 下的 `PTN/ptn-shared-state.json`。
- 重新打开后会保留上次的位置和记录。

## Windows 版本

- Windows 版本位于 `Windows/PTNWindowsWidget`，是一个可置顶的 WPF 桌面悬浮窗口。
- 需要 .NET 8 SDK；在 Windows 上运行 `Windows/PTNWindowsWidget/build-windows-app.ps1` 即可构建并启动。
- Windows 版支持库存、当前奖励、进度奖励、历史撤销和同步文件选择；卡池规划高级交互仍以 Mac 版为完整版本。
- Mac 与 Windows 必须选择同一个 OneDrive 同步文件，建议同一时间只在一台设备上修改。

## 当前支持范围

- 当前只维护 macOS 和 Windows 版本；iPhone、微信小程序和其他平台不在本次同步方案内。
- Mac 与 Windows 通过 OneDrive 下的同一个 JSON 文件同步，适合个人使用；建议同一时间只在一台设备上修改。

## 来源

- 抽卡规划参考 [S1N Banners](https://s1n.gg/banners)。
- 英文兑换码参考 [S1N 首页](https://s1n.gg/) 的 Gift Codes。
- 网站中未标记为已确认的未来日期属于预测信息，可能随官方公告调整。
