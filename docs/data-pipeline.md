# CardScope 数据流水线 — 完整技术文档

## 概述

本项目为 CardScope iOS 应用构建了一套**自动化数据爬虫与清洗工具**，从多个公开数据源抓取真实的球员信息、球星卡目录和市场价格数据，经过清洗后填充至 Supabase (PostgreSQL) 数据库，使 App 展示真实数据。

---

## 1. 数据源一览

| 数据类型 | 数据源 | 协议 | 认证 |
|---------|--------|------|------|
| NBA 球员 | [balldontlie.io](https://balldontlie.io) API | REST | 可选 API Key |
| NBA 头像 | [cdn.nba.com](https://cdn.nba.com) | CDN | 无 |
| MLB 球员 | [MLB Stats API](https://statsapi.mlb.com) | REST | 无 |
| MLB 头像 | [img.mlbstatic.com](https://img.mlbstatic.com) | CDN | 无 |
| NFL 球员 | [ESPN Public API](https://site.api.espn.com) | REST | 无 |
| Soccer 球员 | [TheSportsDB](https://www.thesportsdb.com) | REST | 免费 Key |
| 球星卡目录 | 内置真实品牌/系列知识库 | 本地 | 无 |
| 市场价格 | [eBay Sold Listings](https://www.ebay.com) 爬虫 | HTTP scrape | 无 |
| 备用价格 | 内置价格生成器（基于统计模型） | 本地 | 无 |

---

## 2. 数据库架构

### 2.1 表结构

```
players (1) ─────────────── (N) cards
                                 │
                                 ├── (N) prices
                                 ├── (1) price_summary (per condition)
                                 ├── (N) user_collections
                                 └── (N) scan_history

trending_snapshot (独立预计算表)
```

### 2.2 各表字段

#### `players` — 球员信息
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| name | text | 球员姓名 |
| sport | text | NBA / MLB / NFL / Soccer |
| team | text | 所属球队 |
| position | text | 场上位置 |
| headshot_url | text | 头像 URL |
| bio | text | 个人简介 |

#### `cards` — 球星卡目录
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| player_id | uuid | 外键 → players |
| player_name | text | 球员姓名（冗余） |
| team / position / sport | text | 球队/位置/运动类型 |
| brand | text | 品牌 (Panini, Topps 等) |
| set_name | text | 系列 (Prizm, Chrome 等) |
| year | text | 年份 |
| card_number | text | 卡号 |
| parallel | text | 平行版本 (Base, Silver, Gold 等) |
| is_rookie | boolean | 是否为新秀卡 |
| raw_price_low/high | integer | Raw 评级价格区间 |
| psa9_price_low/high | integer | PSA 9 评级价格区间 |
| psa10_price_low/high | integer | PSA 10 评级价格区间 |
| current_price | integer | 当前市场价格 |
| price_change | double | 价格变化百分比 |
| confidence | double | 价格置信度 |

#### `prices` — 成交记录
| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| card_id | uuid | 外键 → cards |
| condition | text | 评级条件 (Raw, PSA 9, PSA 10...) |
| sale_price | numeric(10,2) | 成交价格 |
| sale_date | date | 成交日期 |
| source | text | 来源 (eBay) |
| source_url | text | 原始链接 |
| listing_title | text | 商品标题 |

#### `price_summary` — 价格汇总
| 字段 | 类型 | 说明 |
|------|------|------|
| card_id | uuid | 复合主键 |
| condition | text | 复合主键 |
| avg/median/min/max_price_30d | numeric | 30 天价格统计 |
| total_sales_30d | integer | 30 天销量 |
| price_trend_pct | numeric | 趋势百分比 |

#### `trending_snapshot` — 热门预计算
| 字段 | 类型 | 说明 |
|------|------|------|
| kind | text | 'players' 或 'series' |
| payload | jsonb | 预计算的 JSON 数据 |
| computed_at | timestamptz | 计算时间 |

### 2.3 视图

- **`trending_players_view`** — Top 50 热门球员（按 price_change 排序）
- **`popular_series_view`** — Top 30 热门系列（按 card_count 排序）

---

## 3. 数据入库统计

| 表 | 记录数 | 说明 |
|---|------:|------|
| `players` | 231 | NBA 50 + MLB 80 + NFL 48 + Soccer 53 |
| `cards` | 1,792 | 真实品牌/系列/年份组合 |
| `prices` | 10,680 | 多评级条件成交记录 |
| `price_summary` | 5,706 | 30 天价格汇总 |
| `trending_snapshot` | 2 | 热门球员 + 热门系列快照 |
| **合计** | **18,411** | |

### 球员分布

| 运动 | 数量 | 头像覆盖率 | 数据源 |
|------|-----:|----------:|--------|
| NBA | 50 | 100% | balldontlie.io + nba.com CDN |
| MLB | 80 | 100% | MLB Stats API + mlbstatic.com |
| NFL | 48 | ~80% | ESPN Public API |
| Soccer | 53 | ~45% | TheSportsDB API |

### 球星卡分布

| 品牌 | 数量 | 主要系列 |
|------|-----:|---------|
| Panini | 901 | Prizm, Select, Donruss, Mosaic, National Treasures |
| Topps | 886 | Chrome, Series 1/2, Heritage, Finest, Bowman |
| Upper Deck | 5 | SP Authentic |

### 价格条件分布

| 条件 | 占比 |
|------|-----:|
| Raw | 45% |
| PSA 9 | 25% |
| PSA 10 | 12% |
| BGS 9.5 | 8% |
| SGC 9/10 | 10% |

### 最高价值球星卡 Top 10

| 排名 | 球员 | 卡牌 | 价格 |
|------|------|------|-----:|
| 1 | Aaron Judge | 2025 Topps Chrome Gold Refractor | $2,191 |
| 2 | Lamar Jackson | 2018 Panini Prizm Black RC | $2,022 |
| 3 | Patrick Mahomes | 2023 Panini Prizm Black | $1,987 |
| 4 | Josh Allen | 2021 Panini Prizm Gold | $1,965 |
| 5 | Joe Burrow | 2020 Panini Prizm Gold RC | $1,823 |
| 6 | Shohei Ohtani | 2018 Topps Chrome Gold Refractor RC | $1,800 |
| 7 | Patrick Mahomes | 2020 Panini Prizm Black | $1,618 |
| 8 | Giannis Antetokounmpo | 2019 Panini Prizm Black | $1,549 |
| 9 | LeBron James | 2018 Panini Prizm Black | $1,538 |
| 10 | Luka Doncic | 2021 Panini Prizm Black | $1,431 |

---

## 4. 工具架构

```
scraper/
├── main.py                 # 主入口 — CLI 参数解析与流水线编排
├── config.py               # 配置 — 品牌/系列/年份/API 超时等
├── requirements.txt        # Python 依赖
├── .env.example            # 环境变量模板
├── scrapers/               # 数据爬取模块
│   ├── nba_players.py      # NBA: balldontlie.io + nba.com headshots
│   ├── mlb_players.py      # MLB: statsapi.mlb.com team rosters
│   ├── nfl_players.py      # NFL: ESPN public API team rosters
│   ├── soccer_players.py   # Soccer: TheSportsDB API
│   ├── card_catalog.py     # 球星卡目录生成 (真实品牌/系列)
│   ├── ebay_prices.py      # eBay 已成交列表爬虫
│   └── price_generator.py  # 备用价格生成器 (统计模型)
├── cleaners/               # 数据清洗模块
│   └── data_cleaner.py     # 去重/验证/标准化/汇总计算
└── db/                     # 数据库模块
    └── supabase_loader.py  # Supabase REST 上传 + SQL/JSON 导出
```

### 流水线步骤

```
1. 爬取球员数据 (API 调用 → 硬编码兜底)
       ↓
2. 清洗球员数据 (去重、字段标准化)
       ↓
3. 生成球星卡目录 (球员 × 品牌 × 系列 × 年份)
       ↓
4. 清洗卡牌数据 (去重、价格验证)
       ↓
5. 爬取/生成价格 (eBay → 统计模型兜底)
       ↓
6. 用价格更新卡牌 + 计算汇总
       ↓
7. 输出 (Supabase REST API / SQL / JSON)
```

---

## 5. 使用方法

### 环境准备

```bash
cd scraper
pip install -r requirements.txt
```

### 基本命令

```bash
# 完整流水线 → 直接上传 Supabase
SUPABASE_URL=https://xxx.supabase.co \
SUPABASE_SERVICE_KEY=your-key \
python3 main.py --output supabase

# 快速模式（跳过 eBay 爬取）
python3 main.py --skip-ebay --output supabase

# 仅导出 SQL 文件
python3 main.py --skip-ebay --output sql

# 仅处理 NBA
python3 main.py --sport NBA --output supabase

# 每人最多 3 张卡（快速测试）
python3 main.py --max-cards 3 --skip-ebay --output json
```

### 环境变量

| 变量 | 必须 | 说明 |
|------|------|------|
| `SUPABASE_URL` | 上传时必须 | Supabase 项目 URL |
| `SUPABASE_SERVICE_KEY` | 上传时必须 | Service Role Key |

也可以通过 `.env` 文件配置（复制 `.env.example`）。

### SQL 导入方式

如果选择导出 SQL 而非直接上传：

```bash
python3 main.py --skip-ebay --output sql
psql $DATABASE_URL < output/seed_*.sql
```

预生成的 seed 文件也在 `supabase/seed/seed_data.sql`。

---

## 6. 数据质量保障

### 清洗规则

- **去重**：按球员姓名 (小写) 去重；按 player+brand+set+year+number+parallel 去重卡牌
- **验证**：sport 必须为 NBA/MLB/NFL/Soccer；价格必须 ≥ 0 且 < $500,000
- **标准化**：文本清除多余空白；URL 必须以 http(s):// 开头；日期格式 YYYY-MM-DD
- **价格区间校正**：确保 raw_low ≤ raw_high ≤ psa9_low ≤ psa9_high ≤ psa10_low ≤ psa10_high

### 兜底机制

每个爬取模块都有硬编码数据兜底：
- API 不可用 → 自动使用内置球员列表
- eBay 超时或被封 → 自动使用统计价格生成器
- Supabase 未配置 → 自动回退到 SQL 文件导出

---

## 7. 验证结果

### 外键完整性 ✅

- `cards.player_id` → `players.id`：全部关联正确
- `prices.card_id` → `cards.id`：全部关联正确
- `price_summary.card_id` → `cards.id`：全部关联正确

### 视图验证 ✅

- `trending_players_view`：返回 50 条热门球员数据
- `popular_series_view`：返回 30 条热门系列数据
- `trending_snapshot`：2 条预计算快照 (players + series)

### App 兼容性 ✅

- `CardService.fetchAllCards()` → 查询 `cards` 表 ✅
- `PlayerService.searchPlayer()` → 查询 `players` 表 ✅
- `PriceService.fetchPriceData()` → 查询 `prices` / `price_summary` ✅
- `ExploreView` → 查询 `trending_players_view` / `popular_series_view` ✅

---

## 8. 后续扩展

1. **定时更新**：配置 cron 或 GitHub Actions 定期运行 `python3 main.py --output supabase` 更新数据
2. **eBay API 集成**：申请 eBay Browse API Key 替换 HTML 爬虫，提高稳定性
3. **PriceCharting 集成**：已预留接口，填入 API Key 即可获取更准确的价格数据
4. **图片爬取**：扩展 eBay 爬虫获取卡牌实物图片，填充 `cards.image_url`
5. **增量更新**：目前为全量导入，可扩展为增量更新模式（仅更新价格变化）
