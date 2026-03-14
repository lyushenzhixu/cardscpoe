"""Fetch NFL player data from ESPN public API."""

import time
import logging
import requests
from config import REQUEST_TIMEOUT, REQUEST_DELAY

logger = logging.getLogger(__name__)

ESPN_NFL_TEAMS_URL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams"
ESPN_NFL_ROSTER_URL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/{team_id}/roster"

TOP_NFL_PLAYERS = [
    "Patrick Mahomes", "Josh Allen", "Lamar Jackson", "Joe Burrow", "Justin Herbert",
    "Jalen Hurts", "Trevor Lawrence", "Tua Tagovailoa", "CJ Stroud", "Caleb Williams",
    "Jayden Daniels", "Drake Maye", "Travis Kelce", "Tyreek Hill", "Justin Jefferson",
    "Ja'Marr Chase", "CeeDee Lamb", "Davante Adams", "Amon-Ra St. Brown",
    "A.J. Brown", "Stefon Diggs", "Puka Nacua", "Garrett Wilson", "Chris Olave",
    "Derrick Henry", "Bijan Robinson", "Saquon Barkley", "Jonathan Taylor",
    "Christian McCaffrey", "Josh Jacobs", "Breece Hall", "Travis Etienne Jr.",
    "Jahmyr Gibbs", "Nick Chubb", "Micah Parsons", "Myles Garrett",
    "T.J. Watt", "Nick Bosa", "Aaron Donald", "Fred Warner",
    "Sauce Gardner", "Jalen Ramsey", "Patrick Surtain II", "Roquan Smith",
    "Dexter Lawrence", "Chris Jones", "Aidan Hutchinson", "Will Anderson Jr.",
    "Marvin Harrison Jr.", "Malik Nabers",
]


def fetch_nfl_players() -> list[dict]:
    """Return NFL player dicts."""
    players = []
    seen = set()

    teams = _fetch_espn_nfl_teams()
    if not teams:
        logger.warning("ESPN NFL API unavailable, using hardcoded data")
        return _hardcoded_nfl_players()

    for team in teams:
        team_id = team.get("id")
        team_name = team.get("displayName", "")
        roster = _fetch_espn_roster(team_id, team_name)
        for p in roster:
            name_lower = p["name"].lower()
            if name_lower not in seen:
                players.append(p)
                seen.add(name_lower)
        time.sleep(REQUEST_DELAY * 0.5)

    top_set = {n.lower() for n in TOP_NFL_PLAYERS}
    prioritized = [p for p in players if p["name"].lower() in top_set]
    others = [p for p in players if p["name"].lower() not in top_set]
    players = prioritized + others[:max(0, 80 - len(prioritized))]

    if len(players) < 20:
        players = _supplement(players, seen)

    logger.info("Fetched %d NFL players", len(players))
    return players


def _fetch_espn_nfl_teams() -> list[dict]:
    try:
        resp = requests.get(ESPN_NFL_TEAMS_URL, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 200:
            data = resp.json()
            sports = data.get("sports", [{}])
            leagues = sports[0].get("leagues", [{}]) if sports else [{}]
            return leagues[0].get("teams", []) if leagues else []
    except requests.RequestException as e:
        logger.warning("ESPN NFL teams fetch failed: %s", e)
    return []


def _fetch_espn_roster(team_id: str, team_name: str) -> list[dict]:
    result = []
    try:
        url = ESPN_NFL_ROSTER_URL.format(team_id=team_id)
        resp = requests.get(url, timeout=REQUEST_TIMEOUT)
        if resp.status_code != 200:
            return result
        data = resp.json()
        athletes = data.get("athletes", [])
        for group in athletes:
            items = group.get("items", [])
            for athlete in items:
                name = athlete.get("displayName", "") or athlete.get("fullName", "")
                pos = athlete.get("position", {}).get("abbreviation", "")
                headshot = athlete.get("headshot", {}).get("href", "")
                if not name:
                    continue
                result.append({
                    "name": name,
                    "sport": "NFL",
                    "team": team_name,
                    "position": _normalize_nfl_position(pos),
                    "headshot_url": headshot,
                    "bio": "",
                })
    except requests.RequestException as e:
        logger.warning("ESPN roster fetch failed for %s: %s", team_name, e)
    return result


def _normalize_nfl_position(pos: str) -> str:
    mapping = {
        "QB": "Quarterback", "RB": "Running Back", "WR": "Wide Receiver",
        "TE": "Tight End", "OT": "Offensive Tackle", "OG": "Offensive Guard",
        "C": "Center", "DE": "Defensive End", "DT": "Defensive Tackle",
        "OLB": "Outside Linebacker", "ILB": "Inside Linebacker",
        "MLB": "Middle Linebacker", "CB": "Cornerback", "S": "Safety",
        "FS": "Free Safety", "SS": "Strong Safety", "K": "Kicker",
        "P": "Punter", "LS": "Long Snapper", "FB": "Fullback",
        "LB": "Linebacker", "DB": "Defensive Back", "DL": "Defensive Line",
        "OL": "Offensive Line", "EDGE": "Edge Rusher",
    }
    return mapping.get(pos, pos or "Unknown")


HARDCODED_NFL = [
    ("Patrick Mahomes", "Kansas City Chiefs", "Quarterback"),
    ("Josh Allen", "Buffalo Bills", "Quarterback"),
    ("Lamar Jackson", "Baltimore Ravens", "Quarterback"),
    ("Joe Burrow", "Cincinnati Bengals", "Quarterback"),
    ("Justin Herbert", "Los Angeles Chargers", "Quarterback"),
    ("Jalen Hurts", "Philadelphia Eagles", "Quarterback"),
    ("Trevor Lawrence", "Jacksonville Jaguars", "Quarterback"),
    ("Tua Tagovailoa", "Miami Dolphins", "Quarterback"),
    ("CJ Stroud", "Houston Texans", "Quarterback"),
    ("Caleb Williams", "Chicago Bears", "Quarterback"),
    ("Jayden Daniels", "Washington Commanders", "Quarterback"),
    ("Drake Maye", "New England Patriots", "Quarterback"),
    ("Travis Kelce", "Kansas City Chiefs", "Tight End"),
    ("Tyreek Hill", "Miami Dolphins", "Wide Receiver"),
    ("Justin Jefferson", "Minnesota Vikings", "Wide Receiver"),
    ("Ja'Marr Chase", "Cincinnati Bengals", "Wide Receiver"),
    ("CeeDee Lamb", "Dallas Cowboys", "Wide Receiver"),
    ("Davante Adams", "New York Jets", "Wide Receiver"),
    ("Amon-Ra St. Brown", "Detroit Lions", "Wide Receiver"),
    ("A.J. Brown", "Philadelphia Eagles", "Wide Receiver"),
    ("Puka Nacua", "Los Angeles Rams", "Wide Receiver"),
    ("Garrett Wilson", "New York Jets", "Wide Receiver"),
    ("Chris Olave", "New Orleans Saints", "Wide Receiver"),
    ("Derrick Henry", "Baltimore Ravens", "Running Back"),
    ("Bijan Robinson", "Atlanta Falcons", "Running Back"),
    ("Saquon Barkley", "Philadelphia Eagles", "Running Back"),
    ("Jonathan Taylor", "Indianapolis Colts", "Running Back"),
    ("Christian McCaffrey", "San Francisco 49ers", "Running Back"),
    ("Josh Jacobs", "Green Bay Packers", "Running Back"),
    ("Breece Hall", "New York Jets", "Running Back"),
    ("Travis Etienne Jr.", "Jacksonville Jaguars", "Running Back"),
    ("Jahmyr Gibbs", "Detroit Lions", "Running Back"),
    ("Nick Chubb", "Cleveland Browns", "Running Back"),
    ("Micah Parsons", "Dallas Cowboys", "Linebacker"),
    ("Myles Garrett", "Cleveland Browns", "Defensive End"),
    ("T.J. Watt", "Pittsburgh Steelers", "Outside Linebacker"),
    ("Nick Bosa", "San Francisco 49ers", "Defensive End"),
    ("Fred Warner", "San Francisco 49ers", "Linebacker"),
    ("Sauce Gardner", "New York Jets", "Cornerback"),
    ("Jalen Ramsey", "Miami Dolphins", "Cornerback"),
    ("Patrick Surtain II", "Denver Broncos", "Cornerback"),
    ("Roquan Smith", "Baltimore Ravens", "Linebacker"),
    ("Dexter Lawrence", "New York Giants", "Defensive Tackle"),
    ("Chris Jones", "Kansas City Chiefs", "Defensive Tackle"),
    ("Aidan Hutchinson", "Detroit Lions", "Defensive End"),
    ("Will Anderson Jr.", "Houston Texans", "Edge Rusher"),
    ("Marvin Harrison Jr.", "Arizona Cardinals", "Wide Receiver"),
    ("Malik Nabers", "New York Giants", "Wide Receiver"),
]


def _hardcoded_nfl_players() -> list[dict]:
    return [
        {"name": n, "sport": "NFL", "team": t, "position": p, "headshot_url": "", "bio": ""}
        for n, t, p in HARDCODED_NFL
    ]


def _supplement(existing: list[dict], seen: set) -> list[dict]:
    result = list(existing)
    for name, team, pos in HARDCODED_NFL:
        if name.lower() in seen:
            continue
        result.append({
            "name": name, "sport": "NFL", "team": team, "position": pos,
            "headshot_url": "", "bio": "",
        })
        seen.add(name.lower())
    return result
