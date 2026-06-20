import 'package:flutter/material.dart';

import '../models/game_card.dart';

/// Renders one anonymized blind card — the three layers from Instructions §3:
/// banded macro, hard numbers, narrative. CP 1.1 rendering; term-chips,
/// knowledge-level definitions and final polish come later (06 §8).
class GameCardView extends StatelessWidget {
  const GameCardView({super.key, required this.card});

  final GameCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = card.payload;
    final f = p.fundamentals;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.sectorCoarse,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _CapChip(cap: p.cap),
              ],
            ),
            const SizedBox(height: 16),
            _MacroBoxView(macro: p.macro),
            const SizedBox(height: 16),
            _FundamentalsGrid(fundamentals: f, growth: p.growth),
            const SizedBox(height: 16),
            Flexible(
              child: Text(
                p.narrative,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip({required this.cap});

  final String cap;

  static const _labels = {'small': 'Small cap', 'mid': 'Mid cap', 'large': 'Large cap'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[cap] ?? cap,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _MacroBoxView extends StatelessWidget {
  const _MacroBoxView({required this.macro});

  final MacroBox macro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InfoChip(label: 'Renter', value: '${macro.rateLevel}, ${macro.rateDirection}'),
          _InfoChip(label: 'Inflasjon', value: macro.inflationBand),
          _InfoChip(label: 'BNP', value: macro.gdpBand),
          _InfoChip(label: 'Sektorsentiment', value: macro.sectorSentiment),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _FundamentalsGrid extends StatelessWidget {
  const _FundamentalsGrid({required this.fundamentals, required this.growth});

  final Fundamentals fundamentals;
  final Growth growth;

  static String _mult(double v) => '${v.toStringAsFixed(1)}×';
  static String _pct(double v) => '${(v * 100).toStringAsFixed(0)} %';

  @override
  Widget build(BuildContext context) {
    final f = fundamentals;
    final metrics = <(String, String)>[
      ('P/E', f.pe == null ? 'neg.' : f.pe!.toStringAsFixed(1)),
      ('P/S', _mult(f.ps)),
      ('Gjeld/EK', _mult(f.debtToEquity)),
      ('Bruttomargin', _pct(f.grossMargin)),
      ('Driftsmargin', _pct(f.operatingMargin)),
      ('Nettomargin', _pct(f.netMargin)),
      ('ROIC', _pct(f.roic)),
      ('Omsetn.vekst', _pct(growth.revCagr3y)),
      ('EPS-vekst', _pct(growth.epsCagr3y)),
    ];

    return Column(
      children: [
        for (var row = 0; row < metrics.length; row += 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (var col = 0; col < 3 && row + col < metrics.length; col++)
                  Expanded(
                    child: _Metric(
                      label: metrics[row + col].$1,
                      value: metrics[row + col].$2,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
