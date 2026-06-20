// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MacroBox _$MacroBoxFromJson(Map<String, dynamic> json) => _MacroBox(
  rateLevel: json['rate_level'] as String,
  rateDirection: json['rate_direction'] as String,
  inflationBand: json['inflation_band'] as String,
  gdpBand: json['gdp_band'] as String,
  sectorSentiment: json['sector_sentiment'] as String,
);

Map<String, dynamic> _$MacroBoxToJson(_MacroBox instance) => <String, dynamic>{
  'rate_level': instance.rateLevel,
  'rate_direction': instance.rateDirection,
  'inflation_band': instance.inflationBand,
  'gdp_band': instance.gdpBand,
  'sector_sentiment': instance.sectorSentiment,
};

_Fundamentals _$FundamentalsFromJson(Map<String, dynamic> json) =>
    _Fundamentals(
      pe: (json['pe'] as num?)?.toDouble(),
      ps: (json['ps'] as num).toDouble(),
      debtToEquity: (json['debt_to_equity'] as num).toDouble(),
      grossMargin: (json['gross_margin'] as num).toDouble(),
      operatingMargin: (json['operating_margin'] as num).toDouble(),
      netMargin: (json['net_margin'] as num).toDouble(),
      roic: (json['roic'] as num).toDouble(),
    );

Map<String, dynamic> _$FundamentalsToJson(_Fundamentals instance) =>
    <String, dynamic>{
      'pe': instance.pe,
      'ps': instance.ps,
      'debt_to_equity': instance.debtToEquity,
      'gross_margin': instance.grossMargin,
      'operating_margin': instance.operatingMargin,
      'net_margin': instance.netMargin,
      'roic': instance.roic,
    };

_Growth _$GrowthFromJson(Map<String, dynamic> json) => _Growth(
  revCagr3y: (json['rev_cagr_3y'] as num).toDouble(),
  epsCagr3y: (json['eps_cagr_3y'] as num).toDouble(),
);

Map<String, dynamic> _$GrowthToJson(_Growth instance) => <String, dynamic>{
  'rev_cagr_3y': instance.revCagr3y,
  'eps_cagr_3y': instance.epsCagr3y,
};

_CardPayload _$CardPayloadFromJson(Map<String, dynamic> json) => _CardPayload(
  macro: MacroBox.fromJson(json['macro'] as Map<String, dynamic>),
  fundamentals: Fundamentals.fromJson(
    json['fundamentals'] as Map<String, dynamic>,
  ),
  growth: Growth.fromJson(json['growth'] as Map<String, dynamic>),
  cap: json['cap'] as String,
  sectorCoarse: json['sector_coarse'] as String,
  narrative: json['narrative'] as String,
);

Map<String, dynamic> _$CardPayloadToJson(_CardPayload instance) =>
    <String, dynamic>{
      'macro': instance.macro.toJson(),
      'fundamentals': instance.fundamentals.toJson(),
      'growth': instance.growth.toJson(),
      'cap': instance.cap,
      'sector_coarse': instance.sectorCoarse,
      'narrative': instance.narrative,
    };

_GameCard _$GameCardFromJson(Map<String, dynamic> json) => _GameCard(
  cardNo: (json['card_no'] as num).toInt(),
  payload: CardPayload.fromJson(json['payload'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GameCardToJson(_GameCard instance) => <String, dynamic>{
  'card_no': instance.cardNo,
  'payload': instance.payload.toJson(),
};
