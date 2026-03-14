"""Fetch MLB player data from the MLB Stats API (free, no auth)."""

import time
import logging
import requests
from config import REQUEST_TIMEOUT, REQUEST_DELAY

logger = logging.getLogger(__name__)

MLB_ROSTER_URL = "https://statsapi.mlb.com/api/v1/teams/{team_id}/roster/active"
MLB_PEOPLE_URL = "https://statsapi.mlb.com/api/v1/people/{player_id}"
MLB_TEAMS_URL = "https://statsapi.mlb.com/api/v1/teams?sportId=1"

TOP_MLB_PLAYERS = [
    "Shohei Ohtani", "Mike Trout", "Mookie Betts", "Aaron Judge", "Ronald Acuna Jr.",
    "Juan Soto", "Freddie Freeman", "Trea Turner", "Corey Seager", "Manny Machado",
    "Fernando Tatis Jr.", "Bryce Harper", "Julio Rodriguez", "Bobby Witt Jr.",
    "Corbin Carroll", "Gunnar Henderson", "Adley Rutschman", "Jackson Holliday",
    "Elly De La Cruz", "Paul Skenes", "Spencer Strider", "Gerrit Cole",
    "Max Scherzer", "Justin Verlander", "Clayton Kershaw", "Jacob deGrom",
    "Yoshinobu Yamamoto", "Pete Alonso", "Vladimir Guerrero Jr.", "Bo Bichette",
    "Rafael Devers", "Wander Franco", "Marcus Semien", "Jose Ramirez",
    "Matt Olson", "Ozzie Albies", "Austin Riley", "Jazz Chisholm Jr.",
    "Kyle Tucker", "Yordan Alvarez", "Jose Altuve", "Alex Bregman",
    "Cody Bellinger", "Ian Happ", "Dansby Swanson", "Nico Hoerner",
    "Xander Bogaerts", "Luis Robert Jr.", "Ke'Bryan Hayes", "CJ Abrams",
]


def fetch_mlb_players() -> list[dict]:
    """Return MLB player dicts with keys: name, team, position, sport, headshot_url, bio."""
    players = []
    seen = set()

    teams = _fetch_mlb_teams()
    if not teams:
        logger.warning("MLB teams API unavailable, using hardcoded data")
        return _hardcoded_mlb_players()

    all_roster_players = []
    for team in teams:
        team_id = team.get("id")
        team_name = team.get("name", "")
        roster = _fetch_team_roster(team_id, team_name)
        all_roster_players.extend(roster)
        time.sleep(REQUEST_DELAY * 0.5)

    top_set = {n.lower() for n in TOP_MLB_PLAYERS}
    for rp in all_roster_players:
        name_lower = rp["name"].lower()
        if name_lower in top_set and name_lower not in seen:
            players.append(rp)
            seen.add(name_lower)

    for rp in all_roster_players:
        name_lower = rp["name"].lower()
        if name_lower not in seen and len(players) < 80:
            players.append(rp)
            seen.add(name_lower)

    if len(players) < 20:
        players = _supplement(players, seen)

    logger.info("Fetched %d MLB players", len(players))
    return players


def _fetch_mlb_teams() -> list[dict]:
    try:
        resp = requests.get(MLB_TEAMS_URL, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 200:
            return resp.json().get("teams", [])
    except requests.RequestException as e:
        logger.warning("MLB teams fetch failed: %s", e)
    return []


def _fetch_team_roster(team_id: int, team_name: str) -> list[dict]:
    result = []
    try:
        url = MLB_ROSTER_URL.format(team_id=team_id)
        resp = requests.get(url, timeout=REQUEST_TIMEOUT)
        if resp.status_code != 200:
            return result
        roster = resp.json().get("roster", [])
        for entry in roster:
            person = entry.get("person", {})
            pid = person.get("id")
            name = person.get("fullName", "")
            pos = entry.get("position", {}).get("abbreviation", "")
            if not name:
                continue
            headshot = f"https://img.mlbstatic.com/mlb-photos/image/upload/d_people:generic:headshot:67:current.png/w_213,q_auto:best/v1/people/{pid}/headshot/67/current" if pid else ""
            result.append({
                "name": name,
                "sport": "MLB",
                "team": team_name,
                "position": _normalize_mlb_position(pos),
                "headshot_url": headshot,
                "bio": "",
            })
    except requests.RequestException as e:
        logger.warning("MLB roster fetch failed for team %s: %s", team_name, e)
    return result


def _normalize_mlb_position(pos: str) -> str:
    mapping = {
        "P": "Pitcher", "C": "Catcher", "1B": "First Base", "2B": "Second Base",
        "3B": "Third Base", "SS": "Shortstop", "LF": "Left Field", "CF": "Center Field",
        "RF": "Right Field", "DH": "Designated Hitter", "OF": "Outfield",
        "IF": "Infield", "UT": "Utility", "RP": "Relief Pitcher", "SP": "Starting Pitcher",
        "TWP": "Two-Way Player",
    }
    return mapping.get(pos, pos or "Unknown")


HARDCODED_MLB = [
    ("Shohei Ohtani", "Los Angeles Dodgers", "Designated Hitter"),
    ("Mike Trout", "Los Angeles Angels", "Center Field"),
    ("Mookie Betts", "Los Angeles Dodgers", "Shortstop"),
    ("Aaron Judge", "New York Yankees", "Right Field"),
    ("Ronald Acuna Jr.", "Atlanta Braves", "Right Field"),
    ("Juan Soto", "New York Yankees", "Left Field"),
    ("Freddie Freeman", "Los Angeles Dodgers", "First Base"),
    ("Trea Turner", "Philadelphia Phillies", "Shortstop"),
    ("Corey Seager", "Texas Rangers", "Shortstop"),
    ("Manny Machado", "San Diego Padres", "Third Base"),
    ("Fernando Tatis Jr.", "San Diego Padres", "Right Field"),
    ("Bryce Harper", "Philadelphia Phillies", "First Base"),
    ("Julio Rodriguez", "Seattle Mariners", "Center Field"),
    ("Bobby Witt Jr.", "Kansas City Royals", "Shortstop"),
    ("Corbin Carroll", "Arizona Diamondbacks", "Left Field"),
    ("Gunnar Henderson", "Baltimore Orioles", "Shortstop"),
    ("Adley Rutschman", "Baltimore Orioles", "Catcher"),
    ("Jackson Holliday", "Baltimore Orioles", "Second Base"),
    ("Elly De La Cruz", "Cincinnati Reds", "Shortstop"),
    ("Paul Skenes", "Pittsburgh Pirates", "Pitcher"),
    ("Spencer Strider", "Atlanta Braves", "Pitcher"),
    ("Gerrit Cole", "New York Yankees", "Pitcher"),
    ("Max Scherzer", "Texas Rangers", "Pitcher"),
    ("Justin Verlander", "Houston Astros", "Pitcher"),
    ("Clayton Kershaw", "Los Angeles Dodgers", "Pitcher"),
    ("Jacob deGrom", "Texas Rangers", "Pitcher"),
    ("Yoshinobu Yamamoto", "Los Angeles Dodgers", "Pitcher"),
    ("Pete Alonso", "New York Mets", "First Base"),
    ("Vladimir Guerrero Jr.", "Toronto Blue Jays", "First Base"),
    ("Bo Bichette", "Toronto Blue Jays", "Shortstop"),
    ("Rafael Devers", "Boston Red Sox", "Third Base"),
    ("Marcus Semien", "Texas Rangers", "Second Base"),
    ("Jose Ramirez", "Cleveland Guardians", "Third Base"),
    ("Matt Olson", "Atlanta Braves", "First Base"),
    ("Ozzie Albies", "Atlanta Braves", "Second Base"),
    ("Austin Riley", "Atlanta Braves", "Third Base"),
    ("Jazz Chisholm Jr.", "New York Yankees", "Second Base"),
    ("Kyle Tucker", "Houston Astros", "Right Field"),
    ("Yordan Alvarez", "Houston Astros", "Designated Hitter"),
    ("Jose Altuve", "Houston Astros", "Second Base"),
    ("Alex Bregman", "Houston Astros", "Third Base"),
    ("Cody Bellinger", "Chicago Cubs", "Center Field"),
    ("Ian Happ", "Chicago Cubs", "Left Field"),
    ("Dansby Swanson", "Chicago Cubs", "Shortstop"),
    ("Nico Hoerner", "Chicago Cubs", "Second Base"),
    ("Xander Bogaerts", "San Diego Padres", "Shortstop"),
    ("Luis Robert Jr.", "Chicago White Sox", "Center Field"),
    ("Ke'Bryan Hayes", "Pittsburgh Pirates", "Third Base"),
    ("CJ Abrams", "Washington Nationals", "Shortstop"),
]


def _hardcoded_mlb_players() -> list[dict]:
    result = []
    for name, team, pos in HARDCODED_MLB:
        pid = None
        headshot = ""
        result.append({
            "name": name,
            "sport": "MLB",
            "team": team,
            "position": pos,
            "headshot_url": headshot,
            "bio": "",
        })
    return result


def _supplement(existing: list[dict], seen: set) -> list[dict]:
    result = list(existing)
    for name, team, pos in HARDCODED_MLB:
        if name.lower() in seen:
            continue
        result.append({
            "name": name,
            "sport": "MLB",
            "team": team,
            "position": pos,
            "headshot_url": "",
            "bio": "",
        })
        seen.add(name.lower())
    return result
