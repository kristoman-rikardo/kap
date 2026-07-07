// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'me_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionSummary {

 int get sessionId; String? get dailyDate; String? get submittedAt; double? get score; double? get hitRate;
/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSummaryCopyWith<SessionSummary> get copyWith => _$SessionSummaryCopyWithImpl<SessionSummary>(this as SessionSummary, _$identity);

  /// Serializes this SessionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSummary&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.dailyDate, dailyDate) || other.dailyDate == dailyDate)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.score, score) || other.score == score)&&(identical(other.hitRate, hitRate) || other.hitRate == hitRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,dailyDate,submittedAt,score,hitRate);

@override
String toString() {
  return 'SessionSummary(sessionId: $sessionId, dailyDate: $dailyDate, submittedAt: $submittedAt, score: $score, hitRate: $hitRate)';
}


}

/// @nodoc
abstract mixin class $SessionSummaryCopyWith<$Res>  {
  factory $SessionSummaryCopyWith(SessionSummary value, $Res Function(SessionSummary) _then) = _$SessionSummaryCopyWithImpl;
@useResult
$Res call({
 int sessionId, String? dailyDate, String? submittedAt, double? score, double? hitRate
});




}
/// @nodoc
class _$SessionSummaryCopyWithImpl<$Res>
    implements $SessionSummaryCopyWith<$Res> {
  _$SessionSummaryCopyWithImpl(this._self, this._then);

  final SessionSummary _self;
  final $Res Function(SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? dailyDate = freezed,Object? submittedAt = freezed,Object? score = freezed,Object? hitRate = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,dailyDate: freezed == dailyDate ? _self.dailyDate : dailyDate // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,hitRate: freezed == hitRate ? _self.hitRate : hitRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionSummary].
extension SessionSummaryPatterns on SessionSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSummary value)  $default,){
final _that = this;
switch (_that) {
case _SessionSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sessionId,  String? dailyDate,  String? submittedAt,  double? score,  double? hitRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.sessionId,_that.dailyDate,_that.submittedAt,_that.score,_that.hitRate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sessionId,  String? dailyDate,  String? submittedAt,  double? score,  double? hitRate)  $default,) {final _that = this;
switch (_that) {
case _SessionSummary():
return $default(_that.sessionId,_that.dailyDate,_that.submittedAt,_that.score,_that.hitRate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sessionId,  String? dailyDate,  String? submittedAt,  double? score,  double? hitRate)?  $default,) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.sessionId,_that.dailyDate,_that.submittedAt,_that.score,_that.hitRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionSummary implements SessionSummary {
  const _SessionSummary({required this.sessionId, this.dailyDate, this.submittedAt, this.score, this.hitRate});
  factory _SessionSummary.fromJson(Map<String, dynamic> json) => _$SessionSummaryFromJson(json);

@override final  int sessionId;
@override final  String? dailyDate;
@override final  String? submittedAt;
@override final  double? score;
@override final  double? hitRate;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSummaryCopyWith<_SessionSummary> get copyWith => __$SessionSummaryCopyWithImpl<_SessionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSummary&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.dailyDate, dailyDate) || other.dailyDate == dailyDate)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.score, score) || other.score == score)&&(identical(other.hitRate, hitRate) || other.hitRate == hitRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,dailyDate,submittedAt,score,hitRate);

@override
String toString() {
  return 'SessionSummary(sessionId: $sessionId, dailyDate: $dailyDate, submittedAt: $submittedAt, score: $score, hitRate: $hitRate)';
}


}

/// @nodoc
abstract mixin class _$SessionSummaryCopyWith<$Res> implements $SessionSummaryCopyWith<$Res> {
  factory _$SessionSummaryCopyWith(_SessionSummary value, $Res Function(_SessionSummary) _then) = __$SessionSummaryCopyWithImpl;
@override @useResult
$Res call({
 int sessionId, String? dailyDate, String? submittedAt, double? score, double? hitRate
});




}
/// @nodoc
class __$SessionSummaryCopyWithImpl<$Res>
    implements _$SessionSummaryCopyWith<$Res> {
  __$SessionSummaryCopyWithImpl(this._self, this._then);

  final _SessionSummary _self;
  final $Res Function(_SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? dailyDate = freezed,Object? submittedAt = freezed,Object? score = freezed,Object? hitRate = freezed,}) {
  return _then(_SessionSummary(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,dailyDate: freezed == dailyDate ? _self.dailyDate : dailyDate // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,hitRate: freezed == hitRate ? _self.hitRate : hitRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$MeStats {

 int get streak; int get roundsPlayed; bool get dailyPlayedToday; double? get todayScore; List<SessionSummary> get recent;
/// Create a copy of MeStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeStatsCopyWith<MeStats> get copyWith => _$MeStatsCopyWithImpl<MeStats>(this as MeStats, _$identity);

  /// Serializes this MeStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeStats&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.roundsPlayed, roundsPlayed) || other.roundsPlayed == roundsPlayed)&&(identical(other.dailyPlayedToday, dailyPlayedToday) || other.dailyPlayedToday == dailyPlayedToday)&&(identical(other.todayScore, todayScore) || other.todayScore == todayScore)&&const DeepCollectionEquality().equals(other.recent, recent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streak,roundsPlayed,dailyPlayedToday,todayScore,const DeepCollectionEquality().hash(recent));

@override
String toString() {
  return 'MeStats(streak: $streak, roundsPlayed: $roundsPlayed, dailyPlayedToday: $dailyPlayedToday, todayScore: $todayScore, recent: $recent)';
}


}

/// @nodoc
abstract mixin class $MeStatsCopyWith<$Res>  {
  factory $MeStatsCopyWith(MeStats value, $Res Function(MeStats) _then) = _$MeStatsCopyWithImpl;
@useResult
$Res call({
 int streak, int roundsPlayed, bool dailyPlayedToday, double? todayScore, List<SessionSummary> recent
});




}
/// @nodoc
class _$MeStatsCopyWithImpl<$Res>
    implements $MeStatsCopyWith<$Res> {
  _$MeStatsCopyWithImpl(this._self, this._then);

  final MeStats _self;
  final $Res Function(MeStats) _then;

/// Create a copy of MeStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streak = null,Object? roundsPlayed = null,Object? dailyPlayedToday = null,Object? todayScore = freezed,Object? recent = null,}) {
  return _then(_self.copyWith(
streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,roundsPlayed: null == roundsPlayed ? _self.roundsPlayed : roundsPlayed // ignore: cast_nullable_to_non_nullable
as int,dailyPlayedToday: null == dailyPlayedToday ? _self.dailyPlayedToday : dailyPlayedToday // ignore: cast_nullable_to_non_nullable
as bool,todayScore: freezed == todayScore ? _self.todayScore : todayScore // ignore: cast_nullable_to_non_nullable
as double?,recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<SessionSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [MeStats].
extension MeStatsPatterns on MeStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeStats value)  $default,){
final _that = this;
switch (_that) {
case _MeStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeStats value)?  $default,){
final _that = this;
switch (_that) {
case _MeStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int streak,  int roundsPlayed,  bool dailyPlayedToday,  double? todayScore,  List<SessionSummary> recent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeStats() when $default != null:
return $default(_that.streak,_that.roundsPlayed,_that.dailyPlayedToday,_that.todayScore,_that.recent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int streak,  int roundsPlayed,  bool dailyPlayedToday,  double? todayScore,  List<SessionSummary> recent)  $default,) {final _that = this;
switch (_that) {
case _MeStats():
return $default(_that.streak,_that.roundsPlayed,_that.dailyPlayedToday,_that.todayScore,_that.recent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int streak,  int roundsPlayed,  bool dailyPlayedToday,  double? todayScore,  List<SessionSummary> recent)?  $default,) {final _that = this;
switch (_that) {
case _MeStats() when $default != null:
return $default(_that.streak,_that.roundsPlayed,_that.dailyPlayedToday,_that.todayScore,_that.recent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeStats implements MeStats {
  const _MeStats({required this.streak, required this.roundsPlayed, required this.dailyPlayedToday, this.todayScore, required final  List<SessionSummary> recent}): _recent = recent;
  factory _MeStats.fromJson(Map<String, dynamic> json) => _$MeStatsFromJson(json);

@override final  int streak;
@override final  int roundsPlayed;
@override final  bool dailyPlayedToday;
@override final  double? todayScore;
 final  List<SessionSummary> _recent;
@override List<SessionSummary> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}


/// Create a copy of MeStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeStatsCopyWith<_MeStats> get copyWith => __$MeStatsCopyWithImpl<_MeStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeStats&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.roundsPlayed, roundsPlayed) || other.roundsPlayed == roundsPlayed)&&(identical(other.dailyPlayedToday, dailyPlayedToday) || other.dailyPlayedToday == dailyPlayedToday)&&(identical(other.todayScore, todayScore) || other.todayScore == todayScore)&&const DeepCollectionEquality().equals(other._recent, _recent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streak,roundsPlayed,dailyPlayedToday,todayScore,const DeepCollectionEquality().hash(_recent));

@override
String toString() {
  return 'MeStats(streak: $streak, roundsPlayed: $roundsPlayed, dailyPlayedToday: $dailyPlayedToday, todayScore: $todayScore, recent: $recent)';
}


}

/// @nodoc
abstract mixin class _$MeStatsCopyWith<$Res> implements $MeStatsCopyWith<$Res> {
  factory _$MeStatsCopyWith(_MeStats value, $Res Function(_MeStats) _then) = __$MeStatsCopyWithImpl;
@override @useResult
$Res call({
 int streak, int roundsPlayed, bool dailyPlayedToday, double? todayScore, List<SessionSummary> recent
});




}
/// @nodoc
class __$MeStatsCopyWithImpl<$Res>
    implements _$MeStatsCopyWith<$Res> {
  __$MeStatsCopyWithImpl(this._self, this._then);

  final _MeStats _self;
  final $Res Function(_MeStats) _then;

/// Create a copy of MeStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streak = null,Object? roundsPlayed = null,Object? dailyPlayedToday = null,Object? todayScore = freezed,Object? recent = null,}) {
  return _then(_MeStats(
streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,roundsPlayed: null == roundsPlayed ? _self.roundsPlayed : roundsPlayed // ignore: cast_nullable_to_non_nullable
as int,dailyPlayedToday: null == dailyPlayedToday ? _self.dailyPlayedToday : dailyPlayedToday // ignore: cast_nullable_to_non_nullable
as bool,todayScore: freezed == todayScore ? _self.todayScore : todayScore // ignore: cast_nullable_to_non_nullable
as double?,recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<SessionSummary>,
  ));
}


}

// dart format on
