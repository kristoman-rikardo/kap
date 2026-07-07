import 'package:freezed_annotation/freezed_annotation.dart';

part 'me_stats.freezed.dart';
part 'me_stats.g.dart';

/// One row in the "siste runder" history (GET /v1/me/stats, 05 §4.5).
@freezed
abstract class SessionSummary with _$SessionSummary {
  const factory SessionSummary({
    required int sessionId,
    String? dailyDate,
    String? submittedAt,
    double? score,
    double? hitRate,
  }) = _SessionSummary;

  factory SessionSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryFromJson(json);
}

/// The home screen's data source: streak, history and today's state.
@freezed
abstract class MeStats with _$MeStats {
  const factory MeStats({
    required int streak,
    required int roundsPlayed,
    required bool dailyPlayedToday,
    double? todayScore,
    required List<SessionSummary> recent,
  }) = _MeStats;

  factory MeStats.fromJson(Map<String, dynamic> json) =>
      _$MeStatsFromJson(json);
}
