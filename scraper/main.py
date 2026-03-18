#!/usr/bin/env python3
"""CardScope Data Pipeline — scrape, clean, and load real sports card data.

Usage:
    python main.py                          # Full pipeline: scrape + generate + export SQL
    python main.py --mode scrape-only       # Only scrape player data from APIs
    python main.py --mode generate-only     # Generate cards from hardcoded players (no API calls)
    python main.py --mode full              # Full pipeline with eBay price scraping
    python main.py --output supabase        # Upload directly to Supabase
    python main.py --output sql             # Export as SQL file (default)
    python main.py --output json            # Export as JSON file
    python main.py --sport NBA              # Only process NBA data
    python main.py --max-cards 5            # Max cards per player
    python main.py --skip-ebay              # Skip eBay price scraping
    python main.py --ebay-sample 20         # Only scrape eBay for top N cards
"""

import sys
import os
import argparse
import logging
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scrapers.nba_players import fetch_nba_players
from scrapers.mlb_players import fetch_mlb_players
from scrapers.nfl_players import fetch_nfl_players
from scrapers.soccer_players import fetch_soccer_players
from scrapers.card_catalog import generate_cards
from scrapers.ebay_prices import scrape_ebay_sold_prices
from scrapers.price_generator import generate_price_records
from cleaners.data_cleaner import (
    clean_players,
    clean_cards,
    clean_prices,
    update_card_prices_from_sales,
    compute_price_summaries,
)
from db.supabase_loader import SupabaseLoader, export_sql, export_json

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("pipeline")


def parse_args():
    parser = argparse.ArgumentParser(description="CardScope Data Pipeline")
    parser.add_argument("--mode", choices=["full", "scrape-only", "generate-only"],
                        default="full", help="Pipeline mode")
    parser.add_argument("--output", choices=["sql", "json", "supabase", "all"],
                        default="sql", help="Output destination")
    parser.add_argument("--sport", choices=["NBA", "MLB", "NFL", "Soccer"],
                        help="Only process a specific sport")
    parser.add_argument("--max-cards", type=int, default=8,
                        help="Max cards to generate per player (default: 8)")
    parser.add_argument("--skip-ebay", action="store_true",
                        help="Skip eBay price scraping")
    parser.add_argument("--ebay-sample", type=int, default=0,
                        help="Only scrape eBay for top N cards (0 = all)")
    parser.add_argument("--output-dir", default="output",
                        help="Output directory for SQL/JSON files")
    return parser.parse_args()


def fetch_players(sport_filter=None, mode="full"):
    """Fetch players from APIs or use hardcoded data."""
    all_players = []

    fetchers = {
        "NBA": fetch_nba_players,
        "MLB": fetch_mlb_players,
        "NFL": fetch_nfl_players,
        "Soccer": fetch_soccer_players,
    }

    sports = [sport_filter] if sport_filter else ["NBA", "MLB", "NFL", "Soccer"]

    for sport in sports:
        fetcher = fetchers.get(sport)
        if not fetcher:
            continue
        logger.info("Fetching %s players...", sport)
        start = time.time()
        try:
            players = fetcher()
            elapsed = time.time() - start
            logger.info("Got %d %s players in %.1fs", len(players), sport, elapsed)
            all_players.extend(players)
        except Exception as e:
            logger.error("Failed to fetch %s players: %s", sport, e)

    logger.info("Total players fetched: %d", len(all_players))
    return all_players


def run_pipeline(args):
    """Execute the full data pipeline."""
    start_time = time.time()
    logger.info("=" * 60)
    logger.info("CardScope Data Pipeline")
    logger.info("Mode: %s | Output: %s | Sport: %s",
                args.mode, args.output, args.sport or "All")
    logger.info("=" * 60)

    # Step 1: Fetch players
    logger.info("\n>>> Step 1: Fetching player data...")
    raw_players = fetch_players(args.sport, args.mode)

    # Step 2: Clean players
    logger.info("\n>>> Step 2: Cleaning player data...")
    players = clean_players(raw_players)
    logger.info("Clean players: %d", len(players))

    # Step 3: Generate cards
    logger.info("\n>>> Step 3: Generating card catalog...")
    raw_cards = generate_cards(players, max_cards_per_player=args.max_cards)

    # Step 4: Clean cards
    logger.info("\n>>> Step 4: Cleaning card data...")
    cards = clean_cards(raw_cards)
    logger.info("Clean cards: %d", len(cards))

    # Step 5: Scrape eBay prices (optional) + fallback price generation
    prices = []
    if not args.skip_ebay and args.mode != "generate-only":
        logger.info("\n>>> Step 5: Scraping eBay sold prices...")
        cards_to_scrape = cards
        if args.ebay_sample > 0:
            cards_to_scrape = sorted(cards, key=lambda c: c["current_price"], reverse=True)[:args.ebay_sample]
            logger.info("Scraping eBay for top %d cards by price", len(cards_to_scrape))

        raw_prices = scrape_ebay_sold_prices(cards_to_scrape)
        prices = clean_prices(raw_prices)
        logger.info("eBay prices: %d", len(prices))

        if prices:
            logger.info("Updating card prices from eBay data...")
            cards = update_card_prices_from_sales(cards, prices)

    if not prices:
        logger.info("\n>>> Step 5b: Generating realistic price records (eBay fallback)...")
        raw_prices = generate_price_records(cards, sales_per_card=6)
        prices = clean_prices(raw_prices)
        logger.info("Generated prices: %d", len(prices))
        if prices:
            cards = update_card_prices_from_sales(cards, prices)

    # Step 6: Compute price summaries
    logger.info("\n>>> Step 6: Computing price summaries...")
    summaries = compute_price_summaries(cards, prices)
    logger.info("Price summaries: %d", len(summaries))

    # Step 7: Output
    logger.info("\n>>> Step 7: Outputting data...")
    output_paths = []

    if args.output in ("sql", "all"):
        path = export_sql(players, cards, prices, summaries, args.output_dir)
        output_paths.append(("SQL", path))

    if args.output in ("json", "all"):
        path = export_json(players, cards, prices, summaries, args.output_dir)
        output_paths.append(("JSON", path))

    if args.output in ("supabase", "all"):
        loader = SupabaseLoader()
        if loader.is_configured:
            stats = loader.load_all(players, cards, prices, summaries)
            output_paths.append(("Supabase", str(stats)))
        else:
            logger.error(
                "Supabase not configured! Set SUPABASE_URL and SUPABASE_SERVICE_KEY "
                "environment variables or in .env file."
            )
            if args.output == "supabase":
                logger.info("Falling back to SQL export...")
                path = export_sql(players, cards, prices, summaries, args.output_dir)
                output_paths.append(("SQL (fallback)", path))

    elapsed = time.time() - start_time

    # Summary
    logger.info("\n" + "=" * 60)
    logger.info("Pipeline Complete!")
    logger.info("-" * 60)
    logger.info("Players:          %d", len(players))
    logger.info("Cards:            %d", len(cards))
    logger.info("Price records:    %d", len(prices))
    logger.info("Price summaries:  %d", len(summaries))
    logger.info("Time elapsed:     %.1fs", elapsed)
    for label, path in output_paths:
        logger.info("Output (%s):  %s", label, path)
    logger.info("=" * 60)

    return {
        "players": len(players),
        "cards": len(cards),
        "prices": len(prices),
        "summaries": len(summaries),
        "outputs": output_paths,
    }


if __name__ == "__main__":
    args = parse_args()
    result = run_pipeline(args)
