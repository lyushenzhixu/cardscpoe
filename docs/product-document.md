# CardScope 产品文档

> 版本：1.0 | 更新日期：2026-03-16

---

## 一、产品概述

**CardScope** 是一款面向体育球星卡收藏爱好者的 iOS 应用，核心功能为 **扫描识别球星卡并提供实时市场估值**。用户可以通过手机摄像头拍摄实体球星卡，应用会自动识别卡片信息，匹配数据库中的卡片数据，展示当前市场价格、价格趋势和卡片评级分析。

### 目标用户
- 体育球星卡收藏爱好者（入门到进阶）
- 球星卡交易市场参与者
- 对 NBA、MLB、NFL、Soccer 球星卡感兴趣的投资者

### 核心价值主张
- **即拍即估**：拍一张照片，立刻获取卡片估值
- **实时行情**：基于真实市场交易数据的价格追踪
- **智能管理**：数字化收藏管理，随时掌握藏品总价值

---

## 二、功能模块

### 2.1 扫描识别（Scan）

| 项目 | 说明 |
|------|------|
| 入口 | 底部 Tab 栏中央位置 + 首页 Hero 入口 |
| 技术 | Apple Vision 框架 OCR 文字识别 |
| 流程 | 拍照 → 文字提取 → 归一化处理 → 评分匹配 → 返回结果 |
| 匹配逻辑 | 球员名(+4分)、品牌/系列/卡号(+2分)、年份/平行版(+1分)，≥2分判定命中 |
| 结果 | 命中：展示 CardFoundView（完整卡片信息）；未命中：展示 CardNotFoundView |

**免费用户限制**：每日 3 次扫描

### 2.2 探索发现（Explore）

- **搜索栏**：支持按球员名、品牌、系列模糊搜索（ILIKE）
- **热门球员**：横向滚动卡片，展示价格涨幅最高的 Top 50 球员（来源：`trending_players_view`）
- **热门系列**：纵向列表，展示卡片数量最多的 Top 30 系列（来源：`popular_series_view`）

### 2.3 首页仪表盘（Home）

- **扫描入口**：主视觉引导区域
- **资产统计**：收藏总价值、卡片总数、月度涨跌幅
- **最近扫描**：最近识别的卡片列表
- **热门推荐**：趋势卡片推荐

### 2.4 收藏管理（Collection）

- 保存扫描识别后的卡片至个人收藏
- 展示收藏列表及总价值计算
- **免费用户限制**：最多保存 20 张卡片

### 2.5 卡片详情（Card Detail）

- 完整卡片信息：球员、球队、品牌、系列、年份、平行版、卡号
- 价格区间：Raw / PSA 9 / PSA 10 分级价格
- 当前价格及 30 天涨跌幅
- 价格历史走势图
- 近期成交记录

### 2.6 评级分析（Grade）

- AI 驱动的卡片品相分析
- 四维评分：居中度（Centering）、边角（Corners）、边缘（Edges）、表面（Surface）
- 综合评级得分

### 2.7 订阅付费（Subscription）

| 套餐 | 价格 | 权益 |
|------|------|------|
| Free | 免费 | 3次/日扫描、20张收藏上限、基础估值 |
| Pro Monthly | 月付 | 无限扫描、无限收藏、完整估值、价格走势、评级分析 |
| Pro Yearly | 年付 | 同 Pro Monthly |
| Lifetime | 一次性 | 同 Pro，终身有效 |

- 支持 Paywall 变体（Soft / Hard）A/B 测试

### 2.8 用户引导（Onboarding）

- 首次打开 App 展示引导流程
- 引导完成后进入主界面，状态持久化至本地

---

## 三、技术架构

### 3.1 整体架构图

```
┌──────────────────────────────────────────┐
│              iOS App (SwiftUI)           │
│                                          │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐  │
│  │  Views   │ │  State   │ │ Services │  │
│  │(SwiftUI) │ │(Observable)│ │(Business)│  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘  │
│       └─────────────┴─────────────┘       │
│                     │                     │
│         ┌───────────┼───────────┐         │
│         ▼           ▼           ▼         │
│    SwiftData    Vision OCR   URLSession   │
│   (本地缓存)   (文字识别)    (网络请求)    │
└─────────┬───────────────────────┬─────────┘
          │                       │
          ▼                       ▼
    本地持久化              Supabase (云端)
                           ┌──────────────┐
                           │  PostgreSQL   │
                           │  ・players    │
                           │  ・cards      │
                           │  ・prices     │
                           │  ・views      │
                           └──────┬───────┘
                                  │
                           Python 数据管线
                           (爬虫 + 清洗)
```

### 3.2 技术栈

| 层级 | 技术选型 |
|------|----------|
| UI 框架 | SwiftUI |
| 状态管理 | @Observable (Observation framework) |
| 本地持久化 | SwiftData |
| 网络层 | URLSession + 自定义 NetworkManager |
| 文字识别 | Apple Vision (VNRecognizeTextRequest) |
| 后端数据库 | Supabase (PostgreSQL + PostgREST) |
| 数据管线 | Python 3 (requests, BeautifulSoup, supabase-py) |

### 3.3 数据获取策略（三级容灾）

```
Supabase 远程查询
       │
       ├─ 成功 → 返回数据 + 写入本地缓存
       │
       └─ 失败 → SwiftData 本地缓存
                      │
                      ├─ 命中 → 返回缓存数据
                      │
                      └─ 未命中 → Mock 数据兜底
```

---

## 四、数据模型

### 4.1 核心实体

#### Player（球员）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | String | 球员姓名 |
| sport | String | 运动类型 (NBA/MLB/NFL/Soccer) |
| team | String | 所属球队 |
| position | String | 场上位置 |
| headshot_url | String? | 头像 URL |
| bio | String? | 简介 |

#### Card（卡片）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| player_id | UUID (FK) | 关联球员 |
| player_name | String | 球员名（冗余字段） |
| brand | String | 品牌 (Panini / Topps / Upper Deck) |
| set_name | String | 系列名 (Prizm / Select / Chrome 等) |
| year | String | 发行年份 |
| card_number | String? | 卡号 |
| parallel | String? | 平行版名称 |
| is_rookie | Bool | 是否新秀卡 |
| current_price | Double | 当前估价 |
| price_change | Double | 30天涨跌幅 (%) |
| raw_price_low/high | Double | Raw 品相价格区间 |
| psa9_price_low/high | Double | PSA 9 品相价格区间 |
| psa10_price_low/high | Double | PSA 10 品相价格区间 |

#### Price（成交价格）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| card_id | UUID (FK) | 关联卡片 |
| condition | String | 品相 (Raw/PSA 9/PSA 10) |
| sale_price | Double | 成交价 |
| sale_date | Date | 成交日期 |
| source | String | 数据来源 (eBay 等) |

### 4.2 数据库视图

| 视图 | 用途 |
|------|------|
| `trending_players_view` | 按价格涨幅排名的 Top 50 球员 |
| `popular_series_view` | 按卡片数量排名的 Top 30 系列 |
| `trending_snapshot` | 预计算的趋势快照 (JSONB) |

### 4.3 数据规模

| 实体 | 数量 | 来源 |
|------|------|------|
| 球员 | 231 | balldontlie + MLB Stats + ESPN + TheSportsDB |
| 卡片 | 1,792 | 球员 × 品牌 × 系列 × 年份 组合生成 |
| 价格记录 | 10,680+ | eBay 爬取 + 算法生成 |
| 价格摘要 | 5,706 | 30天聚合统计 |

---

## 五、数据管线

### 5.1 管线流程

```
1. 获取球员数据
   ├─ NBA → balldontlie.io API
   ├─ MLB → statsapi.mlb.com
   ├─ NFL → ESPN Public API
   └─ Soccer → TheSportsDB API
         │
2. 清洗球员数据（去重、校验、标准化）
         │
3. 生成卡片目录
   └─ 球员 × 品牌 × 系列 × 年份 × 平行版 = 卡片组合
         │
4. 清洗卡片数据（去重、价格区间校验）
         │
5. 获取/生成价格
   ├─ eBay 已售成交价爬取
   └─ 算法价格生成器（兜底）
         │
6. 计算价格摘要 + 更新卡片价格
         │
7. 导出
   ├─ SQL 文件 → psql 兼容
   ├─ JSON → 调试用
   └─ Supabase REST API → 直接上传
```

### 5.2 支持的卡片品牌/系列

| 运动 | 品牌 | 主要系列 |
|------|------|----------|
| NBA | Panini | Prizm, Select, Donruss, Mosaic, Optic, National Treasures, Flawless |
| NBA | Upper Deck | SP Authentic |
| MLB | Topps | Chrome, Series 1, Bowman, Heritage, Inception |
| MLB | Panini | Prizm, Diamond Kings |
| NFL | Panini | Prizm, Select, Donruss, Mosaic, Optic, National Treasures, Contenders |
| Soccer | Topps | Chrome, Finest, Merlin |
| Soccer | Panini | Prizm, Select, Donruss |

### 5.3 运行命令

```bash
# 完整管线，输出 SQL
python3 main.py --output sql

# 跳过 eBay 爬取（更快）
python3 main.py --skip-ebay --output supabase

# 直接上传至 Supabase
SUPABASE_URL=... SUPABASE_SERVICE_KEY=... python3 main.py --output supabase

# 单一运动
python3 main.py --sport NBA --skip-ebay

# 测试模式（每球员最多3张卡）
python3 main.py --max-cards 3 --skip-ebay --output json
```

---

## 六、设计规范

### 6.1 色彩体系（深色模式）

| 用途 | 色值 | 说明 |
|------|------|------|
| 主背景 | `#000000` | surfacePrimary |
| 悬浮面 | `rgb(26,26,33)` | surfaceElevated |
| 强调色 | `#00FF88` | Cyan 绿（主 CTA） |
| 金色 | `#F5C842` | 高亮/Premium 标识 |
| 紫色 | `#8B5CF6` | 辅助强调 |
| 警告 | `rgb(255,107,53)` | 暖色提示 |

### 6.2 字体

使用系统字体（SF Pro），尺寸规范：
- 大标题：34pt (Bold)
- 标题：24pt (Bold)
- 副标题：18pt (Semibold)
- 正文：16pt (Regular)
- 注释：14pt / 12pt

### 6.3 间距 & 圆角

| Token | 值 |
|-------|----|
| xs | 4pt |
| sm | 8pt |
| md | 16pt |
| lg | 24pt |
| xl | 32pt |
| 圆角 sm | 8pt |
| 圆角 md | 14pt |
| 圆角 lg | 20pt |
| 胶囊 | 999pt |

### 6.4 交互动效

- **NyxPressableStyle**：按压时弹簧缩放动效（0.97）
- **GoldSparkleOverlay**：金色闪粉粒子效果（Premium 场景）
- **LoopingVideoPlayer**：循环背景视频播放

---

## 七、导航结构

```
App 启动
  │
  ├─ 未完成引导 → OnboardingView → 完成后标记持久化
  │
  └─ 已完成引导 → MainTabView (5 个 Tab)
      │
      ├─ 🏠 Home（首页仪表盘）
      │     └→ 点击卡片 → CardDetailView (sheet)
      │
      ├─ 🔍 Explore（探索发现）
      │     ├→ 搜索结果 → CardDetailView
      │     └→ 热门球员/系列 → CardDetailView
      │
      ├─ 📷 Scan（扫描识别）
      │     ├→ 识别成功 → ScanResultView → CardDetailView
      │     └→ 识别失败 → CardNotFoundView
      │
      ├─ 📦 Collection（我的收藏）
      │     └→ 点击卡片 → CardDetailView
      │
      └─ 👤 Profile（个人中心）
            └→ 订阅管理 → PaywallView
```

**弹窗触发**：
- 免费用户达到扫描/收藏上限 → PaywallView
- 卡片详情页点击评级 → GradeView

---

## 八、订阅与商业模型

### 8.1 功能对照表

| 功能 | Free | Pro |
|------|:----:|:---:|
| 每日扫描次数 | 3 | 无限 |
| 收藏卡片上限 | 20 | 无限 |
| 基础估值 | ✅ | ✅ |
| 完整估值（分级价格） | ❌ | ✅ |
| 价格走势图 | ❌ | ✅ |
| 评级分析 | ❌ | ✅ |

### 8.2 Paywall 策略

- **Soft Paywall**：提示升级但允许关闭继续使用
- **Hard Paywall**：必须订阅才能继续操作
- 支持 A/B 测试不同变体以优化转化率

---

## 九、项目文件结构

```
cardscpoe/
├── cardscpoe/                    # iOS 应用源码
│   ├── cardscpoeApp.swift        # App 入口
│   ├── ContentView.swift         # 根视图（引导 / 主界面切换）
│   ├── Models/CardModels.swift   # 核心数据模型
│   ├── Services/                 # 业务逻辑层
│   │   ├── SupabaseClient.swift  # Supabase REST 客户端
│   │   ├── CardService.swift     # 卡片数据服务
│   │   ├── PlayerService.swift   # 球员数据服务
│   │   ├── ScanService.swift     # OCR 扫描识别
│   │   ├── PriceService.swift    # 价格计算
│   │   ├── GradeService.swift    # 评级分析
│   │   ├── NetworkManager.swift  # HTTP 网络层
│   │   └── APIConfig.swift       # API 配置
│   ├── State/                    # 全局状态
│   │   ├── AppState.swift        # 应用状态 (@Observable)
│   │   └── SubscriptionState.swift # 订阅状态 + 功能门控
│   ├── Views/                    # UI 视图
│   │   ├── MainTabView.swift     # Tab 导航
│   │   ├── Home/                 # 首页
│   │   ├── Explore/              # 探索
│   │   ├── Scan/                 # 扫描
│   │   ├── Collection/           # 收藏
│   │   ├── Detail/               # 卡片详情
│   │   ├── Result/               # 扫描结果
│   │   ├── Grade/                # 评级
│   │   ├── Profile/              # 个人中心
│   │   ├── Paywall/              # 付费墙
│   │   ├── Onboarding/           # 新手引导
│   │   └── Components/           # 通用组件
│   ├── Camera/                   # 相机集成
│   ├── Persistence/              # 本地缓存 (SwiftData)
│   ├── Theme/                    # 设计主题
│   └── Config/                   # 配置文件
├── scraper/                      # Python 数据管线
│   ├── main.py                   # 管线入口
│   ├── config.py                 # 品牌/系列配置
│   ├── scrapers/                 # 数据源爬虫
│   ├── cleaners/                 # 数据清洗
│   └── db/                       # 数据库操作
├── docs/                         # 文档
├── supabase/                     # 数据库 Schema & Seeds
└── 项目资料/                     # 项目参考资料
```

---

## 十、覆盖运动 & 数据源

| 运动 | 球员数据 API | 头像来源 |
|------|-------------|----------|
| NBA | balldontlie.io | nba.com CDN |
| MLB | statsapi.mlb.com | MLB Stats API |
| NFL | ESPN Public API | ESPN CDN |
| Soccer | TheSportsDB | TheSportsDB |

---

## 十一、未来规划（参考）

- 用户账号体系（Supabase Auth）
- 社区交易市场
- 推送通知（价格提醒）
- Apple Watch 配套应用
- 更多运动品类支持
- eBay 实时价格接入
- AR 卡片展示

---

*本文档由项目源码自动分析生成，如有更新请同步维护。*
