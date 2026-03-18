"""Load cleaned data into Supabase (PostgreSQL) via REST API or export as SQL."""

import json
import uuid
import logging
from datetime import datetime
from pathlib import Path

import requests
from config import SUPABASE_URL, SUPABASE_SERVICE_KEY, REQUEST_TIMEOUT

logger = logging.getLogger(__name__)

BATCH_SIZE = 25


class SupabaseLoader:
    """Handles data insertion into Supabase."""

    def __init__(self, url: str = "", key: str = ""):
        self.url = (url or SUPABASE_URL).rstrip("/")
        self.key = key or SUPABASE_SERVICE_KEY
        self.headers = {
            "apikey": self.key,
            "Authorization": f"Bearer {self.key}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=representation",
        }
        self.player_id_map = {}
        self.card_id_map = {}

    @property
    def is_configured(self) -> bool:
        return bool(self.url) and bool(self.key)

    def load_all(self, players: list[dict], cards: list[dict],
                 prices: list[dict], summaries: list[dict]) -> dict:
        """Load all data into Supabase. Returns stats dict."""
        if not self.is_configured:
            logger.error("Supabase not configured. Set SUPABASE_URL and SUPABASE_SERVICE_KEY.")
            return {"error": "Not configured"}

        stats = {"players": 0, "cards": 0, "prices": 0, "summaries": 0}

        # Clear old data in dependency order
        logger.info("Clearing old data...")
        for table in ["trending_snapshot", "price_summary", "prices", "cards", "players"]:
            self._delete_all(table)

        logger.info("Loading %d players...", len(players))
        stats["players"] = self._load_players(players)

        logger.info("Loading %d cards...", len(cards))
        stats["cards"] = self._load_cards(cards)

        logger.info("Loading %d prices...", len(prices))
        stats["prices"] = self._load_prices(prices)

        logger.info("Loading %d price summaries...", len(summaries))
        stats["summaries"] = self._load_summaries(summaries)

        self._refresh_trending()

        logger.info("Load complete: %s", stats)
        return stats

    def _load_players(self, players: list[dict]) -> int:
        count = 0
        for i in range(0, len(players), BATCH_SIZE):
            batch = players[i:i + BATCH_SIZE]
            records = []
            for idx, p in enumerate(batch):
                pid = str(uuid.uuid4())
                record = {
                    "id": pid,
                    "name": p["name"],
                    "sport": p["sport"],
                    "team": p.get("team"),
                    "position": p.get("position"),
                    "headshot_url": p.get("headshot_url"),
                    "bio": p.get("bio"),
                }
                records.append(record)
                global_idx = i + idx
                self.player_id_map[p["name"].lower()] = pid

            inserted = self._upsert("players", records)
            count += inserted

        return count

    def _load_cards(self, cards: list[dict]) -> int:
        count = 0
        for i in range(0, len(cards), BATCH_SIZE):
            batch = cards[i:i + BATCH_SIZE]
            records = []
            for local_idx, c in enumerate(batch):
                cid = str(uuid.uuid4())
                player_id = self.player_id_map.get(c["player_name"].lower())
                record = {
                    "id": cid,
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
                    "price_change": c["price_change"],
                    "confidence": c["confidence"],
                    "grade": c.get("grade"),
                    "image_url": c.get("image_url"),
                    "headshot_url": c.get("headshot_url"),
                }
                records.append(record)
                global_idx = i + local_idx
                self.card_id_map[global_idx] = cid

            inserted = self._upsert("cards", records)
            count += inserted

        return count

    def _load_prices(self, prices: list[dict]) -> int:
        count = 0
        for i in range(0, len(prices), BATCH_SIZE):
            batch = prices[i:i + BATCH_SIZE]
            records = []
            for p in batch:
                card_idx = p.get("card_index")
                card_id = self.card_id_map.get(card_idx)
                if not card_id:
                    continue
                records.append({
                    "id": str(uuid.uuid4()),
                    "card_id": card_id,
                    "condition": p["condition"],
                    "sale_price": p["sale_price"],
                    "sale_date": p["sale_date"],
                    "source": p["source"],
                    "source_url": p.get("source_url"),
                    "listing_title": p.get("listing_title"),
                })

            if records:
                inserted = self._upsert("prices", records)
                count += inserted

        return count

    def _load_summaries(self, summaries: list[dict]) -> int:
        count = 0
        for i in range(0, len(summaries), BATCH_SIZE):
            batch = summaries[i:i + BATCH_SIZE]
            records = []
            for s in batch:
                card_idx = s.get("card_index")
                card_id = self.card_id_map.get(card_idx)
                if not card_id:
                    continue
                records.append({
                    "card_id": card_id,
                    "condition": s["condition"],
                    "avg_price_30d": s["avg_price_30d"],
                    "median_price_30d": s["median_price_30d"],
                    "min_price_30d": s["min_price_30d"],
                    "max_price_30d": s["max_price_30d"],
                    "total_sales_30d": s["total_sales_30d"],
                    "price_trend_pct": s["price_trend_pct"],
                })

            if records:
                inserted = self._upsert("price_summary", records)
                count += inserted

        return count

    def _refresh_trending(self):
        """Insert a fresh trending_snapshot for players and series."""
        try:
            players_resp = requests.get(
                f"{self.url}/rest/v1/trending_players_view",
                headers={**self.headers, "Prefer": ""},
                params={"select": "*", "limit": "50"},
                timeout=REQUEST_TIMEOUT,
            )
            if players_resp.status_code == 200:
                payload = players_resp.json()
                self._upsert("trending_snapshot", [{
                    "id": str(uuid.uuid4()),
                    "kind": "players",
                    "payload": json.dumps(payload),
                }])

            series_resp = requests.get(
                f"{self.url}/rest/v1/popular_series_view",
                headers={**self.headers, "Prefer": ""},
                params={"select": "*", "limit": "30"},
                timeout=REQUEST_TIMEOUT,
            )
            if series_resp.status_code == 200:
                payload = series_resp.json()
                self._upsert("trending_snapshot", [{
                    "id": str(uuid.uuid4()),
                    "kind": "series",
                    "payload": json.dumps(payload),
                }])

            logger.info("Trending snapshots refreshed")
        except Exception as e:
            logger.warning("Failed to refresh trending snapshots: %s", e)

    def _delete_all(self, table: str):
        """Delete all rows from a table."""
        import time as _time
        for attempt in range(3):
            try:
                resp = requests.delete(
                    f"{self.url}/rest/v1/{table}",
                    headers={**self.headers, "Prefer": ""},
                    params={"id": "neq.00000000-0000-0000-0000-000000000000"},
                    timeout=REQUEST_TIMEOUT,
                )
                if resp.status_code in (200, 204):
                    logger.info("Cleared table: %s", table)
                    return
                else:
                    logger.warning("Delete from %s returned %d: %s", table, resp.status_code, resp.text[:200])
                    return
            except requests.RequestException as e:
                if attempt < 2:
                    _time.sleep(2 ** attempt + 1)
                else:
                    logger.error("Failed to clear %s: %s", table, e)

    def _upsert(self, table: str, records: list[dict], max_retries: int = 5) -> int:
        if not records:
            return 0
        import time as _time
        for attempt in range(max_retries):
            try:
                resp = requests.post(
                    f"{self.url}/rest/v1/{table}",
                    headers=self.headers,
                    json=records,
                    timeout=REQUEST_TIMEOUT,
                )
                if resp.status_code in (200, 201):
                    return len(records)
                else:
                    logger.error(
                        "Supabase upsert to %s failed (%d): %s",
                        table, resp.status_code, resp.text[:500],
                    )
                    return 0
            except requests.RequestException as e:
                wait = 2 ** attempt + 1
                if attempt < max_retries - 1:
                    logger.warning(
                        "Supabase request to %s failed (attempt %d/%d), retrying in %ds: %s",
                        table, attempt + 1, max_retries, wait, str(e)[:100],
                    )
                    _time.sleep(wait)
                else:
                    logger.error("Supabase request failed for %s after %d retries: %s", table, max_retries, e)
                    return 0
        return 0


def export_sql(players: list[dict], cards: list[dict],
               prices: list[dict], summaries: list[dict],
               output_dir: str = "output") -> str:
    """Export all data as a SQL seed file. Returns path to the generated file."""
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filepath = f"{output_dir}/seed_{timestamp}.sql"

    player_id_map = {}
    card_id_map = {}

    with open(filepath, "w", encoding="utf-8") as f:
        f.write("-- CardScope seed data\n")
        f.write(f"-- Generated at {datetime.now().isoformat()}\n")
        f.write("-- Run with: psql $DATABASE_URL < seed.sql\n\n")

        f.write("BEGIN;\n\n")

        f.write("-- Players\n")
        for p in players:
            pid = str(uuid.uuid4())
            player_id_map[p["name"].lower()] = pid
            name_v = _sql_val(p["name"])
            sport_v = _sql_val(p["sport"])
            team_v = _sql_nullable(p.get("team"))
            pos_v = _sql_nullable(p.get("position"))
            head_v = _sql_nullable(p.get("headshot_url"))
            bio_v = _sql_nullable(p.get("bio"))
            f.write(
                f"INSERT INTO public.players (id, name, sport, team, position, headshot_url, bio) "
                f"VALUES ('{pid}', {name_v}, {sport_v}, {team_v}, {pos_v}, {head_v}, {bio_v}) "
                f"ON CONFLICT (id) DO NOTHING;\n"
            )

        f.write("\n-- Cards\n")
        for idx, c in enumerate(cards):
            cid = str(uuid.uuid4())
            card_id_map[idx] = cid
            player_id = player_id_map.get(c["player_name"].lower())
            pid_val = f"'{player_id}'" if player_id else "NULL"

            vals = ", ".join([
                f"'{cid}'", pid_val,
                _sql_val(c["player_name"]), _sql_val(c["team"]),
                _sql_val(c["position"]), _sql_val(c["sport"]),
                _sql_val(c["brand"]), _sql_val(c["set_name"]),
                _sql_val(c["year"]), _sql_val(c["card_number"]),
                _sql_val(c["parallel"]), str(c["is_rookie"]).lower(),
                str(c["raw_price_low"]), str(c["raw_price_high"]),
                str(c["psa9_price_low"]), str(c["psa9_price_high"]),
                str(c["psa10_price_low"]), str(c["psa10_price_high"]),
                str(c["current_price"]), str(c["price_change"]), str(c["confidence"]),
                _sql_nullable(c.get("grade")),
                _sql_nullable(c.get("image_url")),
                _sql_nullable(c.get("headshot_url")),
            ])
            f.write(
                f"INSERT INTO public.cards (id, player_id, player_name, team, position, sport, "
                f"brand, set_name, year, card_number, parallel, is_rookie, "
                f"raw_price_low, raw_price_high, psa9_price_low, psa9_price_high, "
                f"psa10_price_low, psa10_price_high, current_price, price_change, confidence, "
                f"grade, image_url, headshot_url) VALUES ({vals}) "
                f"ON CONFLICT (id) DO NOTHING;\n"
            )

        f.write("\n-- Prices\n")
        for p in prices:
            card_idx = p.get("card_index")
            card_id = card_id_map.get(card_idx)
            if not card_id:
                continue
            price_id = str(uuid.uuid4())
            vals = ", ".join([
                f"'{price_id}'", f"'{card_id}'",
                _sql_val(p["condition"]),
                str(p["sale_price"]),
                _sql_val(p["sale_date"]),
                _sql_val(p["source"]),
                _sql_nullable(p.get("source_url")),
                _sql_nullable(p.get("listing_title")),
            ])
            f.write(
                f"INSERT INTO public.prices (id, card_id, condition, sale_price, sale_date, "
                f"source, source_url, listing_title) VALUES ({vals}) "
                f"ON CONFLICT (id) DO NOTHING;\n"
            )

        f.write("\n-- Price Summaries\n")
        for s in summaries:
            card_idx = s.get("card_index")
            card_id = card_id_map.get(card_idx)
            if not card_id:
                continue
            f.write(
                f"INSERT INTO public.price_summary (card_id, condition, avg_price_30d, "
                f"median_price_30d, min_price_30d, max_price_30d, total_sales_30d, price_trend_pct) "
                f"VALUES ('{card_id}', {_sql_val(s['condition'])}, "
                f"{s['avg_price_30d']}, {s['median_price_30d']}, "
                f"{s['min_price_30d']}, {s['max_price_30d']}, "
                f"{s['total_sales_30d']}, {s['price_trend_pct']}) "
                f"ON CONFLICT (card_id, condition) DO UPDATE SET "
                f"avg_price_30d=EXCLUDED.avg_price_30d, median_price_30d=EXCLUDED.median_price_30d, "
                f"min_price_30d=EXCLUDED.min_price_30d, max_price_30d=EXCLUDED.max_price_30d, "
                f"total_sales_30d=EXCLUDED.total_sales_30d, price_trend_pct=EXCLUDED.price_trend_pct, "
                f"last_updated=now();\n"
            )

        f.write("\nCOMMIT;\n")

    logger.info("Exported SQL seed file to %s", filepath)
    return filepath


def export_json(players: list[dict], cards: list[dict],
                prices: list[dict], summaries: list[dict],
                output_dir: str = "output") -> str:
    """Export all data as JSON. Returns path to the generated file."""
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filepath = f"{output_dir}/seed_{timestamp}.json"

    data = {
        "generated_at": datetime.now().isoformat(),
        "stats": {
            "players": len(players),
            "cards": len(cards),
            "prices": len(prices),
            "summaries": len(summaries),
        },
        "players": players,
        "cards": cards,
        "prices": prices,
        "price_summaries": summaries,
    }

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    logger.info("Exported JSON data to %s", filepath)
    return filepath


def _sql_escape(text: str) -> str:
    if not text:
        return ""
    return text.replace("'", "''").replace("\\", "\\\\")


def _sql_val(text) -> str:
    """Wrap a non-null value as a quoted SQL string."""
    return "'" + _sql_escape(str(text)) + "'"


def _sql_nullable(text) -> str:
    """Return NULL or a quoted SQL string."""
    if not text:
        return "NULL"
    return "'" + _sql_escape(str(text)) + "'"
