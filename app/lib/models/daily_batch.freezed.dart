// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_batch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Intro {

 String get marketSentiment; String get ratePicture; String get note;
/// Create a copy of Intro
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntroCopyWith<Intro> get copyWith => _$IntroCopyWithImpl<Intro>(this as Intro, _$identity);

  /// Serializes this Intro to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Intro&&(identical(other.marketSentiment, marketSentiment) || other.marketSentiment == marketSentiment)&&(identical(other.ratePicture, ratePicture) || other.ratePicture == ratePicture)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,marketSentiment,ratePicture,note);

@override
String toString() {
  return 'Intro(marketSentiment: $marketSentiment, ratePicture: $ratePicture, note: $note)';
}


}

/// @nodoc
abstract mixin class $IntroCopyWith<$Res>  {
  factory $IntroCopyWith(Intro value, $Res Function(Intro) _then) = _$IntroCopyWithImpl;
@useResult
$Res call({
 String marketSentiment, String ratePicture, String note
});




}
/// @nodoc
class _$IntroCopyWithImpl<$Res>
    implements $IntroCopyWith<$Res> {
  _$IntroCopyWithImpl(this._self, this._then);

  final Intro _self;
  final $Res Function(Intro) _then;

/// Create a copy of Intro
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? marketSentiment = null,Object? ratePicture = null,Object? note = null,}) {
  return _then(_self.copyWith(
marketSentiment: null == marketSentiment ? _self.marketSentiment : marketSentiment // ignore: cast_nullable_to_non_nullable
as String,ratePicture: null == ratePicture ? _self.ratePicture : ratePicture // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Intro].
extension IntroPatterns on Intro {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Intro value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Intro() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Intro value)  $default,){
final _that = this;
switch (_that) {
case _Intro():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Intro value)?  $default,){
final _that = this;
switch (_that) {
case _Intro() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String marketSentiment,  String ratePicture,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Intro() when $default != null:
return $default(_that.marketSentiment,_that.ratePicture,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String marketSentiment,  String ratePicture,  String note)  $default,) {final _that = this;
switch (_that) {
case _Intro():
return $default(_that.marketSentiment,_that.ratePicture,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String marketSentiment,  String ratePicture,  String note)?  $default,) {final _that = this;
switch (_that) {
case _Intro() when $default != null:
return $default(_that.marketSentiment,_that.ratePicture,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Intro implements Intro {
  const _Intro({required this.marketSentiment, required this.ratePicture, required this.note});
  factory _Intro.fromJson(Map<String, dynamic> json) => _$IntroFromJson(json);

@override final  String marketSentiment;
@override final  String ratePicture;
@override final  String note;

/// Create a copy of Intro
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntroCopyWith<_Intro> get copyWith => __$IntroCopyWithImpl<_Intro>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntroToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Intro&&(identical(other.marketSentiment, marketSentiment) || other.marketSentiment == marketSentiment)&&(identical(other.ratePicture, ratePicture) || other.ratePicture == ratePicture)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,marketSentiment,ratePicture,note);

@override
String toString() {
  return 'Intro(marketSentiment: $marketSentiment, ratePicture: $ratePicture, note: $note)';
}


}

/// @nodoc
abstract mixin class _$IntroCopyWith<$Res> implements $IntroCopyWith<$Res> {
  factory _$IntroCopyWith(_Intro value, $Res Function(_Intro) _then) = __$IntroCopyWithImpl;
@override @useResult
$Res call({
 String marketSentiment, String ratePicture, String note
});




}
/// @nodoc
class __$IntroCopyWithImpl<$Res>
    implements _$IntroCopyWith<$Res> {
  __$IntroCopyWithImpl(this._self, this._then);

  final _Intro _self;
  final $Res Function(_Intro) _then;

/// Create a copy of Intro
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? marketSentiment = null,Object? ratePicture = null,Object? note = null,}) {
  return _then(_Intro(
marketSentiment: null == marketSentiment ? _self.marketSentiment : marketSentiment // ignore: cast_nullable_to_non_nullable
as String,ratePicture: null == ratePicture ? _self.ratePicture : ratePicture // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DailyBatch {

 int get batchId; String get mode; bool get isDaily; String get dailyDate; int get horizonYears; Intro get intro; List<GameCard> get cards;
/// Create a copy of DailyBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyBatchCopyWith<DailyBatch> get copyWith => _$DailyBatchCopyWithImpl<DailyBatch>(this as DailyBatch, _$identity);

  /// Serializes this DailyBatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyBatch&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.isDaily, isDaily) || other.isDaily == isDaily)&&(identical(other.dailyDate, dailyDate) || other.dailyDate == dailyDate)&&(identical(other.horizonYears, horizonYears) || other.horizonYears == horizonYears)&&(identical(other.intro, intro) || other.intro == intro)&&const DeepCollectionEquality().equals(other.cards, cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,batchId,mode,isDaily,dailyDate,horizonYears,intro,const DeepCollectionEquality().hash(cards));

@override
String toString() {
  return 'DailyBatch(batchId: $batchId, mode: $mode, isDaily: $isDaily, dailyDate: $dailyDate, horizonYears: $horizonYears, intro: $intro, cards: $cards)';
}


}

/// @nodoc
abstract mixin class $DailyBatchCopyWith<$Res>  {
  factory $DailyBatchCopyWith(DailyBatch value, $Res Function(DailyBatch) _then) = _$DailyBatchCopyWithImpl;
@useResult
$Res call({
 int batchId, String mode, bool isDaily, String dailyDate, int horizonYears, Intro intro, List<GameCard> cards
});


$IntroCopyWith<$Res> get intro;

}
/// @nodoc
class _$DailyBatchCopyWithImpl<$Res>
    implements $DailyBatchCopyWith<$Res> {
  _$DailyBatchCopyWithImpl(this._self, this._then);

  final DailyBatch _self;
  final $Res Function(DailyBatch) _then;

/// Create a copy of DailyBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? batchId = null,Object? mode = null,Object? isDaily = null,Object? dailyDate = null,Object? horizonYears = null,Object? intro = null,Object? cards = null,}) {
  return _then(_self.copyWith(
batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,isDaily: null == isDaily ? _self.isDaily : isDaily // ignore: cast_nullable_to_non_nullable
as bool,dailyDate: null == dailyDate ? _self.dailyDate : dailyDate // ignore: cast_nullable_to_non_nullable
as String,horizonYears: null == horizonYears ? _self.horizonYears : horizonYears // ignore: cast_nullable_to_non_nullable
as int,intro: null == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as Intro,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<GameCard>,
  ));
}
/// Create a copy of DailyBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IntroCopyWith<$Res> get intro {
  
  return $IntroCopyWith<$Res>(_self.intro, (value) {
    return _then(_self.copyWith(intro: value));
  });
}
}


/// Adds pattern-matching-related methods to [DailyBatch].
extension DailyBatchPatterns on DailyBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyBatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyBatch value)  $default,){
final _that = this;
switch (_that) {
case _DailyBatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyBatch value)?  $default,){
final _that = this;
switch (_that) {
case _DailyBatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int batchId,  String mode,  bool isDaily,  String dailyDate,  int horizonYears,  Intro intro,  List<GameCard> cards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyBatch() when $default != null:
return $default(_that.batchId,_that.mode,_that.isDaily,_that.dailyDate,_that.horizonYears,_that.intro,_that.cards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int batchId,  String mode,  bool isDaily,  String dailyDate,  int horizonYears,  Intro intro,  List<GameCard> cards)  $default,) {final _that = this;
switch (_that) {
case _DailyBatch():
return $default(_that.batchId,_that.mode,_that.isDaily,_that.dailyDate,_that.horizonYears,_that.intro,_that.cards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int batchId,  String mode,  bool isDaily,  String dailyDate,  int horizonYears,  Intro intro,  List<GameCard> cards)?  $default,) {final _that = this;
switch (_that) {
case _DailyBatch() when $default != null:
return $default(_that.batchId,_that.mode,_that.isDaily,_that.dailyDate,_that.horizonYears,_that.intro,_that.cards);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyBatch implements DailyBatch {
  const _DailyBatch({required this.batchId, required this.mode, required this.isDaily, required this.dailyDate, required this.horizonYears, required this.intro, required final  List<GameCard> cards}): _cards = cards;
  factory _DailyBatch.fromJson(Map<String, dynamic> json) => _$DailyBatchFromJson(json);

@override final  int batchId;
@override final  String mode;
@override final  bool isDaily;
@override final  String dailyDate;
@override final  int horizonYears;
@override final  Intro intro;
 final  List<GameCard> _cards;
@override List<GameCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}


/// Create a copy of DailyBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyBatchCopyWith<_DailyBatch> get copyWith => __$DailyBatchCopyWithImpl<_DailyBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyBatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyBatch&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.isDaily, isDaily) || other.isDaily == isDaily)&&(identical(other.dailyDate, dailyDate) || other.dailyDate == dailyDate)&&(identical(other.horizonYears, horizonYears) || other.horizonYears == horizonYears)&&(identical(other.intro, intro) || other.intro == intro)&&const DeepCollectionEquality().equals(other._cards, _cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,batchId,mode,isDaily,dailyDate,horizonYears,intro,const DeepCollectionEquality().hash(_cards));

@override
String toString() {
  return 'DailyBatch(batchId: $batchId, mode: $mode, isDaily: $isDaily, dailyDate: $dailyDate, horizonYears: $horizonYears, intro: $intro, cards: $cards)';
}


}

/// @nodoc
abstract mixin class _$DailyBatchCopyWith<$Res> implements $DailyBatchCopyWith<$Res> {
  factory _$DailyBatchCopyWith(_DailyBatch value, $Res Function(_DailyBatch) _then) = __$DailyBatchCopyWithImpl;
@override @useResult
$Res call({
 int batchId, String mode, bool isDaily, String dailyDate, int horizonYears, Intro intro, List<GameCard> cards
});


@override $IntroCopyWith<$Res> get intro;

}
/// @nodoc
class __$DailyBatchCopyWithImpl<$Res>
    implements _$DailyBatchCopyWith<$Res> {
  __$DailyBatchCopyWithImpl(this._self, this._then);

  final _DailyBatch _self;
  final $Res Function(_DailyBatch) _then;

/// Create a copy of DailyBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? batchId = null,Object? mode = null,Object? isDaily = null,Object? dailyDate = null,Object? horizonYears = null,Object? intro = null,Object? cards = null,}) {
  return _then(_DailyBatch(
batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,isDaily: null == isDaily ? _self.isDaily : isDaily // ignore: cast_nullable_to_non_nullable
as bool,dailyDate: null == dailyDate ? _self.dailyDate : dailyDate // ignore: cast_nullable_to_non_nullable
as String,horizonYears: null == horizonYears ? _self.horizonYears : horizonYears // ignore: cast_nullable_to_non_nullable
as int,intro: null == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as Intro,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<GameCard>,
  ));
}

/// Create a copy of DailyBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IntroCopyWith<$Res> get intro {
  
  return $IntroCopyWith<$Res>(_self.intro, (value) {
    return _then(_self.copyWith(intro: value));
  });
}
}

// dart format on
