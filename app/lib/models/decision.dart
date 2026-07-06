import 'package:freezed_annotation/freezed_annotation.dart';

import 'choice.dart';

part 'decision.freezed.dart';
part 'decision.g.dart';

/// One choice on one card, as sent to `POST /v1/batches/{id}/submit` (05 §4.3).
@freezed
abstract class Decision with _$Decision {
  const factory Decision({
    required int cardNo,
    required Choice choice,
    double? weight, // Manager-only; null in Junior
    int? responseMs, // time from card shown to choice (analytics, 02 §9)
  }) = _Decision;

  factory Decision.fromJson(Map<String, dynamic> json) =>
      _$DecisionFromJson(json);
}
