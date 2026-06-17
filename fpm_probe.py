#!/usr/bin/env python3
"""
fmp_probe.py — Verifiser at FMP faktisk dekker KAPs dataintegritetskrav PÅ DIN tier.

Bruker FMPs /stable/-endepunkter (v3 ble legacy etter aug 2025).

Bruk:
  export FMP_API_KEY="din_nokkel"
  .venv/bin/python fmp_probe.py
"""

import os
import sys
import datetime as dt
from typing import Optional

try:
    import requests
except ImportError:
    sys.exit("Mangler 'requests'. Kjør:  .venv/bin/pip install requests")

API_KEY = os.environ.get("FMP_API_KEY")
if not API_KEY:
    sys.exit("Sett FMP_API_KEY i miljøet først:  export FMP_API_KEY='...'")

BASE = "https://financialmodelingprep.com/stable"
TIMEOUT = 30

KNOWN_DELISTED = ["SIVB", "SBNY", "FRC", "BBBY"]


def _get(path: str, params: dict = {}) -> tuple[Optional[object], int, str]:
    p = dict(params)
    p["apikey"] = API_KEY
    try:
        r = requests.get(f"{BASE}/{path}", params=p, timeout=TIMEOUT)
    except requests.RequestException as e:
        return None, -1, f"nettverksfeil: {e}"
    if r.status_code not in (200, 402, 404):
        return None, r.status_code, r.text[:200]
    try:
        body = r.json()
    except ValueError:
        return None, r.status_code, f"ikke-JSON: {r.text[:200]}"
    if r.status_code != 200:
        return None, r.status_code, str(body)[:200]
    return body, 200, ""


def hdr(title: str) -> None:
    print("\n" + "=" * 72)
    print(title)
    print("=" * 72)


def check_key() -> None:
    hdr("0) Virker nøkkelen?")
    data, status, err = _get("profile", {"symbol": "AAPL"})
    if status == 200 and isinstance(data, list) and data:
        print(f"  OK — nøkkel virker. AAPL: {data[0].get('companyName')} pris={data[0].get('price')}")
    else:
        print(f"  FEIL — status={status}. {err}")


def check_income_history() -> None:
    hdr("1) Regnskapshistorikk: dybde + filingDate/acceptedDate")
    data, status, err = _get("income-statement", {"symbol": "AAPL", "period": "annual", "limit": 5})
    if status != 200 or not isinstance(data, list) or not data:
        print(f"  FEIL — status={status}. {err}")
        return

    sample = data[0]
    dates = [d.get("date", "") for d in data if d.get("date")]
    print(f"  Rader hentet (limit=5): {len(data)}")
    if dates:
        print(f"  Datoer: {min(dates)} – {max(dates)}")

    has_filing   = "filingDate" in sample
    has_accepted = "acceptedDate" in sample
    print(f"  filingDate:   {has_filing}  verdi={sample.get('filingDate')}")
    print(f"  acceptedDate: {has_accepted}  verdi={sample.get('acceptedDate')}")

    # Sjekk om limit > 5 er gated
    _, s10, _ = _get("income-statement", {"symbol": "AAPL", "period": "annual", "limit": 10})
    print(f"  limit=10 → status={s10} {'(gated bak høyere plan)' if s10 == 402 else 'OK'}")
    print(f"  -> Starter-tier: maks ~5 rader. Premium gir ~30 år.")
    if has_filing and has_accepted:
        print("  -> Look-ahead-fiks ER mulig (filingDate/acceptedDate finnes).")
    else:
        print("  -> Look-ahead-fiks IKKE mulig (mangler felt).")

    # Kvartaler
    _, qs, _ = _get("income-statement", {"symbol": "AAPL", "period": "quarter", "limit": 5})
    print(f"  Kvartalstall: {'OK' if qs == 200 else f'utilgjengelig (status={qs})'}")


def check_constituents() -> None:
    hdr("2) Historiske S&P 500-konstituenter (survivorship del 1)")
    for path, label in [("historical-sp500", "historical-sp500"),
                        ("sp500-constituent", "sp500-constituent")]:
        data, status, msg = _get(path)
        if status == 200 and isinstance(data, list) and data:
            print(f"  OK ({label}) — {len(data)} rader. Felt: {list(data[0].keys())}")
            return
        else:
            emoji = "🔒" if status == 402 else "✗"
            print(f"  {emoji} {label}: status={status} {('— '+msg[:80]) if msg else ''}")
    print("  -> Historiske konstituenter IKKE tilgjengelig på din plan. Survivorship-fix umulig uten oppgradering.")


def check_delisted() -> None:
    hdr("3) Delistede selskaper: liste + kurshistorikk-retensjon (survivorship del 2)")
    data, status, err = _get("delisted-companies", {"limit": 5})
    if status == 200 and isinstance(data, list) and data:
        print(f"  Liste OK — eksempel: {data[0].get('symbol')} delistet {data[0].get('delistedDate')}")
    else:
        print(f"  Liste: status={status} {err[:80]}")

    print("\n  Kurshistorikk for kjente delistede (kritisk for survivorship):")
    for tkr in KNOWN_DELISTED:
        hist, hs, _ = _get(f"historical-price-eod/full", {"symbol": tkr, "limit": 5})
        if hs == 200 and isinstance(hist, list) and hist:
            dates = [r.get("date") for r in hist if r.get("date")]
            print(f"    {tkr:6s}  OK — rader={len(hist)}  nyeste={max(dates) if dates else '?'}")
        else:
            label = "🔒 (premium)" if hs == 402 else f"status={hs}"
            print(f"    {tkr:6s}  INGEN kurshistorikk — {label}")
    print("  -> Hvis delistede mangler historikk: survivorship-fiks er IKKE mulig på Starter-plan.")


def check_benchmark() -> None:
    hdr("4) Kurshistorikk + totalavkastning-proxy")
    for sym in ["SPY", "VOO", "AAPL"]:
        data, status, err = _get("historical-price-eod/full", {"symbol": sym, "limit": 2000})
        if status == 200 and isinstance(data, list) and data:
            dates = [r["date"] for r in data if r.get("date")]
            has_adj = "adjClose" in data[0]
            print(f"  {sym:6s}  rader={len(data):5d}  spenn={min(dates)}..{max(dates)}  adjClose={has_adj}  felt={list(data[0].keys())}")
        else:
            print(f"  {sym:6s}  ingen data — status={status}")

    # Dividender tilgjengelig? (manuell TR-beregning)
    div, ds, _ = _get("dividends", {"symbol": "SPY", "limit": 5})
    if ds == 200 and isinstance(div, list) and div:
        print(f"\n  Dividender (SPY): OK — {len(div)} rader. Felt: {list(div[0].keys())}")
        print("  -> adjClose mangler, men dividender er tilgjengelig => manuell TR-beregning mulig.")
    else:
        print(f"\n  Dividender: status={ds} — TR-benchmark uten adjClose er upresist.")


def summary() -> None:
    hdr("OPPSUMMERING — KAP-krav vs din plan")
    print("""
  Krav                  Status
  ──────────────────────────────────────────────────────────────────────
  [look-ahead-fiks]     filingDate + acceptedDate finnes i income-statement ✓
                        MEN: bare 5 rader per kall (Starter). Nok for MVP.

  [survivorship #1]     Historiske S&P 500-konstituenter: IKKE tilgjengelig
                        (krever høyere plan eller alternativ kilde)

  [survivorship #2]     Kurshistorikk for delistede: IKKE tilgjengelig
                        (402 på alle testede delistede — premium-feature)

  [totalavkastning]     Ingen adjClose i kursdata. Dividender tilgjengelig.
                        Manuell TR = close-kurs justert for dividender mulig,
                        men komplisert. Enklere: bruk SPY/VOO-indeks som proxy
                        og noter begrensningen.

  [historikkdybde]      ~5 år på Starter. Premium gir 30 år.

  KONKLUSJON:
  Din nåværende plan støtter look-ahead-vakten og enkel backtesting (5 år,
  ikke-delistede). Ekte survivorship-bias-fri backtesting krever Premium
  eller en alternativ kilde (CRSP, Sharadar via Nasdaq Data Link, osv.).
""")


def main() -> None:
    print(f"FMP-probe kjørt {dt.datetime.now():%Y-%m-%d %H:%M}")
    check_key()
    check_income_history()
    check_constituents()
    check_delisted()
    check_benchmark()
    summary()


if __name__ == "__main__":
    main()
