# PTN 开发约定

## 项目结构

- `Models/RewardModels.swift`：奖励、卡池、进度和历史记录的数据模型。
- `RewardEngine/RewardSchedule.swift`：奖励配置、ID、日期锚点和周期规则。
- `RewardEngine/RewardEngine.swift`：根据日期和存档状态生成页面数据，不直接写 UI。
- `Storage/AppStateStore.swift`：UserDefaults 持久化、领取/取消、库存和历史记录。
- `Views/MainWidgetView.swift`：页面布局、固定顺序和交互入口。
- `Package.swift`、`build-standalone-app.sh` 与 `script/assemble_app.sh`：独立构建和 `.app` 打包入口；构建脚本自动收集项目内 Swift 文件，不维护手动源文件清单。

## 卡池数据来源

- 固定来源为 [S1N Banners](https://s1n.gg/banners)，后续更新无需用户重复提供链接。
- 页面数据来自其公开只读 `timeline` 数据，其中 `type = banner`；需要读取 `id`、`title`、`banner`、`sinners`、`start`、`end` 和 `confirmed`。
- 英文兑换码同样来自 S1N 的 `timeline` 数据，使用 `type = Gift Code` 并复用 `GiftCodeStore` 的有效期、英文过滤、缓存和兜底逻辑。
- 兑换码仅在活动池或限定池开池日前后 7 天，于德国时间 08:00、16:00 检查；显示数量必须跟随当前兑换码奖励位，主线/周年庆为 3 条，普通活动为 1 条。
- `confirmed = true` 才视为已确认日期；其余未来日期只作为预测，更新时必须保留可修正能力。
- 卡池每天按德国时间 08:00、16:00 检查，只追加 `confirmed = true` 且本地不存在的新卡池。
- 不直接用远端记录覆盖 `pullPlanBanners`：本地内置卡池永远优先，以卡池类型和橙色角色名为锚点并辅以 S1N 来源 ID 去重，保留现有本地 ID、手动日期、领取键、垫抽分组及派生奖励。
- 自动同步必须提供本地配置兜底；接口不可用、字段缺失或解析失败时继续使用内置卡池，不得清空抽卡规划。

## 新增奖励模块

1. 先在 `RewardSchedule.swift` 增加 `RewardSourceDefinition` 或专用定义的唯一 ID、标题、奖励值和时间配置。
2. 简单勾选奖励优先加入对应的 `RewardSourceDefinition` 数组，并复用 `makeConfiguredRewards`，不要单独编写 `RewardItem` 生成循环。
3. 特殊日期或动态奖励模块保留独立规则，但统一通过 `makeRewardItem` 构造最终奖励条目。
4. 多圆点模块使用 `ProgressModuleDefinition`，同时填写 `kind`、`slotCount`、`slotValue` 和刷新能力。
5. 在 `RewardEngine.swift` 增加一个生成方法，统一通过 `makeProgress` 生成圆点和领取键。
6. 在 `AppStateStore.swift` 增加领取/取消动作；可复用 `toggleStandardProgressSlot`，不要复制库存和历史逻辑。
7. 在 `MainWidgetView.swift` 只增加模块位置和 `ProgressModuleKind` 分流，不在 View 内编写日期规则。
8. 更新 `CHECKLIST.md`；只有用户可见功能才更新 `CHANGELOG.md`。

## 更新日志

- `新增` 只记录全新的模块或功能。
- 已有模块的规则、数值或行为调整统一写入 `优化`。
- 每项保持一句话，只描述用户可见结果，不写库存同步、历史同步、持久化等内部实现细节。
- 不记录布局、颜色、尺寸、顺序、弹窗位置等 UI 调整。

## 必须保持

- 开始修改前先搜索并复用已有模型、配置、共享 View、调色板和存储动作；只有现有代码无法表达需求时才新增实现。
- 模块逻辑相同时直接调用已有定义、生成器、存储动作和共享 View；不要为相同逻辑创建新的函数、组件或数据结构。
- 不要为同一规则新增第二套 ID、颜色、领取逻辑或日期计算；优先扩展已有定义和共享方法。
- 不改已有存档键、领取键和历史来源格式，除非同时提供迁移逻辑。
- 当前模块顺序固定，领取后不沉底；不要按 `isClaimed` 重新排序。
- UI 尺寸、圆圈、颜色和弹窗位置视为锁定内容，除非用户明确要求修改。
- 圆形控件统一将外圈和内部图标分层绘制；微调内部图标只使用图标自身的 `offset`，不得改变外圈的尺寸、位置或命中区域。
- 日期必须使用真实日期、配置时区和明确结束时间，不用“一个月四周”等近似算法。
- 未知日期只保留手动入口，不自动推测或均摊。

## 每次修改后的检查

每次完成代码任务后必须执行 `./build-standalone-app.sh`，关闭旧进程并启动最新版本；不能只编译而不重启。

```bash
git diff --check
./build-standalone-app.sh
```

发布构建使用 `./build-release-app.sh`，生成的 `.app` 可脱离 VS Code 独立运行。编译脚本会关闭旧进程、生成 `dist/PTNHypercubeWidget.app` 并重新打开应用。重点手动检查：圆点点击与取消、密令高级奖励、垫抽数、滚动位置、倒计时、历史撤销和库存变化。
