"""
BallDontLie API - NBA 球员数据
免费 API: https://docs.balldontlie.io/
限制: 30 请求/分钟 (免费 tier)
"""
from __future__ import annotations

import time
from typing import Any

import requests

from config import get_config


def fetch_nba_players(per_page: int = 100) -> list[dict[str, Any]]:
    """分页获取所有 NBA 球员"""
    config = get_config()
    if not config.balldontlie_key:
        print("警告: BALLDONTLIE_API_KEY 未配置，跳过 NBA 球员爬取")
        return []

    base_url = "https://api.balldontlie.io/v1/players"
    headers = {
        "Authorization": config.balldontlie_key,
        "Accept": "application/json",
    }
    all_players: list[dict[str, Any]] = []
    page = 0

    while True:
        resp = requests.get(
            base_url,
            params={"per_page": per_page, "cursor": page * per_page},
            headers=headers,
            timeout=30,
        )
        if resp.status_code != 200:
            print(f"BallDontLie API 错误: {resp.status_code} - {resp.text[:200]}")
            break

        data = resp.json().get("data") or []
        meta = resp.json().get("meta") or {}
        all_players.extend(data)

        if not data or len(data) < per_page:
            break

        page += 1
        time.sleep(2.1)  # 确保不超过 30 req/min

    return all_players


def search_player(name: str) -> list[dict[str, Any]]:
    """按姓名搜索球员"""
    config = get_config()
    if not config.balldontlie_key:
        return []

    url = "https://api.balldontlie.io/v1/players"
    headers = {
        "Authorization": config.balldontlie_key,
        "Accept": "application/json",
    }
    resp = requests.get(
        url,
        params={"search": name},
        headers=headers,
        timeout=30,
    )
    if resp.status_code != 200:
        return []

    return resp.json().get("data") or []
