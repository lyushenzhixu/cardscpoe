"""
TheSportsDB API - 多运动球员数据（头像、球队、简介）
免费 API: https://www.thesportsdb.com/api.php
"""
from __future__ import annotations

from typing import Any

import requests

from config import get_config


def search_player(name: str, sport: str | None = None) -> list[dict[str, Any]]:
    """按姓名搜索球员，获取头像、球队、简介等"""
    config = get_config()
    key = config.sportsdb_key or "1"  # "1" 为免费演示 key
    q = name.replace(" ", "_")
    url = f"https://www.thesportsdb.com/api/v1/json/{key}/searchplayers.php"
    resp = requests.get(url, params={"p": q}, timeout=30)

    if resp.status_code != 200:
        return []

    data = resp.json()
    players = data.get("player") or []

    result: list[dict[str, Any]] = []
    for p in players:
        name_val = p.get("strPlayer") or ""
        if not name_val:
            continue
        result.append({
            "name": name_val,
            "team": p.get("strTeam") or "Unknown Team",
            "position": p.get("strPosition") or "Unknown",
            "headshot_url": p.get("strCutout") or p.get("strThumb"),
            "bio": p.get("strDescriptionEN"),
        })
    return result


def get_player_thumb(player_name: str) -> str | None:
    """获取球员头像 URL"""
    matches = search_player(player_name)
    for m in matches:
        if m.get("headshot_url"):
            return m["headshot_url"]
    return None
