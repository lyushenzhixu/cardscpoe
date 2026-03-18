# CardScope 管理后台 PRD

> 版本：1.0 | 作者：CardScope Team | 日期：2026-03-18
> 状态：Draft

---

## 一、产品概述

### 1.1 背景

CardScope 是一款 AI 驱动的体育卡牌扫描识别 App，已具备完整的 iOS 客户端、Supabase (PostgreSQL) 后端和 Python 自动化数据爬虫系统。随着用户量和数据量增长，运营团队需要一个管理后台来：

- 实时监控业务指标（用户增长、付费转化、数据质量）
- 管理用户账号与订阅状态
- 维护卡片数据库（球员、卡片、系列）
- 分析付费漏斗与营收趋势

### 1.2 目标

| 目标 | 衡量标准 |
|------|---------|
| 运营效率提升 | 数据查询/操作耗时降低 80%（相比直接操作数据库） |
| 数据质量保障 | 卡片数据异常发现时间 < 1 小时 |
| 业务洞察 | 核心指标可实时查看，无需手动拉数 |
| 付费优化 | 漏斗转化数据按 source/variant 可拆解 |

### 1.3 核心用户

| 角色 | 职责 | 核心诉求 |
|------|------|---------|
| 运营团队 | 日常数据维护、用户问题处理 | 快速查改用户/卡片数据 |
| 产品团队 | 功能迭代决策、转化优化 | 看板指标、漏斗分析、A/B 结果 |
| 数据团队 | 数据质量监控、管道维护 | 数据入库统计、异常告警 |

### 1.4 技术选型建议

| 层 | 推荐方案 | 说明 |
|---|---------|------|
| 前端 | Next.js + Tailwind + shadcn/ui | React 生态，组件丰富 |
| 后端 | Supabase（现有）+ Edge Functions | 复用现有基础设施 |
| 认证 | Supabase Auth（邮箱+角色） | 内置 RLS 策略 |
| 部署 | Vercel | 与 Next.js 原生集成 |

---

## 二、核心板块 PRD（V1）

### 2.1 Dashboard 仪表盘

#### 概述

管理后台首页，一屏展示核心业务健康度指标，支持时间范围切换（今日 / 7 日 / 30 日 / 自定义）。

#### 2.1.1 顶部 KPI 卡片

| 指标 | 定义 | 数据源 | 展示形式 |
|------|------|--------|---------|
| 总用户数 | 注册用户总量 | `auth.users` COUNT | 数字 + 较上周期变化率 |
| 日活 (DAU) | 当日启动 App 的去重用户 | 事件表 `app_launch` 去重 user_id | 数字 + 趋势箭头 |
| 付费用户数 | 当前有效订阅用户 | 订阅表 tier != 'free' | 数字 + 付费率% |
| 月营收 (MRR) | 当月订阅收入合计 | 订阅表按 plan 计算 | 金额 + 环比变化 |
| 总卡片数 | `cards` 表记录数 | `cards` COUNT | 数字 |
| 今日扫描量 | 当日扫描事件数 | `scan_history` WHERE date = today | 数字 + 昨日对比 |

#### 2.1.2 趋势图表

| 图表 | 类型 | X 轴 | Y 轴 | 数据源 |
|------|------|------|------|--------|
| 用户增长趋势 | 折线图 | 日期 | 新增/累计用户 | `auth.users` 按 created_at 聚合 |
| 扫描量趋势 | 柱状图 | 日期 | 扫描次数 | `scan_history` 按日聚合 |
| 订阅转化漏斗 | 漏斗图 | 步骤 | 人数/转化率 | 事件表漏斗计算 |
| 收入趋势 | 面积图 | 日期 | 收入金额 | 订阅事件按日聚合 |
| 运动类型分布 | 饼图 | — | 占比 | `cards` GROUP BY sport |

#### 2.1.3 快速入口

- 最近注册的 5 个用户（链接到用户详情）
- 最近 5 次数据管道执行状态（成功/失败/运行中）
- 数据质量告警（缺失价格的卡片数、过期数据比例）

---

### 2.2 用户管理

#### 概述

管理所有 CardScope 用户，支持查看详情、修改订阅状态、处理用户反馈。

#### 2.2.1 用户列表页

**筛选条件**：

| 筛选项 | 类型 | 选项 |
|--------|------|------|
| 订阅状态 | 多选 | Free / Pro Monthly / Pro Yearly / Lifetime |
| 注册时间 | 日期范围 | 起止日期选择器 |
| 最后活跃 | 日期范围 | 起止日期选择器 |
| Paywall 变体 | 单选 | Soft / Hard |
| 搜索 | 文本 | 模糊匹配 email / user_id |

**列表字段**：

| 字段 | 说明 | 排序 |
|------|------|------|
| 用户 ID | UUID，可复制 | — |
| Email | 注册邮箱 | — |
| 订阅状态 | Badge 显示 tier | 支持 |
| Paywall 变体 | Soft / Hard | 支持 |
| 注册时间 | YYYY-MM-DD HH:mm | 支持（默认降序） |
| 最后活跃 | YYYY-MM-DD HH:mm | 支持 |
| 扫描次数 | 累计扫描总数 | 支持 |
| 收藏数 | 收藏卡片数量 | 支持 |

**操作**：
- 查看详情
- 批量导出 CSV

#### 2.2.2 用户详情页

**基本信息区**：

| 字段 | 说明 |
|------|------|
| 用户 ID | UUID |
| Email | 注册邮箱 |
| 注册时间 | 首次注册时间 |
| 最后活跃 | 最近一次 app_launch |
| 设备信息 | 机型 / 系统版本 / App 版本 |

**订阅信息区**：

| 字段 | 说明 | 可编辑 |
|------|------|--------|
| 当前套餐 | Free / Pro Monthly / Pro Yearly / Lifetime | 是（下拉选择） |
| Paywall 变体 | Soft / Hard | 是（下拉选择） |
| 试用状态 | 试用中 / 已过期 / 未试用 | — |
| 试用到期时间 | trialEndAt | 是（日期选择器） |
| 订阅开始时间 | 最近一次订阅时间 | — |
| 订阅来源 | onboarding / featureLimit / valueUnlock / profile | — |

**使用数据区**：

| 数据 | 展示形式 |
|------|---------|
| 扫描历史 | 列表：日期 / 识别结果（成功/失败）/ 匹配卡片 |
| 收藏列表 | 列表：卡片名 / 当前价格 / 添加时间 |
| 每日扫描量 | 近 30 天柱状图 |
| 付费墙触达记录 | 列表：时间 / source / 结果（订阅/关闭） |

**操作按钮**：
- 修改订阅状态（含确认弹窗）
- 重置每日扫描次数
- 赠送试用天数

---

### 2.3 卡片数据管理

#### 概述

管理 Supabase 中的 `players`、`cards`、`prices`、`price_summary` 数据，支持 CRUD、批量操作和数据质量监控。

#### 2.3.1 球员管理

**列表字段**：

| 字段 | 类型 | 筛选 | 排序 |
|------|------|------|------|
| ID | uuid | — | — |
| 姓名 (name) | text | 搜索 | 支持 |
| 运动 (sport) | text | 多选：NBA / MLB / NFL / Soccer | 支持 |
| 球队 (team) | text | 搜索 | 支持 |
| 位置 (position) | text | — | — |
| 头像 (headshot_url) | thumbnail | 有/无 | — |
| 关联卡片数 | integer (JOIN cards) | — | 支持 |

**操作**：
- 新增球员
- 编辑球员信息（姓名、球队、位置、头像 URL、简介）
- 删除球员（级联检查：如有关联卡片则阻止删除）
- 批量导入（CSV 上传）

**球员详情**：
- 基本信息编辑表单
- 关联卡片列表（链接到卡片详情）

#### 2.3.2 卡片管理

**列表字段**：

| 字段 | 类型 | 筛选 | 排序 |
|------|------|------|------|
| ID | uuid | — | — |
| 球员 (player_name) | text | 搜索 | 支持 |
| 运动 (sport) | text | 多选 | 支持 |
| 品牌 (brand) | text | 多选：Panini / Topps / Upper Deck | 支持 |
| 系列 (set_name) | text | 搜索 | 支持 |
| 年份 (year) | text | 范围选择 | 支持 |
| 卡号 (card_number) | text | 搜索 | — |
| 平行版 (parallel) | text | 多选：Base / Silver / Gold / Black 等 | 支持 |
| 新秀卡 (is_rookie) | boolean | 是/否 | — |
| 当前价格 (current_price) | integer | 范围 | 支持（默认降序） |
| 涨跌幅 (price_change) | double | — | 支持 |
| 置信度 (confidence) | double | 范围 | 支持 |

**卡片详情/编辑表单**：

| 分组 | 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| 基本信息 | player_id | 下拉（关联 players） | 是 | 选择球员 |
| | player_name | 自动填充 | 是 | 随 player_id 自动填入 |
| | sport | 自动填充 | 是 | 随球员自动填入 |
| | team | 自动填充 | 是 | 随球员自动填入 |
| | position | 自动填充 | 是 | 随球员自动填入 |
| 卡片属性 | brand | 下拉 | 是 | Panini / Topps / Upper Deck |
| | set_name | 下拉（联动 brand） | 是 | Prizm / Chrome 等 |
| | year | 下拉 | 是 | 2017–2026 |
| | card_number | 文本 | 是 | |
| | parallel | 下拉 | 是 | Base / Silver / Gold / Black 等 |
| | is_rookie | 开关 | — | |
| 价格信息 | raw_price_low | 整数 | 是 | Raw 价格下限 ($) |
| | raw_price_high | 整数 | 是 | Raw 价格上限 ($) |
| | psa9_price_low | 整数 | 是 | PSA 9 价格下限 ($) |
| | psa9_price_high | 整数 | 是 | PSA 9 价格上限 ($) |
| | psa10_price_low | 整数 | 是 | PSA 10 价格下限 ($) |
| | psa10_price_high | 整数 | 是 | PSA 10 价格上限 ($) |
| | current_price | 整数 | 是 | 当前市场价 ($) |
| | price_change | 浮点 | — | 30 天涨跌幅 (%) |
| | confidence | 浮点 | — | 价格置信度 (0–100) |
| 媒体 | image_url | URL | — | 卡片图片 |
| | headshot_url | URL | — | 球员头像 |

**表单校验规则**：
- 价格区间：`raw_low ≤ raw_high ≤ psa9_low ≤ psa9_high ≤ psa10_low ≤ psa10_high`
- `current_price` > 0
- `confidence` ∈ [0, 100]
- URL 格式校验

**批量操作**：
- 批量删除（勾选多行）
- 批量修改平行版
- 批量导入（CSV 上传，字段映射 + 预览 + 确认）
- 批量导出 CSV

#### 2.3.3 系列管理

**列表字段**（聚合自 `cards` 表）：

| 字段 | 说明 | 排序 |
|------|------|------|
| 品牌 (brand) | Panini / Topps 等 | 支持 |
| 系列 (set_name) | Prizm / Chrome 等 | 支持 |
| 年份 (year) | 年份 | 支持 |
| 卡片数量 | COUNT(cards) | 支持（默认降序） |
| 平均价格 | AVG(current_price) | 支持 |
| 最高价格 | MAX(current_price) | 支持 |

**操作**：
- 点击系列名 → 展开该系列下所有卡片
- 系列级别的批量操作（如：整系列下架）

#### 2.3.4 价格数据管理

**成交记录列表**（`prices` 表）：

| 字段 | 类型 | 筛选 |
|------|------|------|
| 关联卡片 | 链接 | 搜索 |
| 评级条件 (condition) | text | 多选：Raw / PSA 9 / PSA 10 / BGS 9.5 / SGC 9/10 |
| 成交价 (sale_price) | numeric | 范围 |
| 成交日期 (sale_date) | date | 日期范围 |
| 来源 (source) | text | 多选 |
| 原始链接 (source_url) | URL | — |

**价格汇总**（`price_summary` 表）：

| 字段 | 说明 |
|------|------|
| 关联卡片 | 链接到卡片详情 |
| 评级条件 | Raw / PSA 9 / PSA 10 等 |
| 30 天均价 | avg_price_30d |
| 30 天中位价 | median_price_30d |
| 30 天最低/最高 | min/max_price_30d |
| 30 天销量 | total_sales_30d |
| 价格趋势 | price_trend_pct (%) |
| 最后更新 | last_updated |

#### 2.3.5 数据质量面板

| 监控项 | 阈值 | 展示 |
|--------|------|------|
| 缺失价格的卡片 | current_price = 0 或 NULL | 数量 + 占比 + 链接列表 |
| 价格区间异常 | raw_high > psa9_low 等违反排序 | 数量 + 链接列表 |
| 缺失图片的卡片 | image_url = NULL | 数量 + 占比 |
| 无关联球员的卡片 | player_id = NULL | 数量 + 链接列表 |
| 过期价格汇总 | last_updated > 7 天 | 数量 + 占比 |
| 孤立球员 | 无关联卡片的球员 | 数量 + 链接列表 |

---

### 2.4 订阅与营收

#### 概述

展示订阅相关的核心数据，包括订阅分布、付费墙漏斗、A/B 测试结果和收入趋势，为付费策略优化提供数据支撑。

#### 2.4.1 订阅总览

**KPI 卡片**：

| 指标 | 定义 | 计算方式 |
|------|------|---------|
| 总付费用户 | 当前有效订阅用户数 | tier IN ('proMonthly', 'proYearly', 'lifetime') |
| 付费率 | 付费用户 / 总用户 | 上述 / auth.users COUNT |
| MRR | 月度经常性收入 | monthly × $X + yearly × $Y/12 |
| ARPU | 每用户平均收入 | MRR / 总活跃用户 |
| 试用转化率 | 试用→正式订阅比例 | 统计 trial → paid 转化 |
| 流失率 (Churn) | 当月取消/过期用户占比 | 当月流失 / 上月付费用户 |

**订阅分布**：

| 图表 | 类型 | 说明 |
|------|------|------|
| 套餐分布 | 饼图 | Free / Pro Monthly / Pro Yearly / Lifetime 占比 |
| 订阅趋势 | 堆叠面积图 | 各套餐用户数随时间变化 |
| 新增 vs 流失 | 双柱图 | 每日/周新增订阅 vs 取消订阅 |

#### 2.4.2 付费墙漏斗分析

基于现有 PaywallSource 体系（参见 `paywall-funnel.md`），拆解各触发场景的转化效果。

**漏斗视图**（按 source 分组）：

| 步骤 | 指标 | 数据来源 |
|------|------|---------|
| 1. 触达 | paywall_impression 次数 / 人数 | 事件表 |
| 2. CTA 点击 | paywall_cta_click 次数 | 事件表 |
| 3. 订阅成功 | subscription_subscribe 次数 | 事件表 |
| 4. 转化率 | 步骤 3 / 步骤 1 | 计算值 |

**支持维度**：

| 维度 | 说明 |
|------|------|
| Source | onboarding / featureLimit / valueUnlock / profile |
| Variant | soft / hard |
| Plan | monthly / yearly / lifetime |
| 时间范围 | 7 日 / 30 日 / 90 日 / 自定义 |

**漏斗对比表**：

| Source | 展示次数 | 展示人数 | CTA 点击 | 订阅数 | 转化率 | 趋势 |
|--------|---------|---------|---------|--------|--------|------|
| onboarding | — | — | — | — | —% | ↑/↓ |
| featureLimit | — | — | — | — | —% | ↑/↓ |
| valueUnlock | — | — | — | — | —% | ↑/↓ |
| profile | — | — | — | — | —% | ↑/↓ |

#### 2.4.3 A/B 测试结果

展示 `paywallVariant`（soft vs hard）对转化的影响。

**对比看板**：

| 指标 | Soft 组 | Hard 组 | 差异 | 显著性 |
|------|---------|---------|------|--------|
| 样本量 | — | — | — | — |
| Paywall 展示次数 | — | — | — | — |
| 订阅转化率 | —% | —% | —pp | p-value |
| 试用开始率 | —% | —% | —pp | p-value |
| 7 日留存 | —% | —% | —pp | p-value |
| ARPU | $— | $— | $— | p-value |

**时间趋势**：soft vs hard 转化率折线图，可按 source 下钻。

#### 2.4.4 收入分析

| 图表 | 类型 | 说明 |
|------|------|------|
| 日/周/月收入趋势 | 折线图 | 总收入 + 按 plan 拆分 |
| 收入来源分布 | 堆叠柱状图 | 按首次 paywall source 归因 |
| LTV 分布 | 直方图 | 用户生命周期价值分布 |
| CAC vs LTV | 散点图（需投放数据接入） | 各渠道获客成本对比 LTV |

**关键指标表**：

| 指标 | 定义 |
|------|------|
| 日收入 | 当日新增订阅收入 |
| 周收入 | 近 7 天收入合计 |
| 月收入 (MRR) | 当月经常性收入 |
| 年化收入 (ARR) | MRR × 12 |
| 首月回本率 | 首月收入 ≥ CAC 的用户占比 |

---

## 三、后续迭代板块（V2）

### 3.1 数据管道监控

监控 Python 数据爬虫（`scraper/`）的运行状态。

| 功能 | 说明 |
|------|------|
| 执行历史 | 每次 `main.py` 运行的时间、参数、结果（成功/失败） |
| 入库统计 | players / cards / prices / summaries 各表入库数量 |
| 错误日志 | 各爬虫模块的失败详情（API 超时、解析错误等） |
| 手动触发 | 一键触发数据更新，可选参数（--sport / --skip-ebay） |
| 定时任务 | 配置 cron 计划，查看下次执行时间 |

### 3.2 扫描分析

分析用户扫描行为和识别系统性能。

| 功能 | 说明 |
|------|------|
| 扫描成功率趋势 | 按日统计 matched / total |
| 平均识别耗时 | OCR + 匹配的端到端耗时 |
| 失败扫描列表 | OCR 文本、匹配分数，辅助排查 |
| 热门扫描卡片 | 被扫描最多的卡片 Top 20 |
| 匹配分数分布 | 直方图：分析阈值是否合理 |

### 3.3 内容管理

管理 App 内展示内容。

| 功能 | 说明 |
|------|------|
| 热门推荐配置 | 手动置顶/调整 trending_snapshot 数据 |
| Banner 管理 | Home 页轮播图配置 |
| Paywall 文案管理 | 各 source 的标题/副标题/CTA 文案编辑 |
| App 公告 | 维护通知、版本更新提示 |

### 3.4 系统设置

| 功能 | 说明 |
|------|------|
| 管理员账号管理 | 邀请/禁用管理员 |
| 角色权限配置 | 自定义角色和权限组合 |
| 操作审计日志 | 谁在什么时间做了什么操作 |
| API Key 管理 | 管理外部服务（eBay、PriceCharting）的 Key |
| 功能开关 | 远程控制 App 功能（如关闭 AI 评级） |

### 3.5 价格行情

| 功能 | 说明 |
|------|------|
| 市场大盘指数 | 按运动类型的整体价格走势 |
| 涨跌排行榜 | 涨幅/跌幅 Top 20 卡片 |
| 价格异常检测 | 单日波动 > 50% 的卡片告警 |
| 数据源对比 | eBay vs 内置价格的差异分析 |

---

## 四、数据模型参考

### 4.1 现有 Supabase 表结构

管理后台直接读写以下已有表，**不需要新增主要业务表**：

```
players (1) ──────── (N) cards
                          │
                          ├── (N) prices
                          ├── (1) price_summary (per condition)
                          ├── (N) user_collections
                          └── (N) scan_history

trending_snapshot (独立预计算表)
```

#### players 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | 主键 |
| name | text NOT NULL | 球员姓名 |
| sport | text NOT NULL | NBA / MLB / NFL / Soccer |
| team | text | 所属球队 |
| position | text | 场上位置 |
| headshot_url | text | 头像 URL |
| bio | text | 个人简介 |

#### cards 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | 主键 |
| player_id | uuid FK → players | 关联球员 |
| player_name | text | 球员姓名（冗余，便于查询） |
| team | text | 球队 |
| position | text | 位置 |
| sport | text | 运动类型 |
| brand | text | 品牌：Panini / Topps / Upper Deck |
| set_name | text | 系列：Prizm / Chrome 等 |
| year | text | 年份 |
| card_number | text | 卡号 |
| parallel | text | 平行版：Base / Silver / Gold / Black |
| is_rookie | boolean | 是否新秀卡 |
| raw_price_low | integer | Raw 价格下限 ($) |
| raw_price_high | integer | Raw 价格上限 ($) |
| psa9_price_low | integer | PSA 9 价格下限 ($) |
| psa9_price_high | integer | PSA 9 价格上限 ($) |
| psa10_price_low | integer | PSA 10 价格下限 ($) |
| psa10_price_high | integer | PSA 10 价格上限 ($) |
| current_price | integer | 当前市场价 ($) |
| price_change | double | 30 天涨跌幅 (%) |
| confidence | double | 价格置信度 |
| grade | text | 评级 |
| image_url | text | 卡片图片 URL |
| headshot_url | text | 球员头像 URL |

#### prices 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | 主键 |
| card_id | uuid FK → cards | 关联卡片 |
| condition | text | 评级条件：Raw / PSA 9 / PSA 10 / BGS 9.5 / SGC 9/10 |
| sale_price | numeric(10,2) | 成交价格 |
| sale_date | date | 成交日期 |
| source | text | 来源（eBay） |
| source_url | text | 原始链接 |
| listing_title | text | 商品标题 |

#### price_summary 表

| 字段 | 类型 | 说明 |
|------|------|------|
| card_id | uuid PK (复合) | 关联卡片 |
| condition | text PK (复合) | 评级条件 |
| avg_price_30d | numeric | 30 天均价 |
| median_price_30d | numeric | 30 天中位价 |
| min_price_30d | numeric | 30 天最低价 |
| max_price_30d | numeric | 30 天最高价 |
| total_sales_30d | integer | 30 天销量 |
| price_trend_pct | numeric | 价格趋势 (%) |
| last_updated | timestamptz | 最后更新时间 |

#### trending_snapshot 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid PK | 主键 |
| kind | text | 'players' 或 'series' |
| payload | jsonb | 预计算的 JSON 数据 |
| computed_at | timestamptz | 计算时间 |

#### 视图

- **`trending_players_view`** — Top 50 热门球员（按 price_change 排序）
- **`popular_series_view`** — Top 30 热门系列（按 card_count 排序）

### 4.2 管理后台需要新增的表

| 表名 | 用途 | 主要字段 |
|------|------|---------|
| `admin_users` | 管理员账号 | id, email, role, created_at, last_login |
| `admin_audit_log` | 操作审计日志 | id, admin_id, action, target_table, target_id, detail (jsonb), created_at |
| `pipeline_runs` | 数据管道执行记录 | id, started_at, finished_at, status, params (jsonb), stats (jsonb), error_message |
| `analytics_events` | 埋点事件（如未使用第三方） | id, user_id, event_name, properties (jsonb), created_at |
| `subscription_events` | 订阅变更记录 | id, user_id, from_tier, to_tier, source, plan, created_at |

---

## 五、权限设计

### 5.1 角色定义

| 角色 | 说明 | 适用人员 |
|------|------|---------|
| Super Admin | 全部权限，含系统设置和角色管理 | CTO / 技术负责人 |
| Admin | 数据读写权限，不含角色管理和系统配置 | 运营负责人 |
| Operator | 用户管理 + 卡片数据的读写权限 | 日常运营人员 |
| Analyst | 只读权限，所有页面可查看不可修改 | 产品/数据分析人员 |

### 5.2 权限矩阵

| 功能模块 | Super Admin | Admin | Operator | Analyst |
|---------|:-----------:|:-----:|:--------:|:-------:|
| **Dashboard** | | | | |
| 查看 KPI 和图表 | R | R | R | R |
| **用户管理** | | | | |
| 查看用户列表/详情 | R | R | R | R |
| 修改用户订阅状态 | W | W | W | — |
| 重置扫描次数 | W | W | W | — |
| 赠送试用天数 | W | W | W | — |
| 导出用户数据 | W | W | — | — |
| **卡片数据管理** | | | | |
| 查看球员/卡片/价格 | R | R | R | R |
| 新增/编辑球员 | W | W | W | — |
| 新增/编辑卡片 | W | W | W | — |
| 删除球员/卡片 | W | W | — | — |
| 批量导入/导出 | W | W | — | — |
| **订阅与营收** | | | | |
| 查看订阅统计 | R | R | R | R |
| 查看漏斗/A/B 数据 | R | R | R | R |
| 查看收入数据 | R | R | — | R |
| **数据管道** (V2) | | | | |
| 查看执行记录 | R | R | R | R |
| 手动触发管道 | W | W | — | — |
| 配置定时任务 | W | — | — | — |
| **系统设置** (V2) | | | | |
| 管理管理员账号 | W | — | — | — |
| 配置角色权限 | W | — | — | — |
| 查看审计日志 | R | R | — | — |
| 管理 API Key | W | W | — | — |
| 功能开关 | W | W | — | — |

> R = 只读，W = 读写，— = 无权限

### 5.3 技术实现

- 基于 Supabase Auth + RLS (Row Level Security) 实现
- `admin_users` 表存储管理员角色
- 每个 API 请求通过 JWT 中的 role claim 校验权限
- 敏感操作（删除、批量修改）需要二次确认
- 所有写操作记入 `admin_audit_log`

---

## 六、非功能需求

### 6.1 性能

| 指标 | 要求 |
|------|------|
| 页面加载时间 | < 2s（首屏） |
| 列表查询响应 | < 500ms（万级数据量） |
| 图表渲染 | < 1s |
| 批量导入 | 1000 条 < 10s |

### 6.2 兼容性

- 浏览器：Chrome / Safari / Firefox 最新 2 个版本
- 屏幕：最低 1280px 宽度，支持响应式

### 6.3 安全

- HTTPS 强制
- 登录支持 2FA（V2）
- 会话超时：30 分钟无操作自动登出
- 密码策略：8 位以上，含大小写+数字
- 敏感数据脱敏显示（如用户邮箱部分隐藏）

---

## 附录 A：现有数据规模参考

| 表 | 当前记录数 | 说明 |
|---|----------:|------|
| players | 231 | NBA 50 + MLB 80 + NFL 48 + Soccer 53 |
| cards | 1,792 | 真实品牌/系列/年份组合 |
| prices | 10,680 | 多评级条件成交记录 |
| price_summary | 5,706 | 30 天价格汇总 |
| trending_snapshot | 2 | 热门球员 + 热门系列快照 |

## 附录 B：现有订阅体系

| 套餐 | 代码标识 | 说明 |
|------|---------|------|
| Free | `free` | 每日 3 次扫描，收藏上限 20 张 |
| Pro Monthly | `proMonthly` | 无限扫描、完整估值、AI 评级 |
| Pro Yearly | `proYearly` | 同上 + 批量扫描、导出功能 |
| Lifetime | `lifetime` | 同 Pro Yearly，一次买断 |

**Paywall 触发场景**：

| Source | 触发条件 |
|--------|---------|
| onboarding | 新用户引导第 3 步 |
| featureLimit | 每日扫描用尽 / 收藏上限 |
| valueUnlock | 查看完整估值、价格走势、AI 评级 |
| profile | 个人页主动升级 |

**A/B 变体**：`soft`（可关闭）vs `hard`（不可关闭），50/50 本地分桶。

## 附录 C：相关文档

| 文档 | 路径 | 说明 |
|------|------|------|
| 付费墙与转化漏斗 | `docs/paywall-funnel.md` | 付费墙触发逻辑、埋点事件定义 |
| 扫描识别 & AI 评级 PRD | `docs/prd-scan-identify-grade.md` | 核心功能链路详细设计 |
| 数据流水线技术文档 | `docs/data-pipeline.md` | 爬虫架构、数据质量保障、使用方法 |
