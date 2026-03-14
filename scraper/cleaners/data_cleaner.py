"""Clean and normalize scraped data before database insertion."""

import re
import logging
from datetime import datetime, timedelta
import statistics

logger = logging.getLogger(__name__)


def clean_players(players: list[dict]) -> list[dict]:
    """Deduplicate, normalize, and validate player records."""
    seen = set()
    cleaned = []

    for p in players:
        name = _clean_text(p.get("name", ""))
        if not name:
            continue

        sport = p.get("sport", "")
        if sport not in ("NBA", "MLB", "NFL", "Soccer"):
            continue

        key = name.lower()
        if key in seen:
            continue
        seen.add(key)

        cleaned.append({
            "name": name,
            "sport": sport,
            "team": _clean_text(p.get("team", "")) or None,
            "position": _clean_text(p.get("position", "")) or None,
            "headshot_url": _clean_url(p.get("headshot_url", "")) or None,
            "bio": _clean_text(p.get("bio", ""))[:2000] if p.get("bio") else None,
        })

    logger.info("Cleaned %d players from %d raw records", len(cleaned), len(players))
    return cleaned


def clean_cards(cards: list[dict]) -> list[dict]:
    """Validate and normalize card records."""
    cleaned = []
    seen = set()

    for c in cards:
        player_name = _clean_text(c.get("player_name", ""))
        if not player_name:
            continue

        sport = c.get("sport", "")
        if sport not in ("NBA", "MLB", "NFL", "Soccer"):
            continue

        brand = _clean_text(c.get("brand", ""))
        set_name = _clean_text(c.get("set_name", ""))
        year = str(c.get("year", "")).strip()
        card_number = str(c.get("card_number", "")).strip()
        parallel = _clean_text(c.get("parallel", "")) or "Base"

        if not all([brand, set_name, year, card_number]):
            continue

        dedup_key = f"{player_name}|{brand}|{set_name}|{year}|{card_number}|{parallel}".lower()
        if dedup_key in seen:
            continue
        seen.add(dedup_key)

        raw_low = max(0, int(c.get("raw_price_low", 0)))
        raw_high = max(raw_low, int(c.get("raw_price_high", 0)))
        psa9_low = max(0, int(c.get("psa9_price_low", 0)))
        psa9_high = max(psa9_low, int(c.get("psa9_price_high", 0)))
        psa10_low = max(0, int(c.get("psa10_price_low", 0)))
        psa10_high = max(psa10_low, int(c.get("psa10_price_high", 0)))
        current = max(0, int(c.get("current_price", 0)))
        change = float(c.get("price_change", 0))
        change = max(-99.9, min(999.9, change))

        cleaned.append({
            "player_name": player_name,
            "team": _clean_text(c.get("team", "")) or "Unknown",
            "position": _clean_text(c.get("position", "")) or "Unknown",
            "sport": sport,
            "brand": brand,
            "set_name": set_name,
            "year": year,
            "card_number": card_number,
            "parallel": parallel,
            "is_rookie": bool(c.get("is_rookie", False)),
            "raw_price_low": raw_low,
            "raw_price_high": raw_high,
            "psa9_price_low": psa9_low,
            "psa9_price_high": psa9_high,
            "psa10_price_low": psa10_low,
            "psa10_price_high": psa10_high,
            "current_price": current,
            "price_change": round(change, 1),
            "confidence": round(float(c.get("confidence", 90)), 1),
            "grade": c.get("grade"),
            "image_url": _clean_url(c.get("image_url", "")) or None,
            "headshot_url": _clean_url(c.get("headshot_url", "")) or None,
        })

    logger.info("Cleaned %d cards from %d raw records", len(cleaned), len(cards))
    return cleaned


def clean_prices(prices: list[dict]) -> list[dict]:
    """Validate and normalize price records."""
    cleaned = []

    for p in prices:
        sale_price = p.get("sale_price", 0)
        if not sale_price or float(sale_price) <= 0:
            continue
        if float(sale_price) > 500000:
            continue

        condition = _clean_text(p.get("condition", "Raw")) or "Raw"
        sale_date = p.get("sale_date", "")
        if not _validate_date(sale_date):
            sale_date = datetime.now().strftime("%Y-%m-%d")

        source = _clean_text(p.get("source", "eBay")) or "eBay"

        cleaned.append({
            "card_index": p.get("card_index"),
            "condition": condition,
            "sale_price": round(float(sale_price), 2),
            "sale_date": sale_date,
            "source": source,
            "source_url": _clean_url(p.get("source_url", "")) or None,
            "listing_title": _clean_text(p.get("listing_title", ""))[:500] if p.get("listing_title") else None,
        })

    logger.info("Cleaned %d prices from %d raw records", len(cleaned), len(prices))
    return cleaned


def update_card_prices_from_sales(cards: list[dict], prices: list[dict]) -> list[dict]:
    """Update card price fields using actual eBay sale data."""
    price_by_card = {}
    for p in prices:
        idx = p.get("card_index")
        if idx is not None:
            price_by_card.setdefault(idx, []).append(p)

    updated = 0
    for idx, card in enumerate(cards):
        if idx not in price_by_card:
            continue

        sales = price_by_card[idx]
        raw_sales = [s["sale_price"] for s in sales if s["condition"] == "Raw"]
        psa9_sales = [s["sale_price"] for s in sales if "PSA 9" in s["condition"] or "BGS 9" in s["condition"]]
        psa10_sales = [s["sale_price"] for s in sales if "PSA 10" in s["condition"] or "BGS 10" in s["condition"] or "BGS 9.5" in s["condition"]]

        if raw_sales:
            card["raw_price_low"] = int(min(raw_sales))
            card["raw_price_high"] = int(max(raw_sales))
            card["current_price"] = int(statistics.median(raw_sales))

        if psa9_sales:
            card["psa9_price_low"] = int(min(psa9_sales))
            card["psa9_price_high"] = int(max(psa9_sales))

        if psa10_sales:
            card["psa10_price_low"] = int(min(psa10_sales))
            card["psa10_price_high"] = int(max(psa10_sales))

        all_sale_prices = [s["sale_price"] for s in sales]
        if len(all_sale_prices) >= 2:
            recent = sorted(sales, key=lambda s: s["sale_date"], reverse=True)
            recent_prices = [s["sale_price"] for s in recent[:len(recent)//2 + 1]]
            older_prices = [s["sale_price"] for s in recent[len(recent)//2 + 1:]]
            if older_prices:
                recent_avg = statistics.mean(recent_prices)
                older_avg = statistics.mean(older_prices)
                if older_avg > 0:
                    card["price_change"] = round(((recent_avg - older_avg) / older_avg) * 100, 1)

        updated += 1

    logger.info("Updated prices for %d cards from eBay data", updated)
    return cards


def compute_price_summaries(cards: list[dict], prices: list[dict]) -> list[dict]:
    """Compute 30-day price summaries per card+condition."""
    summaries = []
    cutoff = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")

    price_by_card = {}
    for p in prices:
        idx = p.get("card_index")
        if idx is not None:
            price_by_card.setdefault(idx, []).append(p)

    for idx in range(len(cards)):
        if idx not in price_by_card:
            continue

        sales = price_by_card[idx]
        by_condition = {}
        for s in sales:
            cond = s["condition"]
            by_condition.setdefault(cond, []).append(s)

        for cond, cond_sales in by_condition.items():
            recent = [s for s in cond_sales if s["sale_date"] >= cutoff]
            if not recent:
                recent = cond_sales

            prices_list = [s["sale_price"] for s in recent]
            if not prices_list:
                continue

            avg = round(statistics.mean(prices_list), 2)
            med = round(statistics.median(prices_list), 2)
            mn = round(min(prices_list), 2)
            mx = round(max(prices_list), 2)

            trend = 0.0
            if len(recent) >= 2:
                sorted_sales = sorted(recent, key=lambda s: s["sale_date"])
                first_half = [s["sale_price"] for s in sorted_sales[:len(sorted_sales)//2 + 1]]
                second_half = [s["sale_price"] for s in sorted_sales[len(sorted_sales)//2 + 1:]]
                if second_half and first_half:
                    f_avg = statistics.mean(first_half)
                    s_avg = statistics.mean(second_half)
                    if f_avg > 0:
                        trend = round(((s_avg - f_avg) / f_avg) * 100, 2)

            summaries.append({
                "card_index": idx,
                "condition": cond,
                "avg_price_30d": avg,
                "median_price_30d": med,
                "min_price_30d": mn,
                "max_price_30d": mx,
                "total_sales_30d": len(recent),
                "price_trend_pct": trend,
            })

    logger.info("Computed %d price summaries", len(summaries))
    return summaries


def _clean_text(text: str | None) -> str:
    if not text:
        return ""
    text = re.sub(r"\s+", " ", str(text)).strip()
    return text


def _clean_url(url: str | None) -> str:
    if not url:
        return ""
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return ""
    return url


def _validate_date(date_str: str) -> bool:
    if not date_str:
        return False
    try:
        datetime.strptime(date_str, "%Y-%m-%d")
        return True
    except ValueError:
        return False
