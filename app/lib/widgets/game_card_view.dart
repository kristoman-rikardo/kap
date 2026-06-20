import 'package:flutter/material.dart';

import '../models/game_card.dart';

/// Renders one anonymized blind card — the three layers from Instructions §3,
/// as labelled zones for readability: MARKED (banded macro context),
/// NØKKELTALL (the hard numbers, grouped by theme), SITUASJON (narrative).
///
/// The body scrolls vertically so the full card fits any screen size without
/// overflow (the card swiper only claims horizontal drags). Term-chips,
/// knowledge-level definitions and motion come later (06 §8).
class GameCardView extends StatelessWidget {
  const GameCardView({super.key, required this.card});

  final GameCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = card.payload;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    p.sectorCoarse,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _CapChip(cap: p.cap),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Marked'),
            const SizedBox(height: 10),
            _MacroGrid(macro: p.macro),
            const SizedBox(height: 22),
            const _SectionLabel('Nøkkeltall'),
            const SizedBox(height: 12),
            _MetricsGrid(fundamentals: p.fundamentals, growth: p.growth),
            const SizedBox(height: 22),
            const _SectionLabel('Situasjon'),
            const SizedBox(height: 8),
            Text(
              p.narrative,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip({required this.cap});

  final String cap;

  static const _labels = {
    'small': 'Small cap',
    'mid': 'Mid cap',
    'large': 'Large cap',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[cap] ?? cap,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// 2×2 of label-over-value macro cells inside a soft container.
class _MacroGrid extends StatelessWidget {
  const _MacroGrid({required this.macro});

  final MacroBox macro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Cell(
                  label: 'Renter',
                  value: '${macro.rateLevel}, ${macro.rateDirection}',
                ),
              ),
              Expanded(
                child: _Cell(label: 'Inflasjon', value: macro.inflationBand),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Cell(label: 'BNP', value: macro.gdpBand)),
              Expanded(
                child: _Cell(label: 'Sektor', value: macro.sectorSentiment),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The nine fundamentals as thematic rows:
/// valuation + leverage / margins / returns + growth.
class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.fundamentals, required this.growth});

  final Fundamentals fundamentals;
  final Growth growth;

  static String _mult(double v) => '${v.toStringAsFixed(1)}×';
  static String _pct(double v) => '${(v * 100).toStringAsFixed(0)} %';

  @override
  Widget build(BuildContext context) {
    final f = fundamentals;
    final rows = <List<(String, String)>>[
      [
        ('P/E', f.pe == null ? 'neg.' : f.pe!.toStringAsFixed(1)),
        ('P/S', _mult(f.ps)),
        ('Gjeld/EK', _mult(f.debtToEquity)),
      ],
      [
        ('Bruttomargin', _pct(f.grossMargin)),
        ('Driftsmargin', _pct(f.operatingMargin)),
        ('Nettomargin', _pct(f.netMargin)),
      ],
      [
        ('ROIC', _pct(f.roic)),
        ('Omsetn.vekst', _pct(growth.revCagr3y)),
        ('EPS-vekst', _pct(growth.epsCagr3y)),
      ],
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, value) in rows[i])
                  Expanded(child: _Cell(label: label, value: value)),
              ],
            ),
          ),
      ],
    );
  }
}

/// A muted label over a prominent value — the basic readable unit.
class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
