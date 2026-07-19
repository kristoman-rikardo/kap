"""Point-in-time financials merge tests (CP 3.3). Pure, no network."""

from __future__ import annotations

import datetime as dt

from backend.pipeline.financials import index_by_period, merge_period_row


def _inc(**kw):
    base = {
        "date": "2016-03-26",
        "period": "Q2",
        "fiscalYear": "2016",
        "filingDate": "2016-04-27",
        "revenue": 50557000000,
        "netIncome": 10516000000,
        "epsDiluted": 1.90,
        "weightedAverageShsOutDil": 5500000000,
    }
    base.update(kw)
    return base


def _rat(**kw):
    base = {
        "grossProfitMargin": 0.39,
        "operatingProfitMargin": 0.28,
        "netProfitMargin": 0.208,
        "debtToEquityRatio": 0.62,
    }
    base.update(kw)
    return base


def _km(**kw):
    base = {"returnOnInvestedCapital": 0.22, "marketCap": 580000000000}
    base.update(kw)
    return base


def test_merge_uses_income_filing_date_and_period():
    row = merge_period_row(_inc(), None, _km(), _rat())
    assert row["filing_date"] == dt.date(2016, 4, 27)
    assert row["period_date"] == dt.date(2016, 3, 26)
    assert row["period_type"] == "quarter"


def test_merge_pulls_ratios_and_metrics():
    row = merge_period_row(_inc(), None, _km(), _rat())
    assert row["revenue"] == 50557000000
    assert row["eps"] == 1.90
    assert row["net_margin"] == 0.208
    assert row["debt_to_equity"] == 0.62
    assert row["roic"] == 0.22


def test_merge_omits_price_dependent_fields():
    row = merge_period_row(_inc(), None, _km(), _rat())
    assert "pe" not in row and "ps" not in row and "cap_category" not in row
    assert row["extra"]["shares_out_dil"] == 5500000000


def test_merge_falls_back_to_balance_filing_date():
    inc = _inc()
    del inc["filingDate"]
    bal = {"filingDate": "2016-04-28"}
    row = merge_period_row(inc, bal, _km(), _rat())
    assert row["filing_date"] == dt.date(2016, 4, 28)


def test_merge_tolerates_missing_ratios_and_metrics():
    row = merge_period_row(_inc(), None, None, None)
    assert row["roic"] is None and row["net_margin"] is None
    assert row["revenue"] == 50557000000


def test_index_by_period_keys_on_fiscalyear_and_period():
    rows = [
        {"fiscalYear": "2016", "period": "Q2", "x": 1},
        {"fiscalYear": 2015, "period": "Q4", "x": 2},
    ]
    idx = index_by_period(rows)
    assert idx[("2016", "Q2")]["x"] == 1
    assert idx[("2015", "Q4")]["x"] == 2  # int fiscalYear coerced to str
