#!/usr/bin/env python3
"""
CardScope 数据管道主入口
爬取球员、卡牌、价格数据，清洗后写入 Supabase
"""
from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

# 确保可以导入同目录模块
sys.path.insert(0, str(Path(__file__).parent))

from config import get_config
from loader import get_supabase, insert_prices, upsert_cards, upsert_players
from cleaner import (
    clean_card,
    clean_player_from_ball_dont_lie,
    load_seed_cards,
    merge_player_with_sportsdb,
)
from sources.ball_dont_lie import search_player as ball_search
from sources.the_sports_db import search_player as sportsdb_search
from sources.pricecharting import fetch_card_price


def fetch_and_merge_players(player_names: list[str], name_to_sport: dict[str, str] | None = None) -> list[dict]:
    """从 BallDontLie + TheSportsDB 获取并合并球员数据"""
    config = get_config()
    merged: list[dict] = []
    seen = set()

    for name in player_names:
        name_clean = name.strip()
        if not name_clean or name_clean.lower() in seen:
            continue
        seen.add(name_clean.lower())

        # BallDontLie (仅 NBA)
        ball_players: list[dict] = []
        if config.balldontlie_key:
            try:
                raw = ball_search(name_clean)
                for e in raw:
                    p = clean_player_from_ball_dont_lie(e)
                    if p:
                        ball_players.append(p)
            except Exception as ex:
                print(f"BallDontLie 查询 {name_clean} 失败: {ex}")

        # TheSportsDB（多运动，头像等）
        sportsdb_players: list[dict] = []
        try:
            raw = sportsdb_search(name_clean)
            sportsdb_players = [{"name": p["name"], "team": p["team"], "position": p["position"], "headshot_url": p.get("headshot_url"), "bio": p.get("bio")} for p in raw]
        except Exception as ex:
            print(f"TheSportsDB 查询 {name_clean} 失败: {ex}")

        # 合并：优先 BallDontLie，用 TheSportsDB 丰富
        if ball_players:
            best = ball_players[0]
            for sd in sportsdb_players:
                if sd["name"].lower() == best["name"].lower() or name_clean.lower() in sd["name"].lower():
                    best = merge_player_with_sportsdb(best, sd)
                    break
            merged.append(best)
        elif sportsdb_players:
            p = sportsdb_players[0]
            sport = (name_to_sport or {}).get(name_clean, "NBA")
            merged.append({
                "name": p["name"],
                "sport": sport,
                "team": p["team"],
                "position": p["position"],
                "headshot_url": p.get("headshot_url"),
                "bio": p.get("bio"),
            })
        else:
            # 只有种子卡中的名字，无 API 数据时用占位
            sport = (name_to_sport or {}).get(name_clean, "NBA")
            merged.append({
                "name": name_clean,
                "sport": sport,
                "team": "Unknown Team",
                "position": "Unknown",
                "headshot_url": None,
                "bio": None,
            })

    return merged


def main() -> int:
    parser = argparse.ArgumentParser(description="CardScope 数据管道：爬取并填充数据库")
    parser.add_argument("--dry-run", action="store_true", help="仅打印将要执行的操作，不写入数据库")
    parser.add_argument("--skip-prices", action="store_true", help="跳过 PriceCharting 价格查询（使用种子价格）")
    args = parser.parse_args()

    config = get_config()
    if not args.dry_run and (not config.supabase_url or not config.supabase_service_role_key):
        print("错误: 请设置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY")
        print("可创建 scripts/data_pipeline/.env 或在环境变量中设置")
        return 1

    # 1. 加载种子卡牌
    seed_cards = load_seed_cards()
    if not seed_cards:
        print("错误: data/seed_cards.json 不存在或为空")
        return 1

    player_names = list(dict.fromkeys(c.get("player_name", "") for c in seed_cards if c.get("player_name")))
    player_sport_map = {c.get("player_name", ""): c.get("sport", "NBA") for c in seed_cards if c.get("player_name")}
    print(f"种子卡牌: {len(seed_cards)} 张, 涉及球员: {len(player_names)} 人")

    # 2. 获取球员数据
    players = fetch_and_merge_players(player_names, player_sport_map)
    print(f"获取到 {len(players)} 条球员数据")

    if args.dry_run:
        for p in players[:3]:
            print(f"  球员: {p['name']} | {p['sport']} | {p['team']}")
        print("  ...")
        print("(dry-run 模式，不写入数据库)")
        return 0

    # 3. 写入球员
    sb = get_supabase()
    name_to_id = upsert_players(sb, players)
    print(f"已 upsert {len(name_to_id)} 名球员")

    # 4. 处理卡牌价格（可选 PriceCharting）
    cleaned_cards: list[dict] = []
    for raw in seed_cards:
        price_override = None
        if not args.skip_prices and config.pricecharting_key:
            pc = fetch_card_price(
                raw.get("player_name", ""),
                raw.get("brand", ""),
                raw.get("set_name", ""),
                raw.get("year", ""),
                raw.get("card_number", ""),
                raw.get("parallel", "Base"),
            )
            if pc and (pc.get("loose_price") or pc.get("graded_price")):
                loose = int(pc.get("loose_price", 0))
                graded = int(pc.get("graded_price", 0))
                price_override = {
                    "raw_price_low": max(1, int(loose * 0.85)),
                    "raw_price_high": max(2, int(loose * 1.15)),
                    "psa9_price_low": max(1, int(graded * 0.7)),
                    "psa9_price_high": max(2, int(graded * 0.95)),
                    "psa10_price_low": max(1, int(graded * 0.9)),
                    "psa10_price_high": max(2, int(graded * 1.15)),
                    "current_price": max(loose, graded),
                }
        cleaned_cards.append(clean_card(raw, price_override))

    # 5. 写入卡牌
    card_ids = upsert_cards(sb, cleaned_cards, name_to_id)
    print(f"已 upsert {len(card_ids)} 张卡牌")

    # 6. 写入示例价格记录（用于 prices 表）
    today = date.today().isoformat()
    for i, c in enumerate(cleaned_cards):
        if i < len(card_ids):
            card_id = card_ids[i]
            sample_prices = [
                {"condition": "Raw", "sale_price": c["current_price"] * 0.9, "sale_date": today, "source": "seed", "listing_title": f"{c['player_name']} {c['year']} {c['set_name']}"},
                {"condition": "PSA 9", "sale_price": c["psa9_price_low"], "sale_date": today, "source": "seed", "listing_title": f"{c['player_name']} PSA 9"},
                {"condition": "PSA 10", "sale_price": c["psa10_price_low"], "sale_date": today, "source": "seed", "listing_title": f"{c['player_name']} PSA 10"},
            ]
            insert_prices(sb, card_id, sample_prices)

    print("数据管道执行完成。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
