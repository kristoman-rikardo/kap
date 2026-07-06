import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/choice.dart';
import '../models/reveal.dart';

/// The reveal — the only place truth (names, alpha, points) is shown (06 §10).
///
/// Order follows the truth-layer-first principle (01 §3.2: alpha is the truth
/// layer, points are the game layer): first you vs the index as a chart, then
/// the compact game score, then the per-card flips — each carrying its own
/// fasit so the lesson sits next to the outcome. Outcome colour (green/red)
/// is deliberately allowed here and only here (06 §1/§14).
class RevealView extends StatelessWidget {
  const RevealView({super.key, required this.reveal, required this.onReplay});

  final Reveal reveal;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final idealByCard = {
      for (final c in reveal.ideal.choices) c.cardNo: c.choice,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChartCard(reveal: reveal),
        const SizedBox(height: 12),
        _ScoreStrip(reveal: reveal),
        const SizedBox(height: 16),
        for (final (i, card) in reveal.cards.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FlipTile(
              delay: Duration(milliseconds: 250 + 350 * i),
              card: card,
              idealChoice: idealByCard[card.cardNo],
            ),
          ),
        _PerfectRoundNote(reveal: reveal),
        const SizedBox(height: 24),
        Center(
          child: FilledButton(
            onPressed: onReplay,
            child: const Text('Spill igjen'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Reveal is where outcome colour lives. Green has no Material 3 scheme slot,
/// so the pair is defined once here (moves to theme tokens with 06 §14).
Color _outcomeColor(BuildContext context, double value) {
  if (value == 0) return Theme.of(context).colorScheme.onSurfaceVariant;
  return value > 0
      ? const Color(0xFF2E7D32)
      : Theme.of(context).colorScheme.error;
}

String _signed(double v, {int decimals = 1}) =>
    '${v >= 0 ? '+' : '−'}${v.abs().toStringAsFixed(decimals)}';

/// Annualized fraction -> signed percent string, e.g. 0.13 -> '+13.0 %'.
String _signedPct(double v) => '${_signed(v * 100)} %';

/// You vs the index over the horizon — the first thing the player sees.
///
/// Junior has no weighting, so "your portfolio" is the equal-weight reading of
/// the five choices: the index return plus the average alpha contribution
/// (mean of a_i, 01 §3.1). Real daily series replace this stylized compounding
/// when the pipeline lands.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.reveal});

  final Reveal reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = reveal.benchmark;
    final meanA =
        reveal.cards.fold(0.0, (sum, c) => sum + c.a) / reveal.cards.length;
    final rYou = b.rm + meanA;
    final years = reveal.horizonYears;
    final youColor = _outcomeColor(context, meanA);
    final indexColor = theme.colorScheme.onSurfaceVariant;

    List<FlSpot> series(double r) => [
      for (var t = 0; t <= years; t++)
        FlSpot(t.toDouble(), 100.0 * math.pow(1 + r, t).toDouble()),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deg mot indeksen', style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(
            '${_signedPct(meanA)}/år',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: youColor,
            ),
          ),
          Text(
            'gjennomsnittlig alpha på valgene dine',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          'år ${value.toInt()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: series(b.rm),
                    color: indexColor,
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: series(rYou),
                    color: youColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            children: [
              _LegendEntry(
                color: youColor,
                label:
                    'Du ${_signedPct(math.pow(1 + rYou, years) - 1.0)} totalt',
              ),
              _LegendEntry(
                color: indexColor,
                label:
                    'Indeks ${_signedPct(math.pow(1 + b.rm, years) - 1.0)} totalt',
                dashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The game-layer score, demoted to a compact strip under the chart
/// (points are the squashed play-number; alpha above is the truth).
class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.reveal});

  final Reveal reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hitRate = reveal.hitRate;
    final parts = [
      '${_signed(reveal.score, decimals: 0)} poeng',
      if (hitRate != null) 'treff ${(hitRate * 100).toStringAsFixed(0)} %',
      if (reveal.bonus > 0)
        'perfekt runde +${reveal.bonus.toStringAsFixed(0)}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_esports_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parts.join('  ·  '),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One revealed card: starts face-down, flips up after [delay].
class _FlipTile extends StatefulWidget {
  const _FlipTile({
    required this.delay,
    required this.card,
    required this.idealChoice,
  });

  final Duration delay;
  final RevealCard card;
  final Choice? idealChoice;

  @override
  State<_FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<_FlipTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _flip = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final showingBack = _flip.value < 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(_flip.value * math.pi),
          child: showingBack
              ? _TileFaceDown(cardNo: widget.card.cardNo)
              // The face-up side renders inside a half-turned parent, so it
              // gets its own half-turn to read upright.
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateX(math.pi),
                  child: _TileFaceUp(
                    card: widget.card,
                    idealChoice: widget.idealChoice,
                  ),
                ),
        );
      },
    );
  }
}

class _TileFaceDown extends StatelessWidget {
  const _TileFaceDown({required this.cardNo});

  final int cardNo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Kort $cardNo',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _TileFaceUp extends StatelessWidget {
  const _TileFaceUp({required this.card, required this.idealChoice});

  final RevealCard card;
  final Choice? idealChoice;

  static const _choiceLabels = {
    Choice.long: 'Long',
    Choice.short: 'Short',
    Choice.cash: 'Cash',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointsColor = _outcomeColor(context, card.points);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Det var ${card.name} (${card.ticker})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _signed(card.points, decimals: 0),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: pointsColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Tag(text: 'Du valgte ${_choiceLabels[card.choice]}'),
              ..._fasitTags(context),
              Text(
                'Aksjen: ${_signedPct(card.r)}/år · '
                'alpha ${_signedPct(card.alpha)}/år',
                style: theme.textTheme.bodySmall,
              ),
              if (card.event != null)
                _Tag(
                  text: card.event == 'acquired' ? 'Oppkjøpt' : 'Avnotert',
                  emphasized: true,
                ),
              ..._cashTags(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.clue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// The optimal call, shown on the card itself so the lesson lands where the
  /// outcome is. Cash is named as a valid alternative when the stock actually
  /// fell (01 §8's two-way cash nuance) — alpha-wise short beat it, but
  /// capital preservation was a defensible call.
  List<Widget> _fasitTags(BuildContext context) {
    final ideal = idealChoice;
    if (ideal == null) return const [];
    final hit = card.choice == ideal;
    final cashWasDecent = card.rCum < 0 && card.choice != Choice.cash;
    return [
      _Tag(
        text: 'Fasit: ${_choiceLabels[ideal]}${hit ? ' ✓' : ''}',
        emphasized: true,
        outline: hit ? _outcomeColor(context, 1) : null,
      ),
      if (cashWasDecent) const _Tag(text: 'cash var også ok her'),
    ];
  }

  /// Cash gets a psychological marker separate from its (alpha) score:
  /// avoided a real loss vs missed a rise (01 §3.2 / 06 §10).
  List<Widget> _cashTags() {
    if (card.choice != Choice.cash) return const [];
    return [
      card.rCum < 0
          ? const _Tag(text: '✓ Unngått tap', emphasized: true)
          : const _Tag(text: 'Mistet oppgang'),
    ];
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.emphasized = false, this.outline});

  final String text;
  final bool emphasized;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outline ?? theme.colorScheme.outlineVariant,
          width: outline == null ? 1 : 1.5,
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: emphasized
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Footer: what a perfect round was worth, plus the ex-ante cash lesson that
/// must accompany any hindsight framing (01 §8).
class _PerfectRoundNote extends StatelessWidget {
  const _PerfectRoundNote({required this.reveal});

  final Reveal reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Fasit på alle kort hadde gitt '
        '${_signed(reveal.ideal.score, decimals: 0)} poeng. Fasiten er '
        'etterpåklokskap — cash kan være et godt valg før svaret er kjent, '
        'selv når det koster mot indeksen i ettertid.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
