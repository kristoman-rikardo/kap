import 'package:freezed_annotation/freezed_annotation.dart';

import 'choice.dart';

part 'reveal.freezed.dart';
part 'reveal.g.dart';

/// Batch-level truth, frozen per batch (01 §6.6). `R_m`/`r_m`/`r_f` need
/// explicit keys: the contract distinguishes cumulative (capital R) from
/// annualized (lower r), which snake-casing can't express.
@freezed
abstract class Benchmark with _$Benchmark {
  const factory Benchmark({
    @JsonKey(name: 'R_m') required double rmCum,
    @JsonKey(name: 'r_m') required double rm,
    @JsonKey(name: 'r_f') required double rf,
    required double alphaCash,
  }) = _Benchmark;

  factory Benchmark.fromJson(Map<String, dynamic> json) =>
      _$BenchmarkFromJson(json);
}

/// Per-card truth + the user's outcome (01 §7). Only ever arrives after
/// submit — this model has no place in the blind phase (05 §5).
@freezed
abstract class RevealCard with _$RevealCard {
  const factory RevealCard({
    required int cardNo,
    required String ticker,
    required String name,
    required Choice choice,
    @JsonKey(name: 'R') required double rCum,
    required double r,
    required double alpha,
    required double a,
    required double points,
    required String clue,
    String? event, // 'acquired' | 'delisted' | null
    required int companyId,
  }) = _RevealCard;

  factory RevealCard.fromJson(Map<String, dynamic> json) =>
      _$RevealCardFromJson(json);
}

@freezed
abstract class IdealChoice with _$IdealChoice {
  const factory IdealChoice({
    required int cardNo,
    required Choice choice,
  }) = _IdealChoice;

  factory IdealChoice.fromJson(Map<String, dynamic> json) =>
      _$IdealChoiceFromJson(json);
}

/// Hindsight portfolio (01 §8) — explicitly framed as etterpåklokskap in UI.
@freezed
abstract class Ideal with _$Ideal {
  const factory Ideal({
    required List<IdealChoice> choices,
    required double score,
  }) = _Ideal;

  factory Ideal.fromJson(Map<String, dynamic> json) => _$IdealFromJson(json);
}

@freezed
abstract class Reveal with _$Reveal {
  const factory Reveal({
    required int sessionId,
    required double score,
    required double bonus,
    double? hitRate, // null when the round had no long/short choices
    required Benchmark benchmark,
    required String decisionDate,
    required int horizonYears,
    required List<RevealCard> cards,
    required Ideal ideal,
  }) = _Reveal;

  factory Reveal.fromJson(Map<String, dynamic> json) => _$RevealFromJson(json);
}
