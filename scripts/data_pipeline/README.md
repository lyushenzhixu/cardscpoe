# CardScope 数据管道

自动爬取球员、卡牌、价格数据，清洗后写入 Supabase 数据库，使 App 展示真实数据。

## 数据流程

```
种子卡牌 (seed_cards.json)
    ↓
BallDontLie API (NBA 球员) + TheSportsDB API (多运动/头像)
    ↓
PriceCharting API (可选，卡牌价格)
    ↓
数据清洗 (cleaner.py)
    ↓
Supabase (players, cards, prices)
```

## 环境配置

1. 复制 `.env.example` 为 `.env`
2. 填写 `SUPABASE_URL` 和 `SUPABASE_SERVICE_ROLE_KEY`（必填）
3. 可选：填写 `BALLDONTLIE_API_KEY`、`SPORTSDB_API_KEY`、`PRICECHARTING_API_KEY`

```bash
cd scripts/data_pipeline
cp .env.example .env
# 编辑 .env 填入真实值
```

## 依赖安装

```bash
cd scripts/data_pipeline
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

若系统缺少 `python3-venv`，可运行 `sudo apt install python3.12-venv`（Ubuntu/Debian）。

## 运行

```bash
# 完整执行（爬取 + 写入数据库）
python main.py

# 试运行（仅打印将要执行的操作）
python main.py --dry-run

# 跳过 PriceCharting 价格查询（使用种子数据中的价格）
python main.py --skip-prices
```

## 数据源说明

| 数据源 | 用途 | 免费额度 |
|--------|------|----------|
| BallDontLie | NBA 球员姓名、球队、位置 | 30 请求/分钟 |
| TheSportsDB | 多运动球员、头像、简介 | key "1" 为演示 |
| PriceCharting | 卡牌价格（Raw/PSA） | 1 请求/秒 |

## 种子卡牌

`data/seed_cards.json` 包含 10 张热门球星卡（Luka Dončić、Shohei Ohtani、Patrick Mahomes、Victor Wembanyama、Jude Bellingham、LeBron James、Jayson Tatum、Anthony Edwards、Stephen Curry、Giannis Antetokounmpo）。

可编辑该文件增加更多卡牌。

## 定时任务（可选）

使用 cron 定期更新数据，例如每日凌晨：

```cron
0 2 * * * cd /path/to/scripts/data_pipeline && python main.py
```
