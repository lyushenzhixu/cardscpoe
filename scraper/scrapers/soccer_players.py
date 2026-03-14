"""Fetch Soccer player data from TheSportsDB and hardcoded top players."""

import time
import logging
import requests
from config import REQUEST_TIMEOUT, REQUEST_DELAY, USER_AGENT

logger = logging.getLogger(__name__)

SPORTSDB_SEARCH_URL = "https://www.thesportsdb.com/api/v1/json/3/searchplayers.php"

TOP_SOCCER_PLAYERS = [
    ("Lionel Messi", "Inter Miami", "Forward"),
    ("Cristiano Ronaldo", "Al Nassr", "Forward"),
    ("Kylian Mbappe", "Real Madrid", "Forward"),
    ("Erling Haaland", "Manchester City", "Forward"),
    ("Jude Bellingham", "Real Madrid", "Midfielder"),
    ("Vinicius Junior", "Real Madrid", "Forward"),
    ("Bukayo Saka", "Arsenal", "Forward"),
    ("Phil Foden", "Manchester City", "Midfielder"),
    ("Rodri", "Manchester City", "Midfielder"),
    ("Florian Wirtz", "Bayer Leverkusen", "Midfielder"),
    ("Jamal Musiala", "Bayern Munich", "Midfielder"),
    ("Lamine Yamal", "Barcelona", "Forward"),
    ("Pedri", "Barcelona", "Midfielder"),
    ("Gavi", "Barcelona", "Midfielder"),
    ("Robert Lewandowski", "Barcelona", "Forward"),
    ("Mohamed Salah", "Liverpool", "Forward"),
    ("Son Heung-min", "Tottenham Hotspur", "Forward"),
    ("Martin Odegaard", "Arsenal", "Midfielder"),
    ("Declan Rice", "Arsenal", "Midfielder"),
    ("Bruno Fernandes", "Manchester United", "Midfielder"),
    ("Marcus Rashford", "Manchester United", "Forward"),
    ("Rasmus Hojlund", "Manchester United", "Forward"),
    ("Cole Palmer", "Chelsea", "Midfielder"),
    ("Kevin De Bruyne", "Manchester City", "Midfielder"),
    ("Bernardo Silva", "Manchester City", "Midfielder"),
    ("Virgil van Dijk", "Liverpool", "Defender"),
    ("Trent Alexander-Arnold", "Liverpool", "Defender"),
    ("William Saliba", "Arsenal", "Defender"),
    ("Harry Kane", "Bayern Munich", "Forward"),
    ("Dani Olmo", "Barcelona", "Midfielder"),
    ("Joao Felix", "Chelsea", "Forward"),
    ("Victor Osimhen", "Napoli", "Forward"),
    ("Khvicha Kvaratskhelia", "Paris Saint-Germain", "Forward"),
    ("Ousmane Dembele", "Paris Saint-Germain", "Forward"),
    ("Antoine Griezmann", "Atletico Madrid", "Forward"),
    ("Federico Valverde", "Real Madrid", "Midfielder"),
    ("Toni Kroos", "Real Madrid (Retired)", "Midfielder"),
    ("Neymar Jr.", "Al Hilal", "Forward"),
    ("Lautaro Martinez", "Inter Milan", "Forward"),
    ("Rafael Leao", "AC Milan", "Forward"),
    ("Alejandro Garnacho", "Manchester United", "Forward"),
    ("Kobbie Mainoo", "Manchester United", "Midfielder"),
    ("Nico Williams", "Athletic Bilbao", "Forward"),
    ("Xavi Simons", "RB Leipzig", "Midfielder"),
    ("Endrick", "Real Madrid", "Forward"),
    ("Sandro Tonali", "Newcastle United", "Midfielder"),
    ("Alexander Isak", "Newcastle United", "Forward"),
    ("Julian Alvarez", "Atletico Madrid", "Forward"),
    ("Achraf Hakimi", "Paris Saint-Germain", "Defender"),
    ("Alisson Becker", "Liverpool", "Goalkeeper"),
]


def fetch_soccer_players() -> list[dict]:
    """Return Soccer player dicts."""
    players = []
    seen = set()
    headers = {"Accept": "application/json", "User-Agent": USER_AGENT}

    for name, team, pos in TOP_SOCCER_PLAYERS:
        search_name = name.replace(" ", "_")
        try:
            resp = requests.get(
                SPORTSDB_SEARCH_URL,
                params={"p": search_name},
                headers=headers,
                timeout=REQUEST_TIMEOUT,
            )
            if resp.status_code == 200:
                data = resp.json()
                entries = data.get("player") or []
                for entry in entries:
                    player_name = entry.get("strPlayer", "")
                    if not player_name:
                        continue
                    if player_name.lower() != name.lower() and name.lower() not in player_name.lower():
                        continue
                    sport_check = entry.get("strSport", "").lower()
                    if sport_check and "soccer" not in sport_check and "football" not in sport_check:
                        continue
                    headshot = entry.get("strCutout") or entry.get("strThumb") or ""
                    bio = entry.get("strDescriptionEN") or ""
                    fetched_team = entry.get("strTeam") or team
                    fetched_pos = entry.get("strPosition") or pos

                    if player_name.lower() not in seen:
                        players.append({
                            "name": player_name,
                            "sport": "Soccer",
                            "team": fetched_team,
                            "position": fetched_pos,
                            "headshot_url": headshot,
                            "bio": bio[:500] if bio else "",
                        })
                        seen.add(player_name.lower())
                    break
        except requests.RequestException as e:
            logger.warning("SportsDB request failed for %s: %s", name, e)

        time.sleep(REQUEST_DELAY)

    for name, team, pos in TOP_SOCCER_PLAYERS:
        if name.lower() not in seen:
            players.append({
                "name": name,
                "sport": "Soccer",
                "team": team,
                "position": pos,
                "headshot_url": "",
                "bio": "",
            })
            seen.add(name.lower())

    logger.info("Fetched %d Soccer players", len(players))
    return players
