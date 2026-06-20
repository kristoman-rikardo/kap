// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Intro _$IntroFromJson(Map<String, dynamic> json) => _Intro(
  marketSentiment: json['market_sentiment'] as String,
  ratePicture: json['rate_picture'] as String,
  note: json['note'] as String,
);

Map<String, dynamic> _$IntroToJson(_Intro instance) => <String, dynamic>{
  'market_sentiment': instance.marketSentiment,
  'rate_picture': instance.ratePicture,
  'note': instance.note,
};

_DailyBatch _$DailyBatchFromJson(Map<String, dynamic> json) => _DailyBatch(
  batchId: (json['batch_id'] as num).toInt(),
  mode: json['mode'] as String,
  isDaily: json['is_daily'] as bool,
  dailyDate: json['daily_date'] as String,
  horizonYears: (json['horizon_years'] as num).toInt(),
  intro: Intro.fromJson(json['intro'] as Map<String, dynamic>),
  cards: (json['cards'] as List<dynamic>)
      .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DailyBatchToJson(_DailyBatch instance) =>
    <String, dynamic>{
      'batch_id': instance.batchId,
      'mode': instance.mode,
      'is_daily': instance.isDaily,
      'daily_date': instance.dailyDate,
      'horizon_years': instance.horizonYears,
      'intro': instance.intro.toJson(),
      'cards': instance.cards.map((e) => e.toJson()).toList(),
    };
