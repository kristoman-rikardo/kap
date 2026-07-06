// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Decision _$DecisionFromJson(Map<String, dynamic> json) => _Decision(
  cardNo: (json['card_no'] as num).toInt(),
  choice: $enumDecode(_$ChoiceEnumMap, json['choice']),
  weight: (json['weight'] as num?)?.toDouble(),
  responseMs: (json['response_ms'] as num?)?.toInt(),
);

Map<String, dynamic> _$DecisionToJson(_Decision instance) => <String, dynamic>{
  'card_no': instance.cardNo,
  'choice': _$ChoiceEnumMap[instance.choice]!,
  'weight': instance.weight,
  'response_ms': instance.responseMs,
};

const _$ChoiceEnumMap = {
  Choice.long: 'long',
  Choice.short: 'short',
  Choice.cash: 'cash',
};
