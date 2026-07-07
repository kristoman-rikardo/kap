// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) =>
    _SessionSummary(
      sessionId: (json['session_id'] as num).toInt(),
      dailyDate: json['daily_date'] as String?,
      submittedAt: json['submitted_at'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      hitRate: (json['hit_rate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SessionSummaryToJson(_SessionSummary instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'daily_date': instance.dailyDate,
      'submitted_at': instance.submittedAt,
      'score': instance.score,
      'hit_rate': instance.hitRate,
    };

_MeStats _$MeStatsFromJson(Map<String, dynamic> json) => _MeStats(
  streak: (json['streak'] as num).toInt(),
  roundsPlayed: (json['rounds_played'] as num).toInt(),
  dailyPlayedToday: json['daily_played_today'] as bool,
  todayScore: (json['today_score'] as num?)?.toDouble(),
  recent: (json['recent'] as List<dynamic>)
      .map((e) => SessionSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MeStatsToJson(_MeStats instance) => <String, dynamic>{
  'streak': instance.streak,
  'rounds_played': instance.roundsPlayed,
  'daily_played_today': instance.dailyPlayedToday,
  'today_score': instance.todayScore,
  'recent': instance.recent.map((e) => e.toJson()).toList(),
};
