# 付费墙与转化漏斗

> 目标：投流获客 → 占据心智 → App 内付费墙引导订阅 → ROI 打正

---

## 一、用户旅程总览

```
新用户安装
    → 引导（Onboarding）：3 步（扫卡价值 → 估值价值 → 付费墙）
    → 主 App（Tab：Home / Explore / Scan / Collection / Profile）
    → 核心行为：扫描识别 → 结果页 → 详情 / 加收藏
    → 各环节触达付费墙
```

---

## 二、付费墙触发点（PaywallSource）

| Source | 触发场景 | 触发位置（代码） | 展示形式 | 是否可关闭 |
|--------|----------|------------------|----------|------------|
| **onboarding** | 新用户完成引导第 1、2 步后进入付费页 | `OnboardingView` 第 3 步 = PaywallView | TabView 内嵌页 | 取决于 paywallVariant |
| **featureLimit** | 免费额度用尽 | 见下表 | Sheet | 取决于 variant |
| **valueUnlock** | 想用「高级功能」但未订阅 | 见下表 | Sheet | 是（soft / valueUnlock） |
| **profile** | 个人页主动点「Upgrade to Pro」或订阅入口 | `ProfileView` | Sheet | 是 |

---

## 三、各触发点明细

### 1. Onboarding 付费墙（onboarding）

- **路径**：App 首次启动 → `OnboardingView` → Step0 扫卡价值 → Step1 估值价值 → Step2 = Paywall（可 Skip 直达）
- **文案**：`"Start with a 3-day free trial and unlock all premium features from day one."`
- **变体**：`paywallVariant` = soft / hard（50/50 分桶），影响是否显示关闭按钮
- **完成**：订阅或关闭 → `completeOnboarding()` → 进入主 App

### 2. 功能限制（featureLimit）

免费额度用尽时，**阻断式**弹出付费墙：

| 触发动作 | 判断逻辑 | 代码位置 |
|----------|----------|----------|
| 点击底部「扫描」按钮 | `canStartScanFlow()` → `!subscription.canScanToday()` | `AppState.canStartScanFlow()` |
| 扫描结果页点击「Add to Collection」 | `!subscription.canAddToCollection(currentCount)` | `AppState.addToCollection()`、`ScanResultView` 按钮 |
| 结果页「Add to Collection」前置判断 | `isCollectionLimitReached` | `ScanResultView.actionButtons` |

**免费额度**（`SubscriptionState`）：

- 每日扫描：3 次（`freeDailyScanLimit = 3`）
- 收藏夹：20 张（`freeCollectionLimit = 20`）

### 3. 价值解锁（valueUnlock）

用户**已进入功能入口**，但该功能需 Pro 时，用「解锁」引导订阅（非阻断，可关）：

| 触发动作 | 判断逻辑 | 代码位置 |
|----------|----------|----------|
| 扫描页选择「AI 鉴定」模式并拍照 | `!subscription.hasGradeAssessment()` | `ScanView.capturePhoto(mode: .ai)` |
| 结果页看到锁定价格区，点「Unlock Full Valuation」 | 未订阅时展示 `lockedPriceBox` | `ScanResultView.lockedPriceBox` |
| 详情页看到锁定估值区，点「Unlock Full Valuation」 | 未订阅时展示 `lockedValuationSection` | `CardDetailView.lockedValuationSection` |

**Pro 独占能力**：`hasFullValuation` / `hasPriceChart` / `hasGradeAssessment` 等均为 `isPro`。

### 4. Profile 主动升级（profile）

- **路径**：Profile → 头像卡「Upgrade to Pro」或菜单「Subscription」
- **逻辑**：`appState.presentPaywall(source: .profile)`，无额度判断，纯主动触达。

---

## 四、漏斗层级（建议指标）

按「投流 → 订阅」可拆成：

| 层级 | 指标 | 说明 |
|------|------|------|
| 1. 获客 | 安装量 / 注册量 | 投流带来的进量 |
| 2. 激活 | 完成 Onboarding 比例、首扫比例 | 是否用起来 |
| 3. 触达付费墙 | 各 source 的展示次数 / 展示人数 | onboarding / featureLimit / valueUnlock / profile |
| 4. 转化 | 付费墙 → 订阅转化率（按 source 分） | 哪个场景转化最好 |
| 5. 回本 | CAC vs LTV、首月/首单回本周期 | 打正 ROI 的核心 |

建议优先拆 **source 维度** 的「展示 → 订阅」转化，优化高展示、低转化的场景（文案/时机/变体）。

---

## 五、当前实现要点（代码锚点）

- **付费墙展示**：`AppState.showingPaywall` + `activePaywallSource`，由 `MainTabView` 的 `.sheet(isPresented: $state.showingPaywall)` 统一展示 `PaywallView`。
- **订阅能力**：`SubscriptionState`（tier、canScanToday、canAddToCollection、hasFullValuation、hasGradeAssessment 等）。
- **Paywall 文案**：`PaywallView` 内按 `source` 切换 `headerSubtitle`；按 `variant` 与 `source` 决定 `shouldShowCloseButton`。

---

## 六、可选优化方向（便于打正 ROI）

1. **Onboarding**：A/B 测试 paywall 在第 2 步后强制出现 vs 可跳过；测 soft/hard 对首订率的影响。
2. **featureLimit**：当日 3 次扫完后，在结果页或 Tab 上提前提示「今日免费次数已用完，升级可无限扫」，再点扫描时弹付费墙，减少「懵着被挡」。
3. **valueUnlock**：在结果页首屏弱化「锁」、强化「已识别，解锁看价格与走势」的动机；详情页同理。
4. **profile**：订阅页补充「已用次数 / 收藏数」与 Pro 对比，强化升级理由。
5. **埋点**：为每个 `presentPaywall(source:)` 打展示事件，订阅成功打 source；算各 source 的展示→订阅转化与 LTV，指导投放与产品取舍。

---

## 七、埋点事件列表

以下事件用于漏斗分析、付费墙转化与 ROI 归因。命名建议：`对象_动作`，属性尽量统一便于筛选/分组。

### 7.1 应用与会话

| 事件名 | 触发时机 | 建议属性 |
|--------|----------|----------|
| `app_install` | 首次启动（或首次完成 Onboarding 后） | `channel`（投放渠道）, `campaign` |
| `app_launch` | 每次冷/热启动进入 App | — |
| `onboarding_start` | 进入 Onboarding 第一屏 | — |
| `onboarding_step_view` | 每进入一步 | `step` (0=扫卡价值, 1=估值价值, 2=付费墙), `total_steps` |
| `onboarding_step_next` | 点击 Continue / Get Started | `step` |
| `onboarding_skip_to_paywall` | 点击 Skip 跳到付费墙 | `from_step` |
| `onboarding_complete` | 完成引导进入主 App（订阅或关闭付费墙） | `completed_via` (subscribe / dismiss) |

### 7.2 付费墙

| 事件名 | 触发时机 | 建议属性 |
|--------|----------|----------|
| `paywall_impression` | 付费墙展示（含 Onboarding 内嵌、Sheet 弹出） | `source` (onboarding / featureLimit / valueUnlock / profile), `variant` (soft / hard), `placement` (onboarding_step / sheet) |
| `paywall_dismiss` | 用户关闭付费墙未订阅 | `source`, `variant`, `time_visible_sec`（可选） |
| `paywall_cta_click` | 点击主 CTA（如 Start 3-Day Free Trial / Unlock Lifetime） | `source`, `variant`, `plan` (monthly / yearly / lifetime) |
| `paywall_restore_click` | 点击 Restore Purchase | `source` |
| `paywall_plan_change` | 切换月/年/终身选项 | `plan` |

### 7.3 订阅与付费

| 事件名 | 触发时机 | 建议属性 |
|--------|----------|----------|
| `subscription_start_trial` | 成功发起试用（本地或 IAP 回调） | `plan` (monthly / yearly), `trial_days` |
| `subscription_subscribe` | 完成订阅（含试用开始、直接买断） | `plan`, `is_trial` (bool), `source`（来自哪次 paywall_impression 的 source） |
| `subscription_restore_success` | 恢复购买成功 | — |
| `subscription_restore_fail` | 恢复购买失败 | `error`（可选） |

### 7.4 核心行为（漏斗与额度）

| 事件名 | 触发时机 | 建议属性 |
|--------|----------|----------|
| `scan_button_click` | 底部 Tab 点击扫描按钮 | `can_scan_today` (bool), `remaining_free_scans`（免费时） |
| `scan_flow_blocked` | 因额度不足被拦截并弹付费墙 | `reason` (daily_limit / 预留), `source` = featureLimit |
| `scan_capture` | 拍照完成，进入识别 | `mode` (normal / ai) |
| `scan_identify_success` | 识别成功出结果 | `mode`, `has_match` (bool) |
| `scan_identify_fail` | 识别失败/未匹配 | `mode` |
| `result_view` | 扫描结果页展示 | `mode`, `has_match`, `is_pro` |
| `result_add_to_collection_click` | 点击「Add to Collection」 | `already_added`, `at_collection_limit` (bool) |
| `result_add_to_collection_blocked` | 因收藏上限弹付费墙 | `source` = featureLimit |
| `result_unlock_valuation_click` | 结果页点击「Unlock Full Valuation」 | `source` = valueUnlock |
| `detail_view` | 卡片详情页展示 | `card_id`（可选）, `is_pro` |
| `detail_unlock_valuation_click` | 详情页点击「Unlock Full Valuation」 | `source` = valueUnlock |
| `scan_ai_mode_blocked` | 选 AI 鉴定但因未订阅弹付费墙 | `source` = valueUnlock |

### 7.5 Profile 与设置

| 事件名 | 触发时机 | 建议属性 |
|--------|----------|----------|
| `profile_upgrade_click` | 点击「Upgrade to Pro」或订阅入口 | `source` = profile |
| `profile_subscription_click` | 菜单项「Subscription」点击 | — |

---

### 7.6 使用说明与衍生指标

- **付费墙转化**：同一会话内 `paywall_impression`（按 `source`）→ `subscription_subscribe`，算各 source 的 **展示 → 订阅** 转化率。
- **归因**：`subscription_subscribe` 带上最近一次 `paywall_impression.source`，便于算各触达场景的 LTV 与 ROI。
- **额度与阻断**：`scan_flow_blocked` / `result_add_to_collection_blocked` 计数可看 featureLimit 触达频次，结合 `paywall_impression(source=featureLimit)` 与 `subscription_subscribe` 评估该场景价值。
- **可选通用属性**：所有事件可统一加 `session_id`、`user_id`（若已登录）、`is_pro`、`platform`、`app_version`，便于筛选与留存分析。
