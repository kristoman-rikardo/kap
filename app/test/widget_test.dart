import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kap/models/game_card.dart';
import 'package:kap/models/daily_batch.dart';
import 'package:kap/services/api_client.dart';
import 'package:kap/widgets/game_card_view.dart';

const _sampleCard = GameCard(
  cardNo: 4,
  payload: CardPayload(
    macro: MacroBox(
      rateLevel: 'lav',
      rateDirection: 'fallende',
      inflationBand: 'moderat',
      gdpBand: 'sunn',
      sectorSentiment: 'pessimistisk',
    ),
    fundamentals: Fundamentals(
      pe: null,
      ps: 2.4,
      debtToEquity: 0.9,
      grossMargin: 0.52,
      operatingMargin: -0.05,
      netMargin: -0.08,
      roic: -0.04,
    ),
    growth: Growth(revCagr3y: 0.31, epsCagr3y: 0.0),
    cap: 'small',
    sectorCoarse: 'Forbruksvarer',
    narrative: 'Et raskt voksende selskap som ennå ikke tjener penger.',
  ),
);

// A realistic /v1/daily payload (decoded exactly like the live response).
const _dailyJson = '''
{
  "batch_id": 1, "mode": "junior", "is_daily": true,
  "daily_date": "2026-06-20", "horizon_years": 5,
  "intro": {"market_sentiment": "grådig", "rate_picture": "lave, fallende renter", "note": "n"},
  "cards": [
    {"card_no": 1, "payload": {
      "macro": {"rate_level": "lav", "rate_direction": "fallende",
                "inflation_band": "moderat", "gdp_band": "sunn", "sector_sentiment": "optimistisk"},
      "fundamentals": {"pe": 18.4, "ps": 3.1, "debt_to_equity": 0.6,
                       "gross_margin": 0.41, "operating_margin": 0.22, "net_margin": 0.15, "roic": 0.19},
      "growth": {"rev_cagr_3y": 0.12, "eps_cagr_3y": 0.09},
      "cap": "mid", "sector_coarse": "Teknologi", "narrative": "n1"}},
    {"card_no": 2, "payload": {
      "macro": {"rate_level": "lav", "rate_direction": "fallende",
                "inflation_band": "moderat", "gdp_band": "sunn", "sector_sentiment": "pessimistisk"},
      "fundamentals": {"pe": null, "ps": 2.4, "debt_to_equity": 0.9,
                       "gross_margin": 0.52, "operating_margin": -0.05, "net_margin": -0.08, "roic": -0.04},
      "growth": {"rev_cagr_3y": 0.31, "eps_cagr_3y": 0.0},
      "cap": "small", "sector_coarse": "Forbruksvarer", "narrative": "n2"}}
  ]
}
''';

void main() {
  test('ApiClient applies the dev base URL', () {
    expect(ApiClient().baseUrl, 'http://127.0.0.1:8000');
  });

  test('DailyBatch.fromJson maps snake_case keys, *_cagr_3y, and null pe', () {
    final batch = DailyBatch.fromJson(
      jsonDecode(_dailyJson) as Map<String, dynamic>,
    );

    expect(batch.batchId, 1);
    expect(batch.isDaily, true);
    expect(batch.horizonYears, 5);
    expect(batch.intro.marketSentiment, 'grådig');
    expect(batch.cards.length, 2);

    final c1 = batch.cards[0].payload;
    expect(c1.sectorCoarse, 'Teknologi');
    expect(c1.fundamentals.pe, 18.4);
    expect(c1.growth.revCagr3y, 0.12); // would be null if the @JsonKey were wrong

    final c2 = batch.cards[1].payload;
    expect(c2.fundamentals.pe, isNull); // negative-EPS card
    expect(c2.growth.epsCagr3y, 0.0);
  });

  testWidgets('GameCardView renders sector, narrative, "neg." P/E and cap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GameCardView(card: _sampleCard))),
    );

    expect(find.text('Forbruksvarer'), findsOneWidget);
    expect(find.textContaining('ennå ikke tjener penger'), findsOneWidget);
    expect(find.text('neg.'), findsOneWidget); // null pe
    expect(find.text('Small cap'), findsOneWidget);
  });
}
