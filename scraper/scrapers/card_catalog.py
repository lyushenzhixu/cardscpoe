"""Generate a realistic card catalog from players + known brands/sets/years.

Uses real card numbering conventions and assigns realistic base prices
based on player popularity, card rarity, and rookie status.
"""

import random
import logging
from config import CARD_BRANDS, CARD_YEARS

logger = logging.getLogger(__name__)

ROOKIE_YEARS = {
    "LeBron James": "2003", "Stephen Curry": "2009", "Kevin Durant": "2007",
    "Giannis Antetokounmpo": "2013", "Luka Doncic": "2018", "Nikola Jokic": "2015",
    "Joel Embiid": "2016", "Jayson Tatum": "2017", "Anthony Edwards": "2020",
    "Victor Wembanyama": "2023", "Shai Gilgeous-Alexander": "2018",
    "Ja Morant": "2019", "Devin Booker": "2015", "Donovan Mitchell": "2017",
    "Anthony Davis": "2012", "Damian Lillard": "2012",
    "Shohei Ohtani": "2018", "Mike Trout": "2011", "Aaron Judge": "2017",
    "Juan Soto": "2018", "Ronald Acuna Jr.": "2018", "Mookie Betts": "2014",
    "Freddie Freeman": "2011", "Bryce Harper": "2012",
    "Julio Rodriguez": "2022", "Bobby Witt Jr.": "2022",
    "Corbin Carroll": "2023", "Gunnar Henderson": "2023",
    "Elly De La Cruz": "2023", "Paul Skenes": "2024",
    "Patrick Mahomes": "2017", "Josh Allen": "2018", "Lamar Jackson": "2018",
    "Joe Burrow": "2020", "Justin Herbert": "2020", "Jalen Hurts": "2020",
    "Trevor Lawrence": "2021", "CJ Stroud": "2023", "Caleb Williams": "2024",
    "Jayden Daniels": "2024", "Travis Kelce": "2013",
    "Justin Jefferson": "2020", "Ja'Marr Chase": "2021",
    "CeeDee Lamb": "2020", "Bijan Robinson": "2023",
    "Marvin Harrison Jr.": "2024", "Malik Nabers": "2024",
    "Lionel Messi": "2004", "Cristiano Ronaldo": "2003",
    "Kylian Mbappe": "2017", "Erling Haaland": "2019",
    "Jude Bellingham": "2020", "Vinicius Junior": "2019",
    "Bukayo Saka": "2019", "Phil Foden": "2019",
    "Lamine Yamal": "2023", "Cole Palmer": "2022",
    "Florian Wirtz": "2020", "Jamal Musiala": "2020",
    "Endrick": "2024",
    # 2025 NBA Draft Class
    "Cooper Flagg": "2025", "Dylan Harper": "2025", "Ace Bailey": "2025",
    "VJ Edgecombe": "2025", "Kasparas Jakucionis": "2025",
    "Kon Knueppel": "2025", "Tre Johnson": "2025",
    "Nolan Traore": "2025", "Khaman Maluach": "2025", "Egor Demin": "2025",
    # 2024 NBA Rising Stars
    "Dereck Lively II": "2023", "Amen Thompson": "2023",
    "Zach Edey": "2024", "Reed Sheppard": "2024",
    "Stephon Castle": "2024", "Dalton Knecht": "2024", "Yves Missi": "2024",
    # 2025 MLB Prospects
    "Roki Sasaki": "2025", "Travis Bazzana": "2024", "Charlie Condon": "2025",
    "Jac Caglianone": "2025", "Ethan Salas": "2025", "Roman Anthony": "2025",
    "Junior Caminero": "2024", "Colton Cowser": "2023",
    "Wyatt Langford": "2024", "Jackson Chourio": "2024",
    "James Wood": "2024", "Dylan Crews": "2024",
    "Masyn Winn": "2024", "Noelvi Marte": "2024", "Evan Carter": "2023",
    # 2025 NFL Draft Class
    "Cam Ward": "2025", "Shedeur Sanders": "2025", "Travis Hunter": "2025",
    "Ashton Jeanty": "2025", "Tetairoa McMillan": "2025",
    "Abdul Carter": "2025", "Mason Graham": "2025", "Will Campbell": "2025",
    "Jalon Walker": "2025", "Luther Burden III": "2025",
    "Bo Nix": "2024", "Brock Bowers": "2024", "Ladd McConkey": "2024",
    "Brian Thomas Jr.": "2024", "Xavier Worthy": "2024",
    # Soccer Rising Stars
    "Estevao Willian": "2025", "Mathys Tel": "2023",
    "Warren Zaire-Emery": "2023", "Pau Cubarsi": "2024",
    "Arda Guler": "2024", "Savinho": "2024",
    "Alejandro Baena": "2024", "Kenan Yildiz": "2024",
    "Joao Neves": "2024", "Jamie Bynoe-Gittens": "2024",
}

PLAYER_TIER = {
    1: [  # Superstars — highest card values
        "LeBron James", "Luka Doncic", "Victor Wembanyama", "Giannis Antetokounmpo",
        "Shohei Ohtani", "Mike Trout", "Aaron Judge",
        "Patrick Mahomes", "Josh Allen",
        "Lionel Messi", "Cristiano Ronaldo", "Kylian Mbappe", "Erling Haaland",
        # 2025 #1 Pick — massive hype
        "Cooper Flagg",
        # NFL 2025 top prospect
        "Travis Hunter",
    ],
    2: [  # All-Stars
        "Stephen Curry", "Kevin Durant", "Nikola Jokic", "Joel Embiid", "Jayson Tatum",
        "Anthony Edwards", "Shai Gilgeous-Alexander", "Ja Morant",
        "Juan Soto", "Ronald Acuna Jr.", "Mookie Betts", "Freddie Freeman", "Bryce Harper",
        "Lamar Jackson", "Joe Burrow", "Justin Herbert", "Travis Kelce",
        "Justin Jefferson", "Ja'Marr Chase", "CeeDee Lamb",
        "Jude Bellingham", "Vinicius Junior", "Bukayo Saka",
        "Lamine Yamal", "Cole Palmer",
        # New high-value additions
        "Dylan Harper", "Ace Bailey",
        "Roki Sasaki", "Jackson Chourio", "Bobby Witt Jr.", "Gunnar Henderson",
        "Cam Ward", "Shedeur Sanders", "Ashton Jeanty", "Brock Bowers",
        "Saquon Barkley", "Jayden Daniels",
        "Florian Wirtz", "Jamal Musiala", "Pau Cubarsi",
    ],
    3: [],  # Everyone else
}

TIER_NAMES = set()
for t in PLAYER_TIER.values():
    TIER_NAMES.update(n.lower() for n in t)


def _get_tier(name: str) -> int:
    nl = name.lower()
    for tier, names in PLAYER_TIER.items():
        if nl in {n.lower() for n in names}:
            return tier
    return 3


def _base_price(tier: int, parallel: str, is_rookie: bool) -> int:
    tier_base = {1: 120, 2: 60, 3: 20}
    parallel_mult = {
        "Base": 1.0, "Silver": 2.5, "Holo": 2.0, "Refractor": 2.5,
        "Pink Refractor": 3.0, "Gold Refractor": 8.0, "Blue Refractor": 4.0,
        "Red White Blue": 2.0, "Blue": 3.0, "Green": 3.5,
        "Gold": 10.0, "Black": 15.0, "Platinum": 30.0,
        "Concourse": 1.0, "Premier Level": 1.5, "Tri-Color": 3.0,
        "Press Proof": 2.0, "Holo Orange Laser": 3.0, "Holo Purple Laser": 4.0,
        "Red": 4.0, "Purple": 5.0, "Pink Camo": 3.5, "Emerald": 12.0,
        "Aurora": 2.5, "Ruby": 4.0, "Pink": 2.5, "Crystal": 3.0,
        "Chrome": 2.0, "Real One Autograph": 15.0,
        "Paper": 0.8, "Mini": 1.5, "No Number": 5.0,
        "Rainbow Foil": 3.0, "Vintage Stock": 6.0,
        "Limited": 5.0, "Limited Edition": 5.0,
        "Cracked Ice": 8.0, "Championship Ticket": 20.0,
        "Orange": 3.0, "Neon Blue": 4.0, "Neon Green": 4.0,
        "Red Foil": 3.0, "Green Refractor": 3.5,
        "Holo Orange": 3.0,
    }
    base = tier_base.get(tier, 20)
    mult = parallel_mult.get(parallel, 1.5)
    price = int(base * mult)
    if is_rookie:
        price = int(price * 2.5)
    price = int(price * random.uniform(0.8, 1.2))
    return max(1, price)


def generate_cards(players: list[dict], max_cards_per_player: int = 8) -> list[dict]:
    """Generate realistic card entries for a list of players.

    Returns list of card dicts matching the cards table schema.
    """
    cards = []
    card_num_counter = {}

    random.seed(42)

    for player in players:
        sport = player["sport"]
        name = player["name"]
        team = player["team"]
        position = player["position"]
        headshot_url = player.get("headshot_url", "")
        tier = _get_tier(name)
        rookie_year = ROOKIE_YEARS.get(name)

        brand_configs = CARD_BRANDS.get(sport, [])
        if not brand_configs:
            continue

        cards_generated = 0
        for brand_config in brand_configs:
            if cards_generated >= max_cards_per_player:
                break
            brand = brand_config["brand"]
            for set_config in brand_config["sets"]:
                if cards_generated >= max_cards_per_player:
                    break
                set_name = set_config["name"]
                parallels = set_config["parallels"]

                if tier == 3 and random.random() < 0.5:
                    continue

                for year in CARD_YEARS:
                    if cards_generated >= max_cards_per_player:
                        break

                    if tier == 3 and random.random() < 0.7:
                        continue
                    if tier == 2 and random.random() < 0.4:
                        continue

                    is_rookie = (rookie_year == year)

                    parallel = random.choice(parallels)
                    if tier == 1 and random.random() < 0.3:
                        rare_parallels = [p for p in parallels if p != "Base"]
                        if rare_parallels:
                            parallel = random.choice(rare_parallels)

                    key = f"{brand}-{set_name}-{year}"
                    if key not in card_num_counter:
                        card_num_counter[key] = random.randint(1, 50)
                    card_num_counter[key] += random.randint(1, 10)
                    card_number = str(card_num_counter[key])

                    base = _base_price(tier, parallel, is_rookie)
                    raw_low = max(1, int(base * 0.7))
                    raw_high = max(raw_low + 1, int(base * 1.3))
                    psa9_low = max(raw_high + 1, int(base * 1.8))
                    psa9_high = max(psa9_low + 1, int(base * 2.5))
                    psa10_low = max(psa9_high + 1, int(base * 3.0))
                    psa10_high = max(psa10_low + 1, int(base * 4.5))
                    current = random.randint(raw_low, psa9_high)
                    change = round(random.uniform(-15.0, 35.0), 1)

                    cards.append({
                        "player_name": name,
                        "team": team,
                        "position": position,
                        "sport": sport,
                        "brand": brand,
                        "set_name": set_name,
                        "year": year,
                        "card_number": card_number,
                        "parallel": parallel,
                        "is_rookie": is_rookie,
                        "raw_price_low": raw_low,
                        "raw_price_high": raw_high,
                        "psa9_price_low": psa9_low,
                        "psa9_price_high": psa9_high,
                        "psa10_price_low": psa10_low,
                        "psa10_price_high": psa10_high,
                        "current_price": current,
                        "price_change": change,
                        "confidence": round(random.uniform(85.0, 99.0), 1),
                        "grade": None,
                        "image_url": None,
                        "headshot_url": headshot_url or None,
                    })
                    cards_generated += 1

    logger.info("Generated %d cards for %d players", len(cards), len(players))
    return cards
