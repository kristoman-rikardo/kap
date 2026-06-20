import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_card.freezed.dart';
part 'game_card.g.dart';

/// Banded macro context shown on every card (04 §5.7). No numbers, no year.
@freezed
abstract class MacroBox with _$MacroBox {
  const factory MacroBox({
    required String rateLevel, // 'lav' | 'nøytral' | 'høy'
    required String rateDirection, // 'stigende' | 'flat' | 'fallende'
    required String inflationBand,
    required String gdpBand,
    required String sectorSentiment,
  }) = _MacroBox;

  factory MacroBox.fromJson(Map<String, dynamic> json) =>
      _$MacroBoxFromJson(json);
}

@freezed
abstract class Fundamentals with _$Fundamentals {
  const factory Fundamentals({
    double? pe, // null when EPS is negative -> shown as "neg." (04 §5.2)
    required double ps,
    required double debtToEquity,
    required double grossMargin,
    required double operatingMargin,
    required double netMargin,
    required double roic,
  }) = _Fundamentals;

  factory Fundamentals.fromJson(Map<String, dynamic> json) =>
      _$FundamentalsFromJson(json);
}

@freezed
abstract class Growth with _$Growth {
  const factory Growth({
    // Explicit keys: snake-casing a digit-suffixed name would drop the '_'.
    @JsonKey(name: 'rev_cagr_3y') required double revCagr3y,
    @JsonKey(name: 'eps_cagr_3y') required double epsCagr3y,
  }) = _Growth;

  factory Growth.fromJson(Map<String, dynamic> json) => _$GrowthFromJson(json);
}

/// Exactly what the client sees — anonymized (02 §8). No name/ticker/amounts.
@freezed
abstract class CardPayload with _$CardPayload {
  const factory CardPayload({
    required MacroBox macro,
    required Fundamentals fundamentals,
    required Growth growth,
    required String cap, // 'small' | 'mid' | 'large'
    required String sectorCoarse,
    required String narrative,
  }) = _CardPayload;

  factory CardPayload.fromJson(Map<String, dynamic> json) =>
      _$CardPayloadFromJson(json);
}

@freezed
abstract class GameCard with _$GameCard {
  const factory GameCard({
    required int cardNo,
    required CardPayload payload,
  }) = _GameCard;

  factory GameCard.fromJson(Map<String, dynamic> json) =>
      _$GameCardFromJson(json);
}
