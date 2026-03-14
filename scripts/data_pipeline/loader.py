"""
Supabase 数据加载器
使用 service_role key 写入 players, cards, prices, price_summary
"""
from __future__ import annotations

from typing import Any

from supabase import create_client, Client

from config import get_config


def get_supabase() -> Client:
    config = get_config()
    if not config.supabase_url or not config.supabase_service_role_key:
        raise ValueError("SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 必须配置")
    return create_client(config.supabase_url, config.supabase_service_role_key)


def upsert_players(sb: Client, players: list[dict[str, Any]]) -> dict[str, str]:
    """
    插入或更新球员，返回 name -> id 映射
    """
    name_to_id: dict[str, str] = {}
    for p in players:
        row = {
            "name": p["name"],
            "sport": p["sport"],
            "team": p.get("team", "Unknown Team"),
            "position": p.get("position", "Unknown"),
            "headshot_url": p.get("headshot_url"),
            "bio": p.get("bio"),
        }
        # 尝试 upsert：按 name 匹配，若无则插入
        existing = sb.table("players").select("id").eq("name", p["name"]).limit(1).execute()
        if existing.data and len(existing.data) > 0:
            rid = existing.data[0]["id"]
            sb.table("players").update(row).eq("id", rid).execute()
            name_to_id[p["name"]] = rid
        else:
            ins = sb.table("players").insert(row).execute()
            if ins.data and len(ins.data) > 0:
                name_to_id[p["name"]] = ins.data[0]["id"]
    return name_to_id


def upsert_cards(sb: Client, cards: list[dict[str, Any]], player_name_to_id: dict[str, str]) -> list[str]:
    """
    插入卡牌，返回插入的 card id 列表
    """
    ids: list[str] = []
    for c in cards:
        player_id = player_name_to_id.get(c["player_name"])
        row = {
            "player_id": player_id,
            "player_name": c["player_name"],
            "team": c["team"],
            "position": c["position"],
            "sport": c["sport"],
            "brand": c["brand"],
            "set_name": c["set_name"],
            "year": c["year"],
            "card_number": c["card_number"],
            "parallel": c["parallel"],
            "is_rookie": c["is_rookie"],
            "raw_price_low": c["raw_price_low"],
            "raw_price_high": c["raw_price_high"],
            "psa9_price_low": c["psa9_price_low"],
            "psa9_price_high": c["psa9_price_high"],
            "psa10_price_low": c["psa10_price_low"],
            "psa10_price_high": c["psa10_price_high"],
            "current_price": c["current_price"],
            "price_change": c.get("price_change", 0),
            "confidence": c.get("confidence", 90),
        }
        # 检查是否已存在（player_name + brand + set_name + year + card_number + parallel）
        key = (c["player_name"], c["brand"], c["set_name"], c["year"], c["card_number"], c["parallel"])
        existing = (
            sb.table("cards")
            .select("id")
            .eq("player_name", c["player_name"])
            .eq("brand", c["brand"])
            .eq("set_name", c["set_name"])
            .eq("year", c["year"])
            .eq("card_number", c["card_number"])
            .eq("parallel", c["parallel"])
            .limit(1)
            .execute()
        )
        if existing.data and len(existing.data) > 0:
            rid = existing.data[0]["id"]
            sb.table("cards").update(row).eq("id", rid).execute()
            ids.append(rid)
        else:
            ins = sb.table("cards").insert(row).execute()
            if ins.data and len(ins.data) > 0:
                ids.append(ins.data[0]["id"])
    return ids


def insert_prices(sb: Client, card_id: str, prices: list[dict[str, Any]]) -> int:
    """插入价格记录"""
    if not prices:
        return 0
    rows = [
        {
            "card_id": card_id,
            "condition": p.get("condition", "Raw"),
            "sale_price": p.get("sale_price", 0),
            "sale_date": p.get("sale_date", "2025-03-14"),
            "source": p.get("source", "seed"),
            "source_url": p.get("source_url"),
            "listing_title": p.get("listing_title"),
        }
        for p in prices
    ]
    sb.table("prices").insert(rows).execute()
    return len(rows)


def upsert_price_summary(sb: Client, card_id: str, condition: str, avg_30d: float, total_sales: int, trend_pct: float) -> None:
    """更新价格汇总"""
    row = {
        "card_id": card_id,
        "condition": condition,
        "avg_price_30d": avg_30d,
        "total_sales_30d": total_sales,
        "price_trend_pct": trend_pct,
    }
    sb.table("price_summary").upsert(row, on_conflict="card_id,condition").execute()
