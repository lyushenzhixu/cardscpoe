"""Fetch NBA player data from balldontlie.io and nba.com stats API."""

import time
import logging
import requests
from config import REQUEST_TIMEOUT, REQUEST_DELAY, USER_AGENT

logger = logging.getLogger(__name__)

BALLDONTLIE_URL = "https://api.balldontlie.io/v1/players"
NBA_STATS_URL = "https://stats.nba.com/stats/leagueLeaders"

TOP_NBA_PLAYERS = [
    "LeBron James", "Stephen Curry", "Kevin Durant", "Giannis Antetokounmpo",
    "Luka Doncic", "Nikola Jokic", "Joel Embiid", "Jayson Tatum",
    "Anthony Edwards", "Victor Wembanyama", "Shai Gilgeous-Alexander",
    "Ja Morant", "Devin Booker", "Donovan Mitchell", "Anthony Davis",
    "Damian Lillard", "Jimmy Butler", "Paul George", "Kawhi Leonard",
    "Trae Young", "Zion Williamson", "Tyrese Haliburton", "Chet Holmgren",
    "Paolo Banchero", "Tyrese Maxey", "De'Aaron Fox", "Lauri Markkanen",
    "Scottie Barnes", "Brandon Miller", "Jalen Brunson",
    "Kyrie Irving", "James Harden", "Russell Westbrook", "Chris Paul",
    "Klay Thompson", "Draymond Green", "Bam Adebayo", "Jalen Williams",
    "Cade Cunningham", "Franz Wagner", "Alperen Sengun", "Evan Mobley",
    "Desmond Bane", "Tyler Herro", "Mikal Bridges", "OG Anunoby",
    "Karl-Anthony Towns", "Domantas Sabonis", "Pascal Siakam", "Fred VanVleet",
]


def fetch_nba_players() -> list[dict]:
    """Return a list of NBA player dicts with keys: name, team, position, sport, headshot_url, bio."""
    players = []
    seen = set()
    headers = {"Accept": "application/json", "User-Agent": USER_AGENT}

    for name in TOP_NBA_PLAYERS:
        search_term = name.split()[-1]
        try:
            resp = requests.get(
                BALLDONTLIE_URL,
                params={"search": search_term, "per_page": 25},
                headers=headers,
                timeout=REQUEST_TIMEOUT,
            )
            if resp.status_code == 200:
                data = resp.json().get("data", [])
                for entry in data:
                    first = entry.get("first_name", "")
                    last = entry.get("last_name", "")
                    full = f"{first} {last}".strip()
                    if not full or full.lower() in seen:
                        continue
                    if full.lower() != name.lower():
                        continue

                    team_info = entry.get("team", {})
                    team = team_info.get("full_name", "") if team_info else ""
                    position = entry.get("position", "")

                    player_id = entry.get("id", "")
                    headshot = ""
                    if player_id:
                        nba_id = _get_nba_player_id(full)
                        if nba_id:
                            headshot = f"https://cdn.nba.com/headshots/nba/latest/1040x760/{nba_id}.png"

                    players.append({
                        "name": full,
                        "sport": "NBA",
                        "team": team or "Unknown",
                        "position": _normalize_nba_position(position),
                        "headshot_url": headshot,
                        "bio": "",
                    })
                    seen.add(full.lower())
                    break
            elif resp.status_code == 429:
                logger.warning("Rate limited by balldontlie, sleeping 5s")
                time.sleep(5)
        except requests.RequestException as e:
            logger.warning("balldontlie request failed for %s: %s", name, e)

        time.sleep(REQUEST_DELAY)

    if len(players) < 20:
        logger.info("Supplementing with hardcoded NBA players (%d found so far)", len(players))
        players = _supplement_nba_players(players, seen)

    logger.info("Fetched %d NBA players", len(players))
    return players


NBA_PLAYER_IDS = {
    "LeBron James": 2544, "Stephen Curry": 201939, "Kevin Durant": 201142,
    "Giannis Antetokounmpo": 203507, "Luka Doncic": 1629029, "Nikola Jokic": 203999,
    "Joel Embiid": 203954, "Jayson Tatum": 1628369, "Anthony Edwards": 1630162,
    "Victor Wembanyama": 1641705, "Shai Gilgeous-Alexander": 1628983,
    "Ja Morant": 1629630, "Devin Booker": 1626164, "Donovan Mitchell": 1628378,
    "Anthony Davis": 203076, "Damian Lillard": 203081, "Jimmy Butler": 202710,
    "Paul George": 202331, "Kawhi Leonard": 202695, "Trae Young": 1629027,
    "Zion Williamson": 1629627, "Tyrese Haliburton": 1630169,
    "Chet Holmgren": 1631096, "Paolo Banchero": 1631094, "Tyrese Maxey": 1630178,
    "De'Aaron Fox": 1628368, "Lauri Markkanen": 1628374, "Scottie Barnes": 1630567,
    "Brandon Miller": 1641706, "Jalen Brunson": 1628973, "Kyrie Irving": 202681,
    "James Harden": 201935, "Russell Westbrook": 201566, "Chris Paul": 101108,
    "Klay Thompson": 202691, "Draymond Green": 203110, "Bam Adebayo": 1628389,
    "Jalen Williams": 1631114, "Cade Cunningham": 1630595, "Franz Wagner": 1630532,
    "Alperen Sengun": 1630578, "Evan Mobley": 1630596, "Desmond Bane": 1630217,
    "Tyler Herro": 1629639, "Mikal Bridges": 1628969, "OG Anunoby": 1628384,
    "Karl-Anthony Towns": 1626157, "Domantas Sabonis": 1627734,
    "Pascal Siakam": 1627783, "Fred VanVleet": 1627832,
}


def _get_nba_player_id(name: str) -> int | None:
    return NBA_PLAYER_IDS.get(name)


def _normalize_nba_position(pos: str) -> str:
    mapping = {
        "G": "Guard", "F": "Forward", "C": "Center",
        "G-F": "Guard-Forward", "F-G": "Forward-Guard",
        "F-C": "Forward-Center", "C-F": "Center-Forward",
    }
    return mapping.get(pos, pos or "Guard")


HARDCODED_NBA = [
    ("LeBron James", "Los Angeles Lakers", "Forward"),
    ("Stephen Curry", "Golden State Warriors", "Guard"),
    ("Kevin Durant", "Phoenix Suns", "Forward"),
    ("Giannis Antetokounmpo", "Milwaukee Bucks", "Forward"),
    ("Luka Doncic", "Dallas Mavericks", "Guard"),
    ("Nikola Jokic", "Denver Nuggets", "Center"),
    ("Joel Embiid", "Philadelphia 76ers", "Center"),
    ("Jayson Tatum", "Boston Celtics", "Forward"),
    ("Anthony Edwards", "Minnesota Timberwolves", "Guard"),
    ("Victor Wembanyama", "San Antonio Spurs", "Center"),
    ("Shai Gilgeous-Alexander", "Oklahoma City Thunder", "Guard"),
    ("Ja Morant", "Memphis Grizzlies", "Guard"),
    ("Devin Booker", "Phoenix Suns", "Guard"),
    ("Donovan Mitchell", "Cleveland Cavaliers", "Guard"),
    ("Anthony Davis", "Los Angeles Lakers", "Forward-Center"),
    ("Damian Lillard", "Milwaukee Bucks", "Guard"),
    ("Jimmy Butler", "Miami Heat", "Forward"),
    ("Paul George", "Philadelphia 76ers", "Forward"),
    ("Kawhi Leonard", "Los Angeles Clippers", "Forward"),
    ("Trae Young", "Atlanta Hawks", "Guard"),
    ("Zion Williamson", "New Orleans Pelicans", "Forward"),
    ("Tyrese Haliburton", "Indiana Pacers", "Guard"),
    ("Chet Holmgren", "Oklahoma City Thunder", "Center"),
    ("Paolo Banchero", "Orlando Magic", "Forward"),
    ("Tyrese Maxey", "Philadelphia 76ers", "Guard"),
    ("De'Aaron Fox", "Sacramento Kings", "Guard"),
    ("Lauri Markkanen", "Utah Jazz", "Forward"),
    ("Scottie Barnes", "Toronto Raptors", "Forward"),
    ("Brandon Miller", "Charlotte Hornets", "Forward"),
    ("Jalen Brunson", "New York Knicks", "Guard"),
    ("Kyrie Irving", "Dallas Mavericks", "Guard"),
    ("James Harden", "Los Angeles Clippers", "Guard"),
    ("Russell Westbrook", "Denver Nuggets", "Guard"),
    ("Chris Paul", "Golden State Warriors", "Guard"),
    ("Klay Thompson", "Dallas Mavericks", "Guard"),
    ("Draymond Green", "Golden State Warriors", "Forward"),
    ("Bam Adebayo", "Miami Heat", "Center"),
    ("Jalen Williams", "Oklahoma City Thunder", "Guard-Forward"),
    ("Cade Cunningham", "Detroit Pistons", "Guard"),
    ("Franz Wagner", "Orlando Magic", "Forward"),
    ("Alperen Sengun", "Houston Rockets", "Center"),
    ("Evan Mobley", "Cleveland Cavaliers", "Forward-Center"),
    ("Desmond Bane", "Memphis Grizzlies", "Guard"),
    ("Tyler Herro", "Miami Heat", "Guard"),
    ("Mikal Bridges", "New York Knicks", "Forward"),
    ("OG Anunoby", "New York Knicks", "Forward"),
    ("Karl-Anthony Towns", "New York Knicks", "Center"),
    ("Domantas Sabonis", "Sacramento Kings", "Center"),
    ("Pascal Siakam", "Indiana Pacers", "Forward"),
    ("Fred VanVleet", "Houston Rockets", "Guard"),
]


def _supplement_nba_players(existing: list[dict], seen: set) -> list[dict]:
    result = list(existing)
    for name, team, pos in HARDCODED_NBA:
        if name.lower() in seen:
            continue
        nba_id = _get_nba_player_id(name)
        headshot = f"https://cdn.nba.com/headshots/nba/latest/1040x760/{nba_id}.png" if nba_id else ""
        result.append({
            "name": name,
            "sport": "NBA",
            "team": team,
            "position": pos,
            "headshot_url": headshot,
            "bio": "",
        })
        seen.add(name.lower())
    return result
