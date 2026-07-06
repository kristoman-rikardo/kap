import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kap/models/choice.dart';
import 'package:kap/models/decision.dart';
import 'package:kap/models/game_card.dart';
import 'package:kap/models/daily_batch.dart';
import 'package:kap/models/reveal.dart';
import 'package:kap/screens/daily_screen.dart';
import 'package:kap/screens/reveal_screen.dart';
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

const _sampleReveal = Reveal(
  sessionId: 1,
  score: -28,
  bonus: 0,
  hitRate: 0.5,
  benchmark: Benchmark(
    rmCum: 0.60,
    rm: 0.0986,
    rf: 0.0155,
    alphaCash: -0.0830,
  ),
  decisionDate: '2014-06-02',
  horizonYears: 5,
  cards: [
    RevealCard(
      cardNo: 1,
      ticker: 'CORX',
      name: 'Corex Systems',
      choice: Choice.long,
      rCum: 1.80,
      r: 0.2287,
      alpha: 0.1301,
      a: 0.1301,
      points: 70,
      clue: 'clue-1',
      companyId: 101,
    ),
    RevealCard(
      cardNo: 2,
      ticker: 'MERI',
      name: 'Meridian Energy Partners',
      choice: Choice.cash,
      rCum: -0.45,
      r: -0.1127,
      alpha: -0.2113,
      a: -0.0830,
      points: -50,
      clue: 'clue-2',
      companyId: 102,
    ),
  ],
  ideal: Ideal(
    choices: [
      IdealChoice(cardNo: 1, choice: Choice.long),
      IdealChoice(cardNo: 2, choice: Choice.short),
    ],
    score: 160,
  ),
);

/// In-process stand-in for the backend so the full loop can run in a widget
/// test without networking. Records what was submitted.
class _FakeApi extends ApiClient {
  int? submittedBatchId;
  List<Decision>? submitted;

  @override
  Future<DailyBatch> getDaily() async =>
      DailyBatch.fromJson(jsonDecode(_dailyJson) as Map<String, dynamic>);

  @override
  Future<Reveal> submitBatch(int batchId, List<Decision> decisions) async {
    submittedBatchId = batchId;
    submitted = decisions;
    return _sampleReveal;
  }
}

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

  test('Reveal.fromJson maps R vs r, benchmark keys, choice enum and nulls', () {
    const revealJson = '''
    {
      "session_id": 1, "score": -28.0, "bonus": 0.0, "hit_rate": 0.5,
      "benchmark": {"R_m": 0.60, "r_m": 0.0986, "r_f": 0.0155, "alpha_cash": -0.0830},
      "decision_date": "2014-06-02", "horizon_years": 5,
      "cards": [
        {"card_no": 3, "ticker": "HLVX", "name": "Halvex Pharmaceuticals",
         "choice": "cash", "R": 0.75, "r": 0.1184, "alpha": 0.0199,
         "a": -0.0830, "points": -42.0, "clue": "c",
         "event": null, "company_id": 103}
      ],
      "ideal": {"choices": [{"card_no": 3, "choice": "long"}], "score": 338.0}
    }
    ''';
    final reveal = Reveal.fromJson(
      jsonDecode(revealJson) as Map<String, dynamic>,
    );

    expect(reveal.score, -28.0);
    expect(reveal.hitRate, 0.5);
    expect(reveal.decisionDate, '2014-06-02');
    expect(reveal.benchmark.rmCum, 0.60); // "R_m", not the snake-cased guess
    expect(reveal.benchmark.rm, 0.0986);
    expect(reveal.benchmark.alphaCash, -0.0830);

    final card = reveal.cards.single;
    expect(card.choice, Choice.cash);
    expect(card.rCum, 0.75); // capital "R"
    expect(card.r, 0.1184); // lower "r" stays distinct
    expect(card.event, isNull);
    expect(reveal.ideal.choices.single.choice, Choice.long);
  });

  test('Decision.toJson writes snake_case keys and the enum by name', () {
    const decision = Decision(cardNo: 2, choice: Choice.short, responseMs: 900);
    expect(decision.toJson(), {
      'card_no': 2,
      'choice': 'short',
      'weight': null,
      'response_ms': 900,
    });
  });

  testWidgets('RevealView shows score, names, cash badge and fasit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RevealView(reveal: _sampleReveal, onReplay: () {}),
        ),
      ),
    );
    // Let the staggered flips run to completion so face-up content exists.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Chart-first: the alpha headline and the you-vs-index chart lead.
    expect(find.textContaining('/år'), findsWidgets);
    expect(find.text('Deg mot indeksen'), findsOneWidget);
    // The game score is a compact strip, not the headline.
    expect(find.textContaining('−28 poeng'), findsOneWidget);
    expect(find.textContaining('Corex Systems'), findsOneWidget);
    expect(find.text('Du valgte Long'), findsOneWidget);
    // Each card carries its own fasit; a matching call gets the check mark.
    expect(find.text('Fasit: Long ✓'), findsOneWidget);
    expect(find.text('Fasit: Short'), findsOneWidget);
    // Cash on a falling stock earns the avoided-loss marker (01 §3.2).
    expect(find.text('✓ Unngått tap'), findsOneWidget);
  });

  testWidgets('full loop: choose on every card, auto-submit, see the reveal', (
    WidgetTester tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(MaterialApp(home: DailyScreen(apiClient: api)));
    await tester.pumpAndSettle();

    expect(find.text('Kort 1 av 2'), findsOneWidget);
    await tester.tap(find.text('Long'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Short'));
    await tester.pumpAndSettle();

    // The round auto-submitted with one decision per card, in card order.
    expect(api.submittedBatchId, 1);
    expect(api.submitted!.map((d) => (d.cardNo, d.choice)).toList(), [
      (1, Choice.long),
      (2, Choice.short),
    ]);

    // ... and the reveal took over the screen, chart first.
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Deg mot indeksen'), findsOneWidget);
    expect(find.textContaining('−28 poeng'), findsOneWidget);
    expect(find.textContaining('Corex Systems'), findsOneWidget);
  });

  testWidgets('GameCardView renders sector, narrative, "neg." P/E and cap', (
    WidgetTester tester,
  ) async {
    // Render at a real phone-card envelope so a layout overflow fails the test.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 560,
              child: GameCardView(card: _sampleCard),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Forbruksvarer'), findsOneWidget);
    expect(find.textContaining('ennå ikke tjener penger'), findsOneWidget);
    expect(find.text('neg.'), findsOneWidget); // null pe
    expect(find.text('Small cap'), findsOneWidget);
  });
}
