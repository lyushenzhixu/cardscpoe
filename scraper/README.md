# CardScope Data Pipeline

自动化爬虫 + 数据清洗工具，用于填充 CardScope 应用的数据库，使其拥有真实的球员、球星卡和价格数据。

## 数据源

| 数据类型 | 来源 | 说明 |
|---------|------|------|
| NBA 球员 | balldontlie.io API + nba.com | 球员信息、头像 |
| MLB 球员 | MLB Stats API | 全部 30 支球队现役球员 |
| NFL 球员 | ESPN Public API | 全部 32 支球队现役球员 |
| Soccer 球员 | TheSportsDB API | 顶级球员数据 + 头像 |
| 球星卡目录 | 真实品牌/系列/年份 | Panini, Topps 等真实卡牌系列 |
| 价格数据 | eBay 已成交列表 | 真实市场成交价格 |

## 快速开始

```bash
# 1. 安装依赖
cd scraper
pip install -r requirements.txt

# 2. 配置环境变量（可选，如需直接上传到 Supabase）
cp .env.example .env
# 编辑 .env 填入你的 Supabase 凭据

# 3. 运行完整流水线（输出 SQL 文件）
python main.py

# 4. 导入数据到数据库
psql $DATABASE_URL < output/seed_*.sql
```

## 使用方式

### 基本命令

```bash
# 完整流水线：爬取球员 + 生成卡牌 + 爬取 eBay 价格 + 导出 SQL
python main.py

# 跳过 eBay 爬取（更快，使用算法生成的价格）
python main.py --skip-ebay

# 只处理 NBA 数据
python main.py --sport NBA

# 直接上传到 Supabase
python main.py --output supabase

# 导出为 JSON
python main.py --output json

# 导出所有格式（SQL + JSON + Supabase）
python main.py --output all
```

### 高级选项

```bash
# 只爬取 eBay 上价格最高的 20 张卡
python main.py --ebay-sample 20

# 每个球员最多生成 5 张卡
python main.py --max-cards 5

# 快速模式：跳过 eBay，每人 3 张卡
python main.py --skip-ebay --max-cards 3

# 只生成卡牌不调用 API（使用内置球员数据）
python main.py --mode generate-only
```

## 输出

### SQL 文件
生成的 SQL 文件位于 `output/` 目录，包含：
- `INSERT INTO players` — 球员数据
- `INSERT INTO cards` — 球星卡目录
- `INSERT INTO prices` — 价格记录
- `INSERT INTO price_summary` — 价格汇总

### JSON 文件
包含所有数据的 JSON 格式，便于调试和检查。

## 数据统计（预期）

| 类型 | 数量 |
|------|------|
| 球员 | ~200 (NBA 50 + MLB 50 + NFL 50 + Soccer 50) |
| 球星卡 | ~1000-1600 |
| 价格记录 | ~3000-6000 (如启用 eBay 爬取) |
| 价格汇总 | ~500-1000 |

## 架构

```
scraper/
├── main.py                 # 主入口和流水线编排
├── config.py               # 配置（品牌/系列/年份）
├── requirements.txt        # Python 依赖
├── .env.example            # 环境变量模板
├── scrapers/               # 数据爬取模块
│   ├── nba_players.py      # NBA 球员爬取
│   ├── mlb_players.py      # MLB 球员爬取
│   ├── nfl_players.py      # NFL 球员爬取
│   ├── soccer_players.py   # Soccer 球员爬取
│   ├── card_catalog.py     # 球星卡目录生成
│   └── ebay_prices.py      # eBay 价格爬取
├── cleaners/               # 数据清洗模块
│   └── data_cleaner.py     # 去重、验证、标准化
├── db/                     # 数据库加载模块
│   └── supabase_loader.py  # Supabase 上传 + SQL/JSON 导出
└── output/                 # 生成的数据文件
```
