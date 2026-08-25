# PTN

《无期迷途》异方晶 macOS 桌面小组件。

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

- 数据保存在本机。
- 重新打开后会保留上次的位置和记录。

## iPhone 与 iCloud

- 工程同时包含 macOS target 与 `PTNHypercubeWidgetiOS` target。
- iPhone 版本使用 SwiftUI，奖励模型、日期规则和库存逻辑与 Mac 共用。
- Mac 与 iPhone 登录同一 Apple ID 后，通过 `iCloud.com.openai.PTNHypercubeWidget` 的 CloudKit 私有数据库同步库存、领取记录、历史和抽卡规划。
- 首次在 Mac 上运行新版时会将现有本地记录上传；首次在 iPhone 上运行时会下载云端记录。
- CloudKit 需要 Apple 签名权限；在 Xcode 中运行 Mac target，或设置 `CODESIGN_IDENTITY` 后运行构建脚本，才能让 Mac 端获得 iCloud 权限。
- 使用前需要在 Xcode 的 Signing & Capabilities 中选择自己的开发团队；如果该 Bundle ID 或 iCloud 容器已被占用，请将工程、两个 entitlements 文件中的标识符改成自己名下的唯一值，并在 CloudKit 中启用对应容器。

## 来源

- 抽卡规划参考 [S1N Banners](https://s1n.gg/banners)。
- 英文兑换码参考 [S1N 首页](https://s1n.gg/) 的 Gift Codes。
- 网站中未标记为已确认的未来日期属于预测信息，可能随官方公告调整。
