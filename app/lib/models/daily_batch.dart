import 'package:freezed_annotation/freezed_annotation.dart';

import 'game_card.dart';

part 'daily_batch.freezed.dart';
part 'daily_batch.g.dart';

/// Period framing shown before card 1 (Instructions §3, batch-level).
@freezed
abstract class Intro with _$Intro {
  const factory Intro({
    required String marketSentiment,
    required String ratePicture,
    required String note,
  }) = _Intro;

  factory Intro.fromJson(Map<String, dynamic> json) => _$IntroFromJson(json);
}

/// The daily round (05 §4.1). Carries no name/ticker/decision_date (05 §5).
@freezed
abstract class DailyBatch with _$DailyBatch {
  const factory DailyBatch({
    required int batchId,
    required String mode,
    required bool isDaily,
    required String dailyDate,
    required int horizonYears,
    required Intro intro,
    required List<GameCard> cards,
  }) = _DailyBatch;

  factory DailyBatch.fromJson(Map<String, dynamic> json) =>
      _$DailyBatchFromJson(json);
}
