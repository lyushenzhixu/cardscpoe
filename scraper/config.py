import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

REQUEST_TIMEOUT = 30
REQUEST_DELAY = 1.0
EBAY_DELAY = 2.0

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)

SPORTS = ["NBA", "MLB", "NFL", "Soccer"]

CARD_BRANDS = {
    "NBA": [
        {"brand": "Panini", "sets": [
            {"name": "Prizm", "parallels": ["Base", "Silver", "Red White Blue", "Blue", "Green", "Gold", "Black"]},
            {"name": "Select", "parallels": ["Base", "Concourse", "Premier Level", "Silver", "Tri-Color"]},
            {"name": "Donruss", "parallels": ["Base", "Press Proof", "Holo Orange Laser", "Holo Purple Laser"]},
            {"name": "Donruss Optic", "parallels": ["Base", "Holo", "Red", "Blue", "Purple"]},
            {"name": "Mosaic", "parallels": ["Base", "Silver", "Blue", "Green", "Pink Camo", "Gold"]},
            {"name": "National Treasures", "parallels": ["Base", "Gold", "Platinum"]},
            {"name": "Immaculate", "parallels": ["Base", "Gold", "Platinum"]},
            {"name": "Flawless", "parallels": ["Base", "Gold", "Emerald"]},
            {"name": "Court Kings", "parallels": ["Base", "Aurora", "Ruby"]},
            {"name": "Chronicles", "parallels": ["Base", "Pink", "Gold"]},
        ]},
        {"brand": "Topps", "sets": [
            {"name": "Topps Now", "parallels": ["Base", "Purple", "Blue", "Gold", "Black"]},
            {"name": "Bowman University Chrome", "parallels": ["Base", "Refractor", "Blue Refractor", "Gold Refractor"]},
            {"name": "Chrome", "parallels": ["Base", "Refractor", "Pink Refractor", "Gold Refractor"]},
        ]},
        {"brand": "Upper Deck", "sets": [
            {"name": "SP Authentic", "parallels": ["Base", "Limited"]},
        ]},
    ],
    "MLB": [
        {"brand": "Topps", "sets": [
            {"name": "Chrome", "parallels": ["Base", "Refractor", "Pink Refractor", "Gold Refractor", "Blue Refractor"]},
            {"name": "Series 1", "parallels": ["Base", "Gold", "Rainbow Foil", "Vintage Stock"]},
            {"name": "Series 2", "parallels": ["Base", "Gold", "Rainbow Foil"]},
            {"name": "Heritage", "parallels": ["Base", "Chrome", "Real One Autograph"]},
            {"name": "Finest", "parallels": ["Base", "Refractor", "Green Refractor", "Gold Refractor"]},
            {"name": "Bowman Chrome", "parallels": ["Base", "Refractor", "Blue Refractor", "Gold Refractor"]},
            {"name": "Bowman", "parallels": ["Base", "Paper", "Chrome", "Blue"]},
            {"name": "Stadium Club", "parallels": ["Base", "Chrome", "Red Foil"]},
            {"name": "Allen & Ginter", "parallels": ["Base", "Mini", "No Number"]},
            {"name": "Update Series", "parallels": ["Base", "Gold", "Rainbow Foil"]},
            {"name": "Topps Now", "parallels": ["Base", "Purple", "Blue", "Gold", "Black"]},
        ]},
        {"brand": "Panini", "sets": [
            {"name": "Prizm", "parallels": ["Base", "Silver", "Red White Blue", "Blue"]},
            {"name": "Donruss", "parallels": ["Base", "Holo Orange", "Press Proof"]},
        ]},
    ],
    "NFL": [
        {"brand": "Panini", "sets": [
            {"name": "Prizm", "parallels": ["Base", "Silver", "Red White Blue", "Blue", "Green", "Gold", "Black"]},
            {"name": "Select", "parallels": ["Base", "Concourse", "Premier Level", "Silver", "Tri-Color"]},
            {"name": "Donruss", "parallels": ["Base", "Press Proof", "Holo Orange Laser"]},
            {"name": "Donruss Optic", "parallels": ["Base", "Holo", "Red", "Blue"]},
            {"name": "Mosaic", "parallels": ["Base", "Silver", "Blue", "Green", "Pink Camo"]},
            {"name": "National Treasures", "parallels": ["Base", "Gold", "Platinum"]},
            {"name": "Contenders", "parallels": ["Base", "Cracked Ice", "Championship Ticket"]},
            {"name": "Playbook", "parallels": ["Base", "Orange", "Green"]},
            {"name": "Chronicles", "parallels": ["Base", "Pink", "Gold"]},
            {"name": "Spectra", "parallels": ["Base", "Neon Blue", "Neon Green"]},
        ]},
        {"brand": "Topps", "sets": [
            {"name": "Topps Now", "parallels": ["Base", "Purple", "Blue", "Gold", "Black"]},
        ]},
    ],
    "Soccer": [
        {"brand": "Topps", "sets": [
            {"name": "Chrome UCL", "parallels": ["Base", "Refractor", "Pink Refractor", "Gold Refractor"]},
            {"name": "Merlin Chrome", "parallels": ["Base", "Refractor", "Blue Refractor"]},
            {"name": "Finest UCL", "parallels": ["Base", "Refractor", "Green Refractor"]},
            {"name": "Match Attax", "parallels": ["Base", "Limited Edition", "Crystal"]},
        ]},
        {"brand": "Panini", "sets": [
            {"name": "Prizm Premier League", "parallels": ["Base", "Silver", "Red White Blue", "Blue"]},
            {"name": "Prizm World Cup", "parallels": ["Base", "Silver", "Red White Blue", "Blue", "Gold"]},
            {"name": "Select", "parallels": ["Base", "Silver", "Tri-Color"]},
            {"name": "Donruss", "parallels": ["Base", "Press Proof", "Holo Orange"]},
            {"name": "National Treasures", "parallels": ["Base", "Gold"]},
            {"name": "Immaculate", "parallels": ["Base", "Gold"]},
        ]},
    ],
}

CARD_YEARS = ["2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025", "2026"]
