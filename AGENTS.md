# PTN 开发约定

## 项目结构

- `Models/RewardModels.swift`：奖励、卡池、进度和历史记录的数据模型。
- `RewardEngine/RewardSchedule.swift`：奖励配置、ID、日期锚点和周期规则。
- `RewardEngine/RewardEngine.swift`：根据日期和存档状态生成页面数据，不直接写 UI。
- `Storage/AppStateStore.swift`：UserDefaults 持久化、领取/取消、库存和历史记录。
- `Views/MainWidgetView.swift`：页面布局、固定顺序和交互入口。

## 新增奖励模块

1. 先在 `RewardSchedule.swift` 增加 `RewardSourceDefinition` 或专用定义的唯一 ID、标题、奖励值和时间配置。
2. 多圆点模块使用 `ProgressModuleDefinition`，同时填写 `kind`、`slotCount`、`slotValue` 和刷新能力。
3. 在 `RewardEngine.swift` 增加一个生成方法，统一通过 `makeProgress` 生成圆点和领取键。
4. 在 `AppStateStore.swift` 增加领取/取消动作；可复用 `toggleStandardProgressSlot`，不要复制库存和历史逻辑。
5. 在 `MainWidgetView.swift` 只增加模块位置和 `ProgressModuleKind` 分流，不在 View 内编写日期规则。
6. 更新 `CHECKLIST.md`；只有用户可见功能才更新 `CHANGELOG.md`。

## 必须保持

- 开始修改前先搜索并复用已有模型、配置、共享 View、调色板和存储动作；只有现有代码无法表达需求时才新增实现。
- 不要为同一规则新增第二套 ID、颜色、领取逻辑或日期计算；优先扩展已有定义和共享方法。
- 不改已有存档键、领取键和历史来源格式，除非同时提供迁移逻辑。
- 当前模块顺序固定，领取后不沉底；不要按 `isClaimed` 重新排序。
- UI 尺寸、圆圈、颜色和弹窗位置视为锁定内容，除非用户明确要求修改。
- 日期必须使用真实日期、配置时区和明确结束时间，不用“一个月四周”等近似算法。
- 未知日期只保留手动入口，不自动推测或均摊。

## 每次修改后的检查

```bash
git diff --check
./build-standalone-app.sh
```

编译脚本会关闭旧进程、生成 `dist/PTNHypercubeWidget.app` 并重新打开应用。重点手动检查：圆点点击与取消、密令高级奖励、垫抽数、滚动位置、倒计时、历史撤销和库存变化。
