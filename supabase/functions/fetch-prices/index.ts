import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

type FetchPayload = {
  playerName: string;
  brand: string;
  setName: string;
  year: string;
  cardNumber: string;
};

type PriceResult = {
  currentPrice: number;
  priceChange: number;
  rawLow: number;
  rawHigh: number;
  psa9Low: number;
  psa9High: number;
  psa10Low: number;
  psa10High: number;
  history: Array<{ month: string; value: number }>;
  recentSales: Array<{ grade: string; date: string; price: number }>;
};

function mockResponse(seed: number): PriceResult {
  const currentPrice = Math.max(50, seed);
  const change = Number((((seed % 21) - 10) / 3).toFixed(1));
  return {
    currentPrice,
    priceChange: change,
    rawLow: Math.round(currentPrice * 0.85),
    rawHigh: Math.round(currentPrice * 1.12),
    psa9Low: Math.round(currentPrice * 1.35),
    psa9High: Math.round(currentPrice * 1.65),
    psa10Low: Math.round(currentPrice * 1.95),
    psa10High: Math.round(currentPrice * 2.45),
    history: [
      { month: "Jan", value: currentPrice * 0.76 },
      { month: "Feb", value: currentPrice * 0.8 },
      { month: "Mar", value: currentPrice * 0.82 },
      { month: "Apr", value: currentPrice * 0.87 },
      { month: "May", value: currentPrice * 0.92 },
      { month: "Jun", value: currentPrice * 0.95 },
      { month: "Jul", value: currentPrice * 0.97 },
      { month: "Aug", value: currentPrice * 1.01 },
      { month: "Sep", value: currentPrice * 0.98 },
      { month: "Oct", value: currentPrice * 1.03 },
      { month: "Nov", value: currentPrice * 1.06 },
      { month: "Dec", value: currentPrice * 1.08 },
    ],
    recentSales: [
      { grade: "Raw", date: "Mar 12", price: Math.round(currentPrice * 0.95) },
      { grade: "Raw", date: "Mar 09", price: Math.round(currentPrice * 0.9) },
      { grade: "PSA 9", date: "Mar 07", price: Math.round(currentPrice * 1.55) },
      { grade: "PSA 10", date: "Mar 03", price: Math.round(currentPrice * 2.2) },
    ],
  };
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const payload = (await req.json()) as FetchPayload;
  const seed = (
    `${payload.playerName}-${payload.brand}-${payload.setName}-${payload.year}-${payload.cardNumber}`
  )
    .split("")
    .reduce((acc, char) => acc + char.charCodeAt(0), 0) % 1200;

  // TODO: Plug real providers:
  // 1) eBay Browse API (sold listings)
  // 2) PriceCharting API
  // 3) Persist rollups to public.price_summary
  const result = mockResponse(seed);

  return Response.json(result, {
    headers: {
      "Cache-Control": "public, max-age=3600",
    },
  });
});
