// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reveal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Benchmark {

@JsonKey(name: 'R_m') double get rmCum;@JsonKey(name: 'r_m') double get rm;@JsonKey(name: 'r_f') double get rf; double get alphaCash;
/// Create a copy of Benchmark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BenchmarkCopyWith<Benchmark> get copyWith => _$BenchmarkCopyWithImpl<Benchmark>(this as Benchmark, _$identity);

  /// Serializes this Benchmark to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Benchmark&&(identical(other.rmCum, rmCum) || other.rmCum == rmCum)&&(identical(other.rm, rm) || other.rm == rm)&&(identical(other.rf, rf) || other.rf == rf)&&(identical(other.alphaCash, alphaCash) || other.alphaCash == alphaCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rmCum,rm,rf,alphaCash);

@override
String toString() {
  return 'Benchmark(rmCum: $rmCum, rm: $rm, rf: $rf, alphaCash: $alphaCash)';
}


}

/// @nodoc
abstract mixin class $BenchmarkCopyWith<$Res>  {
  factory $BenchmarkCopyWith(Benchmark value, $Res Function(Benchmark) _then) = _$BenchmarkCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'R_m') double rmCum,@JsonKey(name: 'r_m') double rm,@JsonKey(name: 'r_f') double rf, double alphaCash
});




}
/// @nodoc
class _$BenchmarkCopyWithImpl<$Res>
    implements $BenchmarkCopyWith<$Res> {
  _$BenchmarkCopyWithImpl(this._self, this._then);

  final Benchmark _self;
  final $Res Function(Benchmark) _then;

/// Create a copy of Benchmark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rmCum = null,Object? rm = null,Object? rf = null,Object? alphaCash = null,}) {
  return _then(_self.copyWith(
rmCum: null == rmCum ? _self.rmCum : rmCum // ignore: cast_nullable_to_non_nullable
as double,rm: null == rm ? _self.rm : rm // ignore: cast_nullable_to_non_nullable
as double,rf: null == rf ? _self.rf : rf // ignore: cast_nullable_to_non_nullable
as double,alphaCash: null == alphaCash ? _self.alphaCash : alphaCash // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Benchmark].
extension BenchmarkPatterns on Benchmark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Benchmark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Benchmark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Benchmark value)  $default,){
final _that = this;
switch (_that) {
case _Benchmark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Benchmark value)?  $default,){
final _that = this;
switch (_that) {
case _Benchmark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'R_m')  double rmCum, @JsonKey(name: 'r_m')  double rm, @JsonKey(name: 'r_f')  double rf,  double alphaCash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Benchmark() when $default != null:
return $default(_that.rmCum,_that.rm,_that.rf,_that.alphaCash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'R_m')  double rmCum, @JsonKey(name: 'r_m')  double rm, @JsonKey(name: 'r_f')  double rf,  double alphaCash)  $default,) {final _that = this;
switch (_that) {
case _Benchmark():
return $default(_that.rmCum,_that.rm,_that.rf,_that.alphaCash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'R_m')  double rmCum, @JsonKey(name: 'r_m')  double rm, @JsonKey(name: 'r_f')  double rf,  double alphaCash)?  $default,) {final _that = this;
switch (_that) {
case _Benchmark() when $default != null:
return $default(_that.rmCum,_that.rm,_that.rf,_that.alphaCash);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Benchmark implements Benchmark {
  const _Benchmark({@JsonKey(name: 'R_m') required this.rmCum, @JsonKey(name: 'r_m') required this.rm, @JsonKey(name: 'r_f') required this.rf, required this.alphaCash});
  factory _Benchmark.fromJson(Map<String, dynamic> json) => _$BenchmarkFromJson(json);

@override@JsonKey(name: 'R_m') final  double rmCum;
@override@JsonKey(name: 'r_m') final  double rm;
@override@JsonKey(name: 'r_f') final  double rf;
@override final  double alphaCash;

/// Create a copy of Benchmark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BenchmarkCopyWith<_Benchmark> get copyWith => __$BenchmarkCopyWithImpl<_Benchmark>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BenchmarkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Benchmark&&(identical(other.rmCum, rmCum) || other.rmCum == rmCum)&&(identical(other.rm, rm) || other.rm == rm)&&(identical(other.rf, rf) || other.rf == rf)&&(identical(other.alphaCash, alphaCash) || other.alphaCash == alphaCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rmCum,rm,rf,alphaCash);

@override
String toString() {
  return 'Benchmark(rmCum: $rmCum, rm: $rm, rf: $rf, alphaCash: $alphaCash)';
}


}

/// @nodoc
abstract mixin class _$BenchmarkCopyWith<$Res> implements $BenchmarkCopyWith<$Res> {
  factory _$BenchmarkCopyWith(_Benchmark value, $Res Function(_Benchmark) _then) = __$BenchmarkCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'R_m') double rmCum,@JsonKey(name: 'r_m') double rm,@JsonKey(name: 'r_f') double rf, double alphaCash
});




}
/// @nodoc
class __$BenchmarkCopyWithImpl<$Res>
    implements _$BenchmarkCopyWith<$Res> {
  __$BenchmarkCopyWithImpl(this._self, this._then);

  final _Benchmark _self;
  final $Res Function(_Benchmark) _then;

/// Create a copy of Benchmark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rmCum = null,Object? rm = null,Object? rf = null,Object? alphaCash = null,}) {
  return _then(_Benchmark(
rmCum: null == rmCum ? _self.rmCum : rmCum // ignore: cast_nullable_to_non_nullable
as double,rm: null == rm ? _self.rm : rm // ignore: cast_nullable_to_non_nullable
as double,rf: null == rf ? _self.rf : rf // ignore: cast_nullable_to_non_nullable
as double,alphaCash: null == alphaCash ? _self.alphaCash : alphaCash // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$RevealCard {

 int get cardNo; String get ticker; String get name; Choice get choice;@JsonKey(name: 'R') double get rCum; double get r; double get alpha; double get a; double get points; String get clue; String? get event;// 'acquired' | 'delisted' | null
 int get companyId;
/// Create a copy of RevealCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevealCardCopyWith<RevealCard> get copyWith => _$RevealCardCopyWithImpl<RevealCard>(this as RevealCard, _$identity);

  /// Serializes this RevealCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevealCard&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.choice, choice) || other.choice == choice)&&(identical(other.rCum, rCum) || other.rCum == rCum)&&(identical(other.r, r) || other.r == r)&&(identical(other.alpha, alpha) || other.alpha == alpha)&&(identical(other.a, a) || other.a == a)&&(identical(other.points, points) || other.points == points)&&(identical(other.clue, clue) || other.clue == clue)&&(identical(other.event, event) || other.event == event)&&(identical(other.companyId, companyId) || other.companyId == companyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardNo,ticker,name,choice,rCum,r,alpha,a,points,clue,event,companyId);

@override
String toString() {
  return 'RevealCard(cardNo: $cardNo, ticker: $ticker, name: $name, choice: $choice, rCum: $rCum, r: $r, alpha: $alpha, a: $a, points: $points, clue: $clue, event: $event, companyId: $companyId)';
}


}

/// @nodoc
abstract mixin class $RevealCardCopyWith<$Res>  {
  factory $RevealCardCopyWith(RevealCard value, $Res Function(RevealCard) _then) = _$RevealCardCopyWithImpl;
@useResult
$Res call({
 int cardNo, String ticker, String name, Choice choice,@JsonKey(name: 'R') double rCum, double r, double alpha, double a, double points, String clue, String? event, int companyId
});




}
/// @nodoc
class _$RevealCardCopyWithImpl<$Res>
    implements $RevealCardCopyWith<$Res> {
  _$RevealCardCopyWithImpl(this._self, this._then);

  final RevealCard _self;
  final $Res Function(RevealCard) _then;

/// Create a copy of RevealCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardNo = null,Object? ticker = null,Object? name = null,Object? choice = null,Object? rCum = null,Object? r = null,Object? alpha = null,Object? a = null,Object? points = null,Object? clue = null,Object? event = freezed,Object? companyId = null,}) {
  return _then(_self.copyWith(
cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as int,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,choice: null == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as Choice,rCum: null == rCum ? _self.rCum : rCum // ignore: cast_nullable_to_non_nullable
as double,r: null == r ? _self.r : r // ignore: cast_nullable_to_non_nullable
as double,alpha: null == alpha ? _self.alpha : alpha // ignore: cast_nullable_to_non_nullable
as double,a: null == a ? _self.a : a // ignore: cast_nullable_to_non_nullable
as double,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double,clue: null == clue ? _self.clue : clue // ignore: cast_nullable_to_non_nullable
as String,event: freezed == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RevealCard].
extension RevealCardPatterns on RevealCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevealCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevealCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevealCard value)  $default,){
final _that = this;
switch (_that) {
case _RevealCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevealCard value)?  $default,){
final _that = this;
switch (_that) {
case _RevealCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cardNo,  String ticker,  String name,  Choice choice, @JsonKey(name: 'R')  double rCum,  double r,  double alpha,  double a,  double points,  String clue,  String? event,  int companyId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevealCard() when $default != null:
return $default(_that.cardNo,_that.ticker,_that.name,_that.choice,_that.rCum,_that.r,_that.alpha,_that.a,_that.points,_that.clue,_that.event,_that.companyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cardNo,  String ticker,  String name,  Choice choice, @JsonKey(name: 'R')  double rCum,  double r,  double alpha,  double a,  double points,  String clue,  String? event,  int companyId)  $default,) {final _that = this;
switch (_that) {
case _RevealCard():
return $default(_that.cardNo,_that.ticker,_that.name,_that.choice,_that.rCum,_that.r,_that.alpha,_that.a,_that.points,_that.clue,_that.event,_that.companyId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cardNo,  String ticker,  String name,  Choice choice, @JsonKey(name: 'R')  double rCum,  double r,  double alpha,  double a,  double points,  String clue,  String? event,  int companyId)?  $default,) {final _that = this;
switch (_that) {
case _RevealCard() when $default != null:
return $default(_that.cardNo,_that.ticker,_that.name,_that.choice,_that.rCum,_that.r,_that.alpha,_that.a,_that.points,_that.clue,_that.event,_that.companyId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevealCard implements RevealCard {
  const _RevealCard({required this.cardNo, required this.ticker, required this.name, required this.choice, @JsonKey(name: 'R') required this.rCum, required this.r, required this.alpha, required this.a, required this.points, required this.clue, this.event, required this.companyId});
  factory _RevealCard.fromJson(Map<String, dynamic> json) => _$RevealCardFromJson(json);

@override final  int cardNo;
@override final  String ticker;
@override final  String name;
@override final  Choice choice;
@override@JsonKey(name: 'R') final  double rCum;
@override final  double r;
@override final  double alpha;
@override final  double a;
@override final  double points;
@override final  String clue;
@override final  String? event;
// 'acquired' | 'delisted' | null
@override final  int companyId;

/// Create a copy of RevealCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevealCardCopyWith<_RevealCard> get copyWith => __$RevealCardCopyWithImpl<_RevealCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevealCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevealCard&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.name, name) || other.name == name)&&(identical(other.choice, choice) || other.choice == choice)&&(identical(other.rCum, rCum) || other.rCum == rCum)&&(identical(other.r, r) || other.r == r)&&(identical(other.alpha, alpha) || other.alpha == alpha)&&(identical(other.a, a) || other.a == a)&&(identical(other.points, points) || other.points == points)&&(identical(other.clue, clue) || other.clue == clue)&&(identical(other.event, event) || other.event == event)&&(identical(other.companyId, companyId) || other.companyId == companyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardNo,ticker,name,choice,rCum,r,alpha,a,points,clue,event,companyId);

@override
String toString() {
  return 'RevealCard(cardNo: $cardNo, ticker: $ticker, name: $name, choice: $choice, rCum: $rCum, r: $r, alpha: $alpha, a: $a, points: $points, clue: $clue, event: $event, companyId: $companyId)';
}


}

/// @nodoc
abstract mixin class _$RevealCardCopyWith<$Res> implements $RevealCardCopyWith<$Res> {
  factory _$RevealCardCopyWith(_RevealCard value, $Res Function(_RevealCard) _then) = __$RevealCardCopyWithImpl;
@override @useResult
$Res call({
 int cardNo, String ticker, String name, Choice choice,@JsonKey(name: 'R') double rCum, double r, double alpha, double a, double points, String clue, String? event, int companyId
});




}
/// @nodoc
class __$RevealCardCopyWithImpl<$Res>
    implements _$RevealCardCopyWith<$Res> {
  __$RevealCardCopyWithImpl(this._self, this._then);

  final _RevealCard _self;
  final $Res Function(_RevealCard) _then;

/// Create a copy of RevealCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardNo = null,Object? ticker = null,Object? name = null,Object? choice = null,Object? rCum = null,Object? r = null,Object? alpha = null,Object? a = null,Object? points = null,Object? clue = null,Object? event = freezed,Object? companyId = null,}) {
  return _then(_RevealCard(
cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as int,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,choice: null == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as Choice,rCum: null == rCum ? _self.rCum : rCum // ignore: cast_nullable_to_non_nullable
as double,r: null == r ? _self.r : r // ignore: cast_nullable_to_non_nullable
as double,alpha: null == alpha ? _self.alpha : alpha // ignore: cast_nullable_to_non_nullable
as double,a: null == a ? _self.a : a // ignore: cast_nullable_to_non_nullable
as double,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double,clue: null == clue ? _self.clue : clue // ignore: cast_nullable_to_non_nullable
as String,event: freezed == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$IdealChoice {

 int get cardNo; Choice get choice;
/// Create a copy of IdealChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdealChoiceCopyWith<IdealChoice> get copyWith => _$IdealChoiceCopyWithImpl<IdealChoice>(this as IdealChoice, _$identity);

  /// Serializes this IdealChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdealChoice&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.choice, choice) || other.choice == choice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardNo,choice);

@override
String toString() {
  return 'IdealChoice(cardNo: $cardNo, choice: $choice)';
}


}

/// @nodoc
abstract mixin class $IdealChoiceCopyWith<$Res>  {
  factory $IdealChoiceCopyWith(IdealChoice value, $Res Function(IdealChoice) _then) = _$IdealChoiceCopyWithImpl;
@useResult
$Res call({
 int cardNo, Choice choice
});




}
/// @nodoc
class _$IdealChoiceCopyWithImpl<$Res>
    implements $IdealChoiceCopyWith<$Res> {
  _$IdealChoiceCopyWithImpl(this._self, this._then);

  final IdealChoice _self;
  final $Res Function(IdealChoice) _then;

/// Create a copy of IdealChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardNo = null,Object? choice = null,}) {
  return _then(_self.copyWith(
cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as int,choice: null == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as Choice,
  ));
}

}


/// Adds pattern-matching-related methods to [IdealChoice].
extension IdealChoicePatterns on IdealChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IdealChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IdealChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IdealChoice value)  $default,){
final _that = this;
switch (_that) {
case _IdealChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IdealChoice value)?  $default,){
final _that = this;
switch (_that) {
case _IdealChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cardNo,  Choice choice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IdealChoice() when $default != null:
return $default(_that.cardNo,_that.choice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cardNo,  Choice choice)  $default,) {final _that = this;
switch (_that) {
case _IdealChoice():
return $default(_that.cardNo,_that.choice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cardNo,  Choice choice)?  $default,) {final _that = this;
switch (_that) {
case _IdealChoice() when $default != null:
return $default(_that.cardNo,_that.choice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IdealChoice implements IdealChoice {
  const _IdealChoice({required this.cardNo, required this.choice});
  factory _IdealChoice.fromJson(Map<String, dynamic> json) => _$IdealChoiceFromJson(json);

@override final  int cardNo;
@override final  Choice choice;

/// Create a copy of IdealChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IdealChoiceCopyWith<_IdealChoice> get copyWith => __$IdealChoiceCopyWithImpl<_IdealChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IdealChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IdealChoice&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.choice, choice) || other.choice == choice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardNo,choice);

@override
String toString() {
  return 'IdealChoice(cardNo: $cardNo, choice: $choice)';
}


}

/// @nodoc
abstract mixin class _$IdealChoiceCopyWith<$Res> implements $IdealChoiceCopyWith<$Res> {
  factory _$IdealChoiceCopyWith(_IdealChoice value, $Res Function(_IdealChoice) _then) = __$IdealChoiceCopyWithImpl;
@override @useResult
$Res call({
 int cardNo, Choice choice
});




}
/// @nodoc
class __$IdealChoiceCopyWithImpl<$Res>
    implements _$IdealChoiceCopyWith<$Res> {
  __$IdealChoiceCopyWithImpl(this._self, this._then);

  final _IdealChoice _self;
  final $Res Function(_IdealChoice) _then;

/// Create a copy of IdealChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardNo = null,Object? choice = null,}) {
  return _then(_IdealChoice(
cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as int,choice: null == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as Choice,
  ));
}


}


/// @nodoc
mixin _$Ideal {

 List<IdealChoice> get choices; double get score;
/// Create a copy of Ideal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdealCopyWith<Ideal> get copyWith => _$IdealCopyWithImpl<Ideal>(this as Ideal, _$identity);

  /// Serializes this Ideal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ideal&&const DeepCollectionEquality().equals(other.choices, choices)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(choices),score);

@override
String toString() {
  return 'Ideal(choices: $choices, score: $score)';
}


}

/// @nodoc
abstract mixin class $IdealCopyWith<$Res>  {
  factory $IdealCopyWith(Ideal value, $Res Function(Ideal) _then) = _$IdealCopyWithImpl;
@useResult
$Res call({
 List<IdealChoice> choices, double score
});




}
/// @nodoc
class _$IdealCopyWithImpl<$Res>
    implements $IdealCopyWith<$Res> {
  _$IdealCopyWithImpl(this._self, this._then);

  final Ideal _self;
  final $Res Function(Ideal) _then;

/// Create a copy of Ideal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? choices = null,Object? score = null,}) {
  return _then(_self.copyWith(
choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<IdealChoice>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Ideal].
extension IdealPatterns on Ideal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ideal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ideal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ideal value)  $default,){
final _that = this;
switch (_that) {
case _Ideal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ideal value)?  $default,){
final _that = this;
switch (_that) {
case _Ideal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<IdealChoice> choices,  double score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ideal() when $default != null:
return $default(_that.choices,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<IdealChoice> choices,  double score)  $default,) {final _that = this;
switch (_that) {
case _Ideal():
return $default(_that.choices,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<IdealChoice> choices,  double score)?  $default,) {final _that = this;
switch (_that) {
case _Ideal() when $default != null:
return $default(_that.choices,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ideal implements Ideal {
  const _Ideal({required final  List<IdealChoice> choices, required this.score}): _choices = choices;
  factory _Ideal.fromJson(Map<String, dynamic> json) => _$IdealFromJson(json);

 final  List<IdealChoice> _choices;
@override List<IdealChoice> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}

@override final  double score;

/// Create a copy of Ideal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IdealCopyWith<_Ideal> get copyWith => __$IdealCopyWithImpl<_Ideal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IdealToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ideal&&const DeepCollectionEquality().equals(other._choices, _choices)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_choices),score);

@override
String toString() {
  return 'Ideal(choices: $choices, score: $score)';
}


}

/// @nodoc
abstract mixin class _$IdealCopyWith<$Res> implements $IdealCopyWith<$Res> {
  factory _$IdealCopyWith(_Ideal value, $Res Function(_Ideal) _then) = __$IdealCopyWithImpl;
@override @useResult
$Res call({
 List<IdealChoice> choices, double score
});




}
/// @nodoc
class __$IdealCopyWithImpl<$Res>
    implements _$IdealCopyWith<$Res> {
  __$IdealCopyWithImpl(this._self, this._then);

  final _Ideal _self;
  final $Res Function(_Ideal) _then;

/// Create a copy of Ideal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? choices = null,Object? score = null,}) {
  return _then(_Ideal(
choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<IdealChoice>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Reveal {

 int get sessionId; double get score; double get bonus; double? get hitRate;// null when the round had no long/short choices
 Benchmark get benchmark; String get decisionDate; int get horizonYears; List<RevealCard> get cards; Ideal get ideal;
/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevealCopyWith<Reveal> get copyWith => _$RevealCopyWithImpl<Reveal>(this as Reveal, _$identity);

  /// Serializes this Reveal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reveal&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.score, score) || other.score == score)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.hitRate, hitRate) || other.hitRate == hitRate)&&(identical(other.benchmark, benchmark) || other.benchmark == benchmark)&&(identical(other.decisionDate, decisionDate) || other.decisionDate == decisionDate)&&(identical(other.horizonYears, horizonYears) || other.horizonYears == horizonYears)&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.ideal, ideal) || other.ideal == ideal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,score,bonus,hitRate,benchmark,decisionDate,horizonYears,const DeepCollectionEquality().hash(cards),ideal);

@override
String toString() {
  return 'Reveal(sessionId: $sessionId, score: $score, bonus: $bonus, hitRate: $hitRate, benchmark: $benchmark, decisionDate: $decisionDate, horizonYears: $horizonYears, cards: $cards, ideal: $ideal)';
}


}

/// @nodoc
abstract mixin class $RevealCopyWith<$Res>  {
  factory $RevealCopyWith(Reveal value, $Res Function(Reveal) _then) = _$RevealCopyWithImpl;
@useResult
$Res call({
 int sessionId, double score, double bonus, double? hitRate, Benchmark benchmark, String decisionDate, int horizonYears, List<RevealCard> cards, Ideal ideal
});


$BenchmarkCopyWith<$Res> get benchmark;$IdealCopyWith<$Res> get ideal;

}
/// @nodoc
class _$RevealCopyWithImpl<$Res>
    implements $RevealCopyWith<$Res> {
  _$RevealCopyWithImpl(this._self, this._then);

  final Reveal _self;
  final $Res Function(Reveal) _then;

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? score = null,Object? bonus = null,Object? hitRate = freezed,Object? benchmark = null,Object? decisionDate = null,Object? horizonYears = null,Object? cards = null,Object? ideal = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as double,hitRate: freezed == hitRate ? _self.hitRate : hitRate // ignore: cast_nullable_to_non_nullable
as double?,benchmark: null == benchmark ? _self.benchmark : benchmark // ignore: cast_nullable_to_non_nullable
as Benchmark,decisionDate: null == decisionDate ? _self.decisionDate : decisionDate // ignore: cast_nullable_to_non_nullable
as String,horizonYears: null == horizonYears ? _self.horizonYears : horizonYears // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<RevealCard>,ideal: null == ideal ? _self.ideal : ideal // ignore: cast_nullable_to_non_nullable
as Ideal,
  ));
}
/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BenchmarkCopyWith<$Res> get benchmark {
  
  return $BenchmarkCopyWith<$Res>(_self.benchmark, (value) {
    return _then(_self.copyWith(benchmark: value));
  });
}/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IdealCopyWith<$Res> get ideal {
  
  return $IdealCopyWith<$Res>(_self.ideal, (value) {
    return _then(_self.copyWith(ideal: value));
  });
}
}


/// Adds pattern-matching-related methods to [Reveal].
extension RevealPatterns on Reveal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reveal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reveal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reveal value)  $default,){
final _that = this;
switch (_that) {
case _Reveal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reveal value)?  $default,){
final _that = this;
switch (_that) {
case _Reveal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sessionId,  double score,  double bonus,  double? hitRate,  Benchmark benchmark,  String decisionDate,  int horizonYears,  List<RevealCard> cards,  Ideal ideal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that.sessionId,_that.score,_that.bonus,_that.hitRate,_that.benchmark,_that.decisionDate,_that.horizonYears,_that.cards,_that.ideal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sessionId,  double score,  double bonus,  double? hitRate,  Benchmark benchmark,  String decisionDate,  int horizonYears,  List<RevealCard> cards,  Ideal ideal)  $default,) {final _that = this;
switch (_that) {
case _Reveal():
return $default(_that.sessionId,_that.score,_that.bonus,_that.hitRate,_that.benchmark,_that.decisionDate,_that.horizonYears,_that.cards,_that.ideal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sessionId,  double score,  double bonus,  double? hitRate,  Benchmark benchmark,  String decisionDate,  int horizonYears,  List<RevealCard> cards,  Ideal ideal)?  $default,) {final _that = this;
switch (_that) {
case _Reveal() when $default != null:
return $default(_that.sessionId,_that.score,_that.bonus,_that.hitRate,_that.benchmark,_that.decisionDate,_that.horizonYears,_that.cards,_that.ideal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reveal implements Reveal {
  const _Reveal({required this.sessionId, required this.score, required this.bonus, this.hitRate, required this.benchmark, required this.decisionDate, required this.horizonYears, required final  List<RevealCard> cards, required this.ideal}): _cards = cards;
  factory _Reveal.fromJson(Map<String, dynamic> json) => _$RevealFromJson(json);

@override final  int sessionId;
@override final  double score;
@override final  double bonus;
@override final  double? hitRate;
// null when the round had no long/short choices
@override final  Benchmark benchmark;
@override final  String decisionDate;
@override final  int horizonYears;
 final  List<RevealCard> _cards;
@override List<RevealCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

@override final  Ideal ideal;

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevealCopyWith<_Reveal> get copyWith => __$RevealCopyWithImpl<_Reveal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevealToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reveal&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.score, score) || other.score == score)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.hitRate, hitRate) || other.hitRate == hitRate)&&(identical(other.benchmark, benchmark) || other.benchmark == benchmark)&&(identical(other.decisionDate, decisionDate) || other.decisionDate == decisionDate)&&(identical(other.horizonYears, horizonYears) || other.horizonYears == horizonYears)&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.ideal, ideal) || other.ideal == ideal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,score,bonus,hitRate,benchmark,decisionDate,horizonYears,const DeepCollectionEquality().hash(_cards),ideal);

@override
String toString() {
  return 'Reveal(sessionId: $sessionId, score: $score, bonus: $bonus, hitRate: $hitRate, benchmark: $benchmark, decisionDate: $decisionDate, horizonYears: $horizonYears, cards: $cards, ideal: $ideal)';
}


}

/// @nodoc
abstract mixin class _$RevealCopyWith<$Res> implements $RevealCopyWith<$Res> {
  factory _$RevealCopyWith(_Reveal value, $Res Function(_Reveal) _then) = __$RevealCopyWithImpl;
@override @useResult
$Res call({
 int sessionId, double score, double bonus, double? hitRate, Benchmark benchmark, String decisionDate, int horizonYears, List<RevealCard> cards, Ideal ideal
});


@override $BenchmarkCopyWith<$Res> get benchmark;@override $IdealCopyWith<$Res> get ideal;

}
/// @nodoc
class __$RevealCopyWithImpl<$Res>
    implements _$RevealCopyWith<$Res> {
  __$RevealCopyWithImpl(this._self, this._then);

  final _Reveal _self;
  final $Res Function(_Reveal) _then;

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? score = null,Object? bonus = null,Object? hitRate = freezed,Object? benchmark = null,Object? decisionDate = null,Object? horizonYears = null,Object? cards = null,Object? ideal = null,}) {
  return _then(_Reveal(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as double,hitRate: freezed == hitRate ? _self.hitRate : hitRate // ignore: cast_nullable_to_non_nullable
as double?,benchmark: null == benchmark ? _self.benchmark : benchmark // ignore: cast_nullable_to_non_nullable
as Benchmark,decisionDate: null == decisionDate ? _self.decisionDate : decisionDate // ignore: cast_nullable_to_non_nullable
as String,horizonYears: null == horizonYears ? _self.horizonYears : horizonYears // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<RevealCard>,ideal: null == ideal ? _self.ideal : ideal // ignore: cast_nullable_to_non_nullable
as Ideal,
  ));
}

/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BenchmarkCopyWith<$Res> get benchmark {
  
  return $BenchmarkCopyWith<$Res>(_self.benchmark, (value) {
    return _then(_self.copyWith(benchmark: value));
  });
}/// Create a copy of Reveal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IdealCopyWith<$Res> get ideal {
  
  return $IdealCopyWith<$Res>(_self.ideal, (value) {
    return _then(_self.copyWith(ideal: value));
  });
}
}

// dart format on
