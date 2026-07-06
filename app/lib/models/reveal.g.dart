// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reveal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Benchmark _$BenchmarkFromJson(Map<String, dynamic> json) => _Benchmark(
  rmCum: (json['R_m'] as num).toDouble(),
  rm: (json['r_m'] as num).toDouble(),
  rf: (json['r_f'] as num).toDouble(),
  alphaCash: (json['alpha_cash'] as num).toDouble(),
);

Map<String, dynamic> _$BenchmarkToJson(_Benchmark instance) =>
    <String, dynamic>{
      'R_m': instance.rmCum,
      'r_m': instance.rm,
      'r_f': instance.rf,
      'alpha_cash': instance.alphaCash,
    };

_RevealCard _$RevealCardFromJson(Map<String, dynamic> json) => _RevealCard(
  cardNo: (json['card_no'] as num).toInt(),
  ticker: json['ticker'] as String,
  name: json['name'] as String,
  choice: $enumDecode(_$ChoiceEnumMap, json['choice']),
  rCum: (json['R'] as num).toDouble(),
  r: (json['r'] as num).toDouble(),
  alpha: (json['alpha'] as num).toDouble(),
  a: (json['a'] as num).toDouble(),
  points: (json['points'] as num).toDouble(),
  clue: json['clue'] as String,
  event: json['event'] as String?,
  companyId: (json['company_id'] as num).toInt(),
);

Map<String, dynamic> _$RevealCardToJson(_RevealCard instance) =>
    <String, dynamic>{
      'card_no': instance.cardNo,
      'ticker': instance.ticker,
      'name': instance.name,
      'choice': _$ChoiceEnumMap[instance.choice]!,
      'R': instance.rCum,
      'r': instance.r,
      'alpha': instance.alpha,
      'a': instance.a,
      'points': instance.points,
      'clue': instance.clue,
      'event': instance.event,
      'company_id': instance.companyId,
    };

const _$ChoiceEnumMap = {
  Choice.long: 'long',
  Choice.short: 'short',
  Choice.cash: 'cash',
};

_IdealChoice _$IdealChoiceFromJson(Map<String, dynamic> json) => _IdealChoice(
  cardNo: (json['card_no'] as num).toInt(),
  choice: $enumDecode(_$ChoiceEnumMap, json['choice']),
);

Map<String, dynamic> _$IdealChoiceToJson(_IdealChoice instance) =>
    <String, dynamic>{
      'card_no': instance.cardNo,
      'choice': _$ChoiceEnumMap[instance.choice]!,
    };

_Ideal _$IdealFromJson(Map<String, dynamic> json) => _Ideal(
  choices: (json['choices'] as List<dynamic>)
      .map((e) => IdealChoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  score: (json['score'] as num).toDouble(),
);

Map<String, dynamic> _$IdealToJson(_Ideal instance) => <String, dynamic>{
  'choices': instance.choices.map((e) => e.toJson()).toList(),
  'score': instance.score,
};

_Reveal _$RevealFromJson(Map<String, dynamic> json) => _Reveal(
  sessionId: (json['session_id'] as num).toInt(),
  score: (json['score'] as num).toDouble(),
  bonus: (json['bonus'] as num).toDouble(),
  hitRate: (json['hit_rate'] as num?)?.toDouble(),
  benchmark: Benchmark.fromJson(json['benchmark'] as Map<String, dynamic>),
  decisionDate: json['decision_date'] as String,
  horizonYears: (json['horizon_years'] as num).toInt(),
  cards: (json['cards'] as List<dynamic>)
      .map((e) => RevealCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  ideal: Ideal.fromJson(json['ideal'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RevealToJson(_Reveal instance) => <String, dynamic>{
  'session_id': instance.sessionId,
  'score': instance.score,
  'bonus': instance.bonus,
  'hit_rate': instance.hitRate,
  'benchmark': instance.benchmark.toJson(),
  'decision_date': instance.decisionDate,
  'horizon_years': instance.horizonYears,
  'cards': instance.cards.map((e) => e.toJson()).toList(),
  'ideal': instance.ideal.toJson(),
};
