"""
数据清洗与规范化
- 球员姓名标准化
- 运动类型映射 (NBA/MLB/NFL/Soccer)
- 价格单位统一 (美元 -> 美分存入或保持整数)
- 去重与空值处理
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

# 运动类型合法值 (与 DB schema 一致)
VALID_SPORTS = {"NBA", "MLB", "NFL", "Soccer"}


def normalize_player_name(name: str) -> str:
    """标准化球员姓名：去除多余空格、统一特殊字符"""
    if not name or not isinstance(name, str):
        return ""
    s = " ".join(name.split())
    # Dončić -> Doncic 等，保留原始形式以匹配搜索
    return s.strip()


def normalize_sport(sport: str) -> str:
    """确保 sport 在合法枚举内"""
    if not sport:
        return "NBA"
    u = sport.upper().strip()
    for v in VALID_SPORTS:
        if v in u or u in v:
            return v
    if "basket" in u or "nba" in u:
        return "NBA"
    if "base" in u or "mlb" in u:
        return "MLB"
    if "foot" in u or "nfl" in u:
        return "NFL"
    if "soccer" in u or "football" in u:
        return "Soccer"
    return "NBA"


def normalize_price(value: Any) -> int:
    """价格转为整数（美元），无效则 0"""
    if value is None:
        return 0
    if isinstance(value, (int, float)):
        return max(0, int(round(float(value))))
    if isinstance(value, str):
        cleaned = re.sub(r"[^0-9.]", "", value)
        try:
            return max(0, int(round(float(cleaned))))
        except ValueError:
            return 0
    return 0


def _extract_team(team_any: Any) -> str:
    if isinstance(team_any, dict):
        return str(team_any.get("full_name") or team_any.get("fullName") or team_any.get("abbreviation") or "").strip() or "Unknown Team"
    if team_any:
        return str(team_any).strip()
    return "Unknown Team"


def clean_player(raw: dict[str, Any]) -> dict[str, Any]:
    """清洗单条球员数据，输出符合 players 表的格式"""
    name = normalize_player_name(
        raw.get("name") or f"{raw.get('firstName', '')} {raw.get('lastName', '')}".strip()
    )
    if not name:
        name = str(raw.get("name", "")).strip()
    return {
        "name": name or "Unknown",
        "sport": normalize_sport(str(raw.get("sport", "NBA"))),
        "team": _extract_team(raw.get("team")),
        "position": str(raw.get("position") or "Unknown").strip() or "Unknown",
        "headshot_url": (raw.get("headshot_url") or raw.get("strCutout") or raw.get("strThumb") or "").strip() or None,
        "bio": (raw.get("bio") or raw.get("strDescriptionEN") or "").strip() or None,
    }


def clean_player_from_ball_dont_lie(entry: dict[str, Any]) -> dict[str, Any] | None:
    """从 BallDontLie 返回格式转为清洗后球员"""
    first = entry.get("first_name") or entry.get("firstName") or ""
    last = entry.get("last_name") or entry.get("lastName") or ""
    name = f"{first} {last}".strip()
    if not name:
        return None
    team = entry.get("team")
    team_name = (team.get("full_name") or team.get("fullName")) if isinstance(team, dict) else (team or "Unknown Team")
    return {
        "name": name,
        "sport": "NBA",
        "team": team_name or "Unknown Team",
        "position": (entry.get("position") or "Unknown").strip() or "Unknown",
        "headshot_url": None,
        "bio": None,
    }


def clean_card(raw: dict[str, Any], price_override: dict[str, Any] | None = None) -> dict[str, Any]:
    """清洗单条卡牌数据，输出符合 cards 表的格式"""
    out: dict[str, Any] = {
        "player_name": normalize_player_name(raw.get("player_name", "")),
        "team": str(raw.get("team", "")).strip() or "Unknown Team",
        "position": str(raw.get("position", "")).strip() or "Unknown",
        "sport": normalize_sport(str(raw.get("sport", "NBA"))),
        "brand": str(raw.get("brand", "")).strip() or "Unknown",
        "set_name": str(raw.get("set_name", "")).strip() or "Unknown",
        "year": str(raw.get("year", "")).strip() or "Unknown",
        "card_number": str(raw.get("card_number", "")).strip() or "0",
        "parallel": str(raw.get("parallel", "")).strip() or "Base",
        "is_rookie": bool(raw.get("is_rookie", False)),
        "raw_price_low": normalize_price(raw.get("raw_price_low")),
        "raw_price_high": normalize_price(raw.get("raw_price_high")),
        "psa9_price_low": normalize_price(raw.get("psa9_price_low")),
        "psa9_price_high": normalize_price(raw.get("psa9_price_high")),
        "psa10_price_low": normalize_price(raw.get("psa10_price_low")),
        "psa10_price_high": normalize_price(raw.get("psa10_price_high")),
        "current_price": normalize_price(raw.get("current_price")),
        "price_change": float(raw.get("price_change", 0)) if raw.get("price_change") is not None else 0.0,
        "confidence": min(100, max(0, float(raw.get("confidence", 90)))),
    }
    if price_override:
        for k, v in price_override.items():
            if k in out:
                out[k] = v
    return out


def load_seed_cards() -> list[dict[str, Any]]:
    """加载种子卡牌 JSON"""
    path = Path(__file__).parent / "data" / "seed_cards.json"
    if not path.exists():
        return []
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, list) else []


def merge_player_with_sportsdb(ball_player: dict[str, Any], sportsdb: dict[str, Any]) -> dict[str, Any]:
    """用 TheSportsDB 数据丰富球员（头像、简介）"""
    out = dict(ball_player)
    if sportsdb.get("headshot_url"):
        out["headshot_url"] = sportsdb["headshot_url"]
    if sportsdb.get("bio"):
        out["bio"] = sportsdb["bio"]
    if sportsdb.get("team") and sportsdb["team"] != "Unknown Team":
        out["team"] = sportsdb["team"]
    if sportsdb.get("position") and sportsdb["position"] != "Unknown":
        out["position"] = sportsdb["position"]
    return out
