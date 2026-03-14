"""
PriceCharting API - 卡牌价格数据
文档: https://www.pricecharting.com/api-documentation
注意: 体育卡可能通过 SportsCardsPro，需付费订阅；此处实现通用查询
"""
from __future__ import annotations

import time
from typing import Any

import requests

from config import get_config


def fetch_card_price(
    player_name: str,
    brand: str,
    set_name: str,
    year: str,
    card_number: str,
    parallel: str = "Base",
) -> dict[str, Any] | None:
    """
    查询单张卡的价格
    返回: loose_price (Raw), graded_price (PSA), 或 None
    """
    config = get_config()
    if not config.pricecharting_key:
        return None

    q = f"{player_name} {year} {brand} {set_name} #{card_number} {parallel}"
    url = "https://www.pricecharting.com/api/product"
    params = {"t": config.pricecharting_key, "q": q}

    try:
        resp = requests.get(url, params=params, timeout=15)
        if resp.status_code != 200:
            return None

        data = resp.json()
        if not data:
            return None

        loose = data.get("loosePrice") or data.get("usedPrice") or data.get("loose-price") or 0
        graded = data.get("newPrice") or data.get("gradedPrice") or data.get("new-price") or loose

        # PriceCharting/SportsCardsPro 官方文档：价格为美分 (e.g. $17.32 = 1732)
        def to_dollars(v: int | float) -> float:
            if not v:
                return 0.0
            f = float(v)
            return round(f / 100.0, 2)

        if isinstance(loose, (int, float)) and isinstance(graded, (int, float)):
            return {
                "product_name": data.get("product-name") or data.get("productName"),
                "loose_price": to_dollars(loose),
                "graded_price": to_dollars(graded),
            }
    except Exception as e:
        print(f"PriceCharting 查询失败 {q[:50]}...: {e}")
    return None


def fetch_prices_batch(cards: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    """
    批量查询卡牌价格（带限速 1 req/s）
    cards: [{"player_name", "brand", "set_name", "year", "card_number", "parallel"}, ...]
    返回: {card_key: price_data}
    """
    config = get_config()
    if not config.pricecharting_key:
        return {}

    result: dict[str, dict[str, Any]] = {}
    for card in cards:
        key = f"{card.get('player_name','')}|{card.get('brand','')}|{card.get('set_name','')}|{card.get('year','')}|{card.get('card_number','')}"
        price = fetch_card_price(
            player_name=card.get("player_name", ""),
            brand=card.get("brand", ""),
            set_name=card.get("set_name", ""),
            year=card.get("year", ""),
            card_number=card.get("card_number", ""),
            parallel=card.get("parallel", "Base"),
        )
        if price:
            result[key] = price
        time.sleep(1.1)  # 遵守 1 req/s 限制
    return result
