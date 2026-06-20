// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MacroBox {

 String get rateLevel;// 'lav' | 'nøytral' | 'høy'
 String get rateDirection;// 'stigende' | 'flat' | 'fallende'
 String get inflationBand; String get gdpBand; String get sectorSentiment;
/// Create a copy of MacroBox
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MacroBoxCopyWith<MacroBox> get copyWith => _$MacroBoxCopyWithImpl<MacroBox>(this as MacroBox, _$identity);

  /// Serializes this MacroBox to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MacroBox&&(identical(other.rateLevel, rateLevel) || other.rateLevel == rateLevel)&&(identical(other.rateDirection, rateDirection) || other.rateDirection == rateDirection)&&(identical(other.inflationBand, inflationBand) || other.inflationBand == inflationBand)&&(identical(other.gdpBand, gdpBand) || other.gdpBand == gdpBand)&&(identical(other.sectorSentiment, sectorSentiment) || other.sectorSentiment == sectorSentiment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rateLevel,rateDirection,inflationBand,gdpBand,sectorSentiment);

@override
String toString() {
  return 'MacroBox(rateLevel: $rateLevel, rateDirection: $rateDirection, inflationBand: $inflationBand, gdpBand: $gdpBand, sectorSentiment: $sectorSentiment)';
}


}

/// @nodoc
abstract mixin class $MacroBoxCopyWith<$Res>  {
  factory $MacroBoxCopyWith(MacroBox value, $Res Function(MacroBox) _then) = _$MacroBoxCopyWithImpl;
@useResult
$Res call({
 String rateLevel, String rateDirection, String inflationBand, String gdpBand, String sectorSentiment
});




}
/// @nodoc
class _$MacroBoxCopyWithImpl<$Res>
    implements $MacroBoxCopyWith<$Res> {
  _$MacroBoxCopyWithImpl(this._self, this._then);

  final MacroBox _self;
  final $Res Function(MacroBox) _then;

/// Create a copy of MacroBox
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rateLevel = null,Object? rateDirection = null,Object? inflationBand = null,Object? gdpBand = null,Object? sectorSentiment = null,}) {
  return _then(_self.copyWith(
rateLevel: null == rateLevel ? _self.rateLevel : rateLevel // ignore: cast_nullable_to_non_nullable
as String,rateDirection: null == rateDirection ? _self.rateDirection : rateDirection // ignore: cast_nullable_to_non_nullable
as String,inflationBand: null == inflationBand ? _self.inflationBand : inflationBand // ignore: cast_nullable_to_non_nullable
as String,gdpBand: null == gdpBand ? _self.gdpBand : gdpBand // ignore: cast_nullable_to_non_nullable
as String,sectorSentiment: null == sectorSentiment ? _self.sectorSentiment : sectorSentiment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MacroBox].
extension MacroBoxPatterns on MacroBox {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MacroBox value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MacroBox() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MacroBox value)  $default,){
final _that = this;
switch (_that) {
case _MacroBox():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MacroBox value)?  $default,){
final _that = this;
switch (_that) {
case _MacroBox() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rateLevel,  String rateDirection,  String inflationBand,  String gdpBand,  String sectorSentiment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MacroBox() when $default != null:
return $default(_that.rateLevel,_that.rateDirection,_that.inflationBand,_that.gdpBand,_that.sectorSentiment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rateLevel,  String rateDirection,  String inflationBand,  String gdpBand,  String sectorSentiment)  $default,) {final _that = this;
switch (_that) {
case _MacroBox():
return $default(_that.rateLevel,_that.rateDirection,_that.inflationBand,_that.gdpBand,_that.sectorSentiment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rateLevel,  String rateDirection,  String inflationBand,  String gdpBand,  String sectorSentiment)?  $default,) {final _that = this;
switch (_that) {
case _MacroBox() when $default != null:
return $default(_that.rateLevel,_that.rateDirection,_that.inflationBand,_that.gdpBand,_that.sectorSentiment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MacroBox implements MacroBox {
  const _MacroBox({required this.rateLevel, required this.rateDirection, required this.inflationBand, required this.gdpBand, required this.sectorSentiment});
  factory _MacroBox.fromJson(Map<String, dynamic> json) => _$MacroBoxFromJson(json);

@override final  String rateLevel;
// 'lav' | 'nøytral' | 'høy'
@override final  String rateDirection;
// 'stigende' | 'flat' | 'fallende'
@override final  String inflationBand;
@override final  String gdpBand;
@override final  String sectorSentiment;

/// Create a copy of MacroBox
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MacroBoxCopyWith<_MacroBox> get copyWith => __$MacroBoxCopyWithImpl<_MacroBox>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MacroBoxToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MacroBox&&(identical(other.rateLevel, rateLevel) || other.rateLevel == rateLevel)&&(identical(other.rateDirection, rateDirection) || other.rateDirection == rateDirection)&&(identical(other.inflationBand, inflationBand) || other.inflationBand == inflationBand)&&(identical(other.gdpBand, gdpBand) || other.gdpBand == gdpBand)&&(identical(other.sectorSentiment, sectorSentiment) || other.sectorSentiment == sectorSentiment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rateLevel,rateDirection,inflationBand,gdpBand,sectorSentiment);

@override
String toString() {
  return 'MacroBox(rateLevel: $rateLevel, rateDirection: $rateDirection, inflationBand: $inflationBand, gdpBand: $gdpBand, sectorSentiment: $sectorSentiment)';
}


}

/// @nodoc
abstract mixin class _$MacroBoxCopyWith<$Res> implements $MacroBoxCopyWith<$Res> {
  factory _$MacroBoxCopyWith(_MacroBox value, $Res Function(_MacroBox) _then) = __$MacroBoxCopyWithImpl;
@override @useResult
$Res call({
 String rateLevel, String rateDirection, String inflationBand, String gdpBand, String sectorSentiment
});




}
/// @nodoc
class __$MacroBoxCopyWithImpl<$Res>
    implements _$MacroBoxCopyWith<$Res> {
  __$MacroBoxCopyWithImpl(this._self, this._then);

  final _MacroBox _self;
  final $Res Function(_MacroBox) _then;

/// Create a copy of MacroBox
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rateLevel = null,Object? rateDirection = null,Object? inflationBand = null,Object? gdpBand = null,Object? sectorSentiment = null,}) {
  return _then(_MacroBox(
rateLevel: null == rateLevel ? _self.rateLevel : rateLevel // ignore: cast_nullable_to_non_nullable
as String,rateDirection: null == rateDirection ? _self.rateDirection : rateDirection // ignore: cast_nullable_to_non_nullable
as String,inflationBand: null == inflationBand ? _self.inflationBand : inflationBand // ignore: cast_nullable_to_non_nullable
as String,gdpBand: null == gdpBand ? _self.gdpBand : gdpBand // ignore: cast_nullable_to_non_nullable
as String,sectorSentiment: null == sectorSentiment ? _self.sectorSentiment : sectorSentiment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Fundamentals {

 double? get pe;// null when EPS is negative -> shown as "neg." (04 §5.2)
 double get ps; double get debtToEquity; double get grossMargin; double get operatingMargin; double get netMargin; double get roic;
/// Create a copy of Fundamentals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundamentalsCopyWith<Fundamentals> get copyWith => _$FundamentalsCopyWithImpl<Fundamentals>(this as Fundamentals, _$identity);

  /// Serializes this Fundamentals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Fundamentals&&(identical(other.pe, pe) || other.pe == pe)&&(identical(other.ps, ps) || other.ps == ps)&&(identical(other.debtToEquity, debtToEquity) || other.debtToEquity == debtToEquity)&&(identical(other.grossMargin, grossMargin) || other.grossMargin == grossMargin)&&(identical(other.operatingMargin, operatingMargin) || other.operatingMargin == operatingMargin)&&(identical(other.netMargin, netMargin) || other.netMargin == netMargin)&&(identical(other.roic, roic) || other.roic == roic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pe,ps,debtToEquity,grossMargin,operatingMargin,netMargin,roic);

@override
String toString() {
  return 'Fundamentals(pe: $pe, ps: $ps, debtToEquity: $debtToEquity, grossMargin: $grossMargin, operatingMargin: $operatingMargin, netMargin: $netMargin, roic: $roic)';
}


}

/// @nodoc
abstract mixin class $FundamentalsCopyWith<$Res>  {
  factory $FundamentalsCopyWith(Fundamentals value, $Res Function(Fundamentals) _then) = _$FundamentalsCopyWithImpl;
@useResult
$Res call({
 double? pe, double ps, double debtToEquity, double grossMargin, double operatingMargin, double netMargin, double roic
});




}
/// @nodoc
class _$FundamentalsCopyWithImpl<$Res>
    implements $FundamentalsCopyWith<$Res> {
  _$FundamentalsCopyWithImpl(this._self, this._then);

  final Fundamentals _self;
  final $Res Function(Fundamentals) _then;

/// Create a copy of Fundamentals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pe = freezed,Object? ps = null,Object? debtToEquity = null,Object? grossMargin = null,Object? operatingMargin = null,Object? netMargin = null,Object? roic = null,}) {
  return _then(_self.copyWith(
pe: freezed == pe ? _self.pe : pe // ignore: cast_nullable_to_non_nullable
as double?,ps: null == ps ? _self.ps : ps // ignore: cast_nullable_to_non_nullable
as double,debtToEquity: null == debtToEquity ? _self.debtToEquity : debtToEquity // ignore: cast_nullable_to_non_nullable
as double,grossMargin: null == grossMargin ? _self.grossMargin : grossMargin // ignore: cast_nullable_to_non_nullable
as double,operatingMargin: null == operatingMargin ? _self.operatingMargin : operatingMargin // ignore: cast_nullable_to_non_nullable
as double,netMargin: null == netMargin ? _self.netMargin : netMargin // ignore: cast_nullable_to_non_nullable
as double,roic: null == roic ? _self.roic : roic // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Fundamentals].
extension FundamentalsPatterns on Fundamentals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Fundamentals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Fundamentals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Fundamentals value)  $default,){
final _that = this;
switch (_that) {
case _Fundamentals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Fundamentals value)?  $default,){
final _that = this;
switch (_that) {
case _Fundamentals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? pe,  double ps,  double debtToEquity,  double grossMargin,  double operatingMargin,  double netMargin,  double roic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Fundamentals() when $default != null:
return $default(_that.pe,_that.ps,_that.debtToEquity,_that.grossMargin,_that.operatingMargin,_that.netMargin,_that.roic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? pe,  double ps,  double debtToEquity,  double grossMargin,  double operatingMargin,  double netMargin,  double roic)  $default,) {final _that = this;
switch (_that) {
case _Fundamentals():
return $default(_that.pe,_that.ps,_that.debtToEquity,_that.grossMargin,_that.operatingMargin,_that.netMargin,_that.roic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? pe,  double ps,  double debtToEquity,  double grossMargin,  double operatingMargin,  double netMargin,  double roic)?  $default,) {final _that = this;
switch (_that) {
case _Fundamentals() when $default != null:
return $default(_that.pe,_that.ps,_that.debtToEquity,_that.grossMargin,_that.operatingMargin,_that.netMargin,_that.roic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Fundamentals implements Fundamentals {
  const _Fundamentals({this.pe, required this.ps, required this.debtToEquity, required this.grossMargin, required this.operatingMargin, required this.netMargin, required this.roic});
  factory _Fundamentals.fromJson(Map<String, dynamic> json) => _$FundamentalsFromJson(json);

@override final  double? pe;
// null when EPS is negative -> shown as "neg." (04 §5.2)
@override final  double ps;
@override final  double debtToEquity;
@override final  double grossMargin;
@override final  double operatingMargin;
@override final  double netMargin;
@override final  double roic;

/// Create a copy of Fundamentals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundamentalsCopyWith<_Fundamentals> get copyWith => __$FundamentalsCopyWithImpl<_Fundamentals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundamentalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Fundamentals&&(identical(other.pe, pe) || other.pe == pe)&&(identical(other.ps, ps) || other.ps == ps)&&(identical(other.debtToEquity, debtToEquity) || other.debtToEquity == debtToEquity)&&(identical(other.grossMargin, grossMargin) || other.grossMargin == grossMargin)&&(identical(other.operatingMargin, operatingMargin) || other.operatingMargin == operatingMargin)&&(identical(other.netMargin, netMargin) || other.netMargin == netMargin)&&(identical(other.roic, roic) || other.roic == roic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pe,ps,debtToEquity,grossMargin,operatingMargin,netMargin,roic);

@override
String toString() {
  return 'Fundamentals(pe: $pe, ps: $ps, debtToEquity: $debtToEquity, grossMargin: $grossMargin, operatingMargin: $operatingMargin, netMargin: $netMargin, roic: $roic)';
}


}

/// @nodoc
abstract mixin class _$FundamentalsCopyWith<$Res> implements $FundamentalsCopyWith<$Res> {
  factory _$FundamentalsCopyWith(_Fundamentals value, $Res Function(_Fundamentals) _then) = __$FundamentalsCopyWithImpl;
@override @useResult
$Res call({
 double? pe, double ps, double debtToEquity, double grossMargin, double operatingMargin, double netMargin, double roic
});




}
/// @nodoc
class __$FundamentalsCopyWithImpl<$Res>
    implements _$FundamentalsCopyWith<$Res> {
  __$FundamentalsCopyWithImpl(this._self, this._then);

  final _Fundamentals _self;
  final $Res Function(_Fundamentals) _then;

/// Create a copy of Fundamentals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pe = freezed,Object? ps = null,Object? debtToEquity = null,Object? grossMargin = null,Object? operatingMargin = null,Object? netMargin = null,Object? roic = null,}) {
  return _then(_Fundamentals(
pe: freezed == pe ? _self.pe : pe // ignore: cast_nullable_to_non_nullable
as double?,ps: null == ps ? _self.ps : ps // ignore: cast_nullable_to_non_nullable
as double,debtToEquity: null == debtToEquity ? _self.debtToEquity : debtToEquity // ignore: cast_nullable_to_non_nullable
as double,grossMargin: null == grossMargin ? _self.grossMargin : grossMargin // ignore: cast_nullable_to_non_nullable
as double,operatingMargin: null == operatingMargin ? _self.operatingMargin : operatingMargin // ignore: cast_nullable_to_non_nullable
as double,netMargin: null == netMargin ? _self.netMargin : netMargin // ignore: cast_nullable_to_non_nullable
as double,roic: null == roic ? _self.roic : roic // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Growth {

// Explicit keys: snake-casing a digit-suffixed name would drop the '_'.
@JsonKey(name: 'rev_cagr_3y') double get revCagr3y;@JsonKey(name: 'eps_cagr_3y') double get epsCagr3y;
/// Create a copy of Growth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrowthCopyWith<Growth> get copyWith => _$GrowthCopyWithImpl<Growth>(this as Growth, _$identity);

  /// Serializes this Growth to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Growth&&(identical(other.revCagr3y, revCagr3y) || other.revCagr3y == revCagr3y)&&(identical(other.epsCagr3y, epsCagr3y) || other.epsCagr3y == epsCagr3y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revCagr3y,epsCagr3y);

@override
String toString() {
  return 'Growth(revCagr3y: $revCagr3y, epsCagr3y: $epsCagr3y)';
}


}

/// @nodoc
abstract mixin class $GrowthCopyWith<$Res>  {
  factory $GrowthCopyWith(Growth value, $Res Function(Growth) _then) = _$GrowthCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'rev_cagr_3y') double revCagr3y,@JsonKey(name: 'eps_cagr_3y') double epsCagr3y
});




}
/// @nodoc
class _$GrowthCopyWithImpl<$Res>
    implements $GrowthCopyWith<$Res> {
  _$GrowthCopyWithImpl(this._self, this._then);

  final Growth _self;
  final $Res Function(Growth) _then;

/// Create a copy of Growth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revCagr3y = null,Object? epsCagr3y = null,}) {
  return _then(_self.copyWith(
revCagr3y: null == revCagr3y ? _self.revCagr3y : revCagr3y // ignore: cast_nullable_to_non_nullable
as double,epsCagr3y: null == epsCagr3y ? _self.epsCagr3y : epsCagr3y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Growth].
extension GrowthPatterns on Growth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Growth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Growth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Growth value)  $default,){
final _that = this;
switch (_that) {
case _Growth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Growth value)?  $default,){
final _that = this;
switch (_that) {
case _Growth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'rev_cagr_3y')  double revCagr3y, @JsonKey(name: 'eps_cagr_3y')  double epsCagr3y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Growth() when $default != null:
return $default(_that.revCagr3y,_that.epsCagr3y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'rev_cagr_3y')  double revCagr3y, @JsonKey(name: 'eps_cagr_3y')  double epsCagr3y)  $default,) {final _that = this;
switch (_that) {
case _Growth():
return $default(_that.revCagr3y,_that.epsCagr3y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'rev_cagr_3y')  double revCagr3y, @JsonKey(name: 'eps_cagr_3y')  double epsCagr3y)?  $default,) {final _that = this;
switch (_that) {
case _Growth() when $default != null:
return $default(_that.revCagr3y,_that.epsCagr3y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Growth implements Growth {
  const _Growth({@JsonKey(name: 'rev_cagr_3y') required this.revCagr3y, @JsonKey(name: 'eps_cagr_3y') required this.epsCagr3y});
  factory _Growth.fromJson(Map<String, dynamic> json) => _$GrowthFromJson(json);

// Explicit keys: snake-casing a digit-suffixed name would drop the '_'.
@override@JsonKey(name: 'rev_cagr_3y') final  double revCagr3y;
@override@JsonKey(name: 'eps_cagr_3y') final  double epsCagr3y;

/// Create a copy of Growth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrowthCopyWith<_Growth> get copyWith => __$GrowthCopyWithImpl<_Growth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrowthToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Growth&&(identical(other.revCagr3y, revCagr3y) || other.revCagr3y == revCagr3y)&&(identical(other.epsCagr3y, epsCagr3y) || other.epsCagr3y == epsCagr3y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revCagr3y,epsCagr3y);

@override
String toString() {
  return 'Growth(revCagr3y: $revCagr3y, epsCagr3y: $epsCagr3y)';
}


}

/// @nodoc
abstract mixin class _$GrowthCopyWith<$Res> implements $GrowthCopyWith<$Res> {
  factory _$GrowthCopyWith(_Growth value, $Res Function(_Growth) _then) = __$GrowthCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'rev_cagr_3y') double revCagr3y,@JsonKey(name: 'eps_cagr_3y') double epsCagr3y
});




}
/// @nodoc
class __$GrowthCopyWithImpl<$Res>
    implements _$GrowthCopyWith<$Res> {
  __$GrowthCopyWithImpl(this._self, this._then);

  final _Growth _self;
  final $Res Function(_Growth) _then;

/// Create a copy of Growth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revCagr3y = null,Object? epsCagr3y = null,}) {
  return _then(_Growth(
revCagr3y: null == revCagr3y ? _self.revCagr3y : revCagr3y // ignore: cast_nullable_to_non_nullable
as double,epsCagr3y: null == epsCagr3y ? _self.epsCagr3y : epsCagr3y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$CardPayload {

 MacroBox get macro; Fundamentals get fundamentals; Growth get growth; String get cap;// 'small' | 'mid' | 'large'
 String get sectorCoarse; String get narrative;
/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardPayloadCopyWith<CardPayload> get copyWith => _$CardPayloadCopyWithImpl<CardPayload>(this as CardPayload, _$identity);

  /// Serializes this CardPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardPayload&&(identical(other.macro, macro) || other.macro == macro)&&(identical(other.fundamentals, fundamentals) || other.fundamentals == fundamentals)&&(identical(other.growth, growth) || other.growth == growth)&&(identical(other.cap, cap) || other.cap == cap)&&(identical(other.sectorCoarse, sectorCoarse) || other.sectorCoarse == sectorCoarse)&&(identical(other.narrative, narrative) || other.narrative == narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,macro,fundamentals,growth,cap,sectorCoarse,narrative);

@override
String toString() {
  return 'CardPayload(macro: $macro, fundamentals: $fundamentals, growth: $growth, cap: $cap, sectorCoarse: $sectorCoarse, narrative: $narrative)';
}


}

/// @nodoc
abstract mixin class $CardPayloadCopyWith<$Res>  {
  factory $CardPayloadCopyWith(CardPayload value, $Res Function(CardPayload) _then) = _$CardPayloadCopyWithImpl;
@useResult
$Res call({
 MacroBox macro, Fundamentals fundamentals, Growth growth, String cap, String sectorCoarse, String narrative
});


$MacroBoxCopyWith<$Res> get macro;$FundamentalsCopyWith<$Res> get fundamentals;$GrowthCopyWith<$Res> get growth;

}
/// @nodoc
class _$CardPayloadCopyWithImpl<$Res>
    implements $CardPayloadCopyWith<$Res> {
  _$CardPayloadCopyWithImpl(this._self, this._then);

  final CardPayload _self;
  final $Res Function(CardPayload) _then;

/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? macro = null,Object? fundamentals = null,Object? growth = null,Object? cap = null,Object? sectorCoarse = null,Object? narrative = null,}) {
  return _then(_self.copyWith(
macro: null == macro ? _self.macro : macro // ignore: cast_nullable_to_non_nullable
as MacroBox,fundamentals: null == fundamentals ? _self.fundamentals : fundamentals // ignore: cast_nullable_to_non_nullable
as Fundamentals,growth: null == growth ? _self.growth : growth // ignore: cast_nullable_to_non_nullable
as Growth,cap: null == cap ? _self.cap : cap // ignore: cast_nullable_to_non_nullable
as String,sectorCoarse: null == sectorCoarse ? _self.sectorCoarse : sectorCoarse // ignore: cast_nullable_to_non_nullable
as String,narrative: null == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacroBoxCopyWith<$Res> get macro {
  
  return $MacroBoxCopyWith<$Res>(_self.macro, (value) {
    return _then(_self.copyWith(macro: value));
  });
}/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundamentalsCopyWith<$Res> get fundamentals {
  
  return $FundamentalsCopyWith<$Res>(_self.fundamentals, (value) {
    return _then(_self.copyWith(fundamentals: value));
  });
}/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrowthCopyWith<$Res> get growth {
  
  return $GrowthCopyWith<$Res>(_self.growth, (value) {
    return _then(_self.copyWith(growth: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardPayload].
extension CardPayloadPatterns on CardPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardPayload value)  $default,){
final _that = this;
switch (_that) {
case _CardPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardPayload value)?  $default,){
final _that = this;
switch (_that) {
case _CardPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MacroBox macro,  Fundamentals fundamentals,  Growth growth,  String cap,  String sectorCoarse,  String narrative)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardPayload() when $default != null:
return $default(_that.macro,_that.fundamentals,_that.growth,_that.cap,_that.sectorCoarse,_that.narrative);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MacroBox macro,  Fundamentals fundamentals,  Growth growth,  String cap,  String sectorCoarse,  String narrative)  $default,) {final _that = this;
switch (_that) {
case _CardPayload():
return $default(_that.macro,_that.fundamentals,_that.growth,_that.cap,_that.sectorCoarse,_that.narrative);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MacroBox macro,  Fundamentals fundamentals,  Growth growth,  String cap,  String sectorCoarse,  String narrative)?  $default,) {final _that = this;
switch (_that) {
case _CardPayload() when $default != null:
return $default(_that.macro,_that.fundamentals,_that.growth,_that.cap,_that.sectorCoarse,_that.narrative);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardPayload implements CardPayload {
  const _CardPayload({required this.macro, required this.fundamentals, required this.growth, required this.cap, required this.sectorCoarse, required this.narrative});
  factory _CardPayload.fromJson(Map<String, dynamic> json) => _$CardPayloadFromJson(json);

@override final  MacroBox macro;
@override final  Fundamentals fundamentals;
@override final  Growth growth;
@override final  String cap;
// 'small' | 'mid' | 'large'
@override final  String sectorCoarse;
@override final  String narrative;

/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardPayloadCopyWith<_CardPayload> get copyWith => __$CardPayloadCopyWithImpl<_CardPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardPayload&&(identical(other.macro, macro) || other.macro == macro)&&(identical(other.fundamentals, fundamentals) || other.fundamentals == fundamentals)&&(identical(other.growth, growth) || other.growth == growth)&&(identical(other.cap, cap) || other.cap == cap)&&(identical(other.sectorCoarse, sectorCoarse) || other.sectorCoarse == sectorCoarse)&&(identical(other.narrative, narrative) || other.narrative == narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,macro,fundamentals,growth,cap,sectorCoarse,narrative);

@override
String toString() {
  return 'CardPayload(macro: $macro, fundamentals: $fundamentals, growth: $growth, cap: $cap, sectorCoarse: $sectorCoarse, narrative: $narrative)';
}


}

/// @nodoc
abstract mixin class _$CardPayloadCopyWith<$Res> implements $CardPayloadCopyWith<$Res> {
  factory _$CardPayloadCopyWith(_CardPayload value, $Res Function(_CardPayload) _then) = __$CardPayloadCopyWithImpl;
@override @useResult
$Res call({
 MacroBox macro, Fundamentals fundamentals, Growth growth, String cap, String sectorCoarse, String narrative
});


@override $MacroBoxCopyWith<$Res> get macro;@override $FundamentalsCopyWith<$Res> get fundamentals;@override $GrowthCopyWith<$Res> get growth;

}
/// @nodoc
class __$CardPayloadCopyWithImpl<$Res>
    implements _$CardPayloadCopyWith<$Res> {
  __$CardPayloadCopyWithImpl(this._self, this._then);

  final _CardPayload _self;
  final $Res Function(_CardPayload) _then;

/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? macro = null,Object? fundamentals = null,Object? growth = null,Object? cap = null,Object? sectorCoarse = null,Object? narrative = null,}) {
  return _then(_CardPayload(
macro: null == macro ? _self.macro : macro // ignore: cast_nullable_to_non_nullable
as MacroBox,fundamentals: null == fundamentals ? _self.fundamentals : fundamentals // ignore: cast_nullable_to_non_nullable
as Fundamentals,growth: null == growth ? _self.growth : growth // ignore: cast_nullable_to_non_nullable
as Growth,cap: null == cap ? _self.cap : cap // ignore: cast_nullable_to_non_nullable
as String,sectorCoarse: null == sectorCoarse ? _self.sectorCoarse : sectorCoarse // ignore: cast_nullable_to_non_nullable
as String,narrative: null == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacroBoxCopyWith<$Res> get macro {
  
  return $MacroBoxCopyWith<$Res>(_self.macro, (value) {
    return _then(_self.copyWith(macro: value));
  });
}/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundamentalsCopyWith<$Res> get fundamentals {
  
  return $FundamentalsCopyWith<$Res>(_self.fundamentals, (value) {
    return _then(_self.copyWith(fundamentals: value));
  });
}/// Create a copy of CardPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrowthCopyWith<$Res> get growth {
  
  return $GrowthCopyWith<$Res>(_self.growth, (value) {
    return _then(_self.copyWith(growth: value));
  });
}
}


/// @nodoc
mixin _$GameCard {

 int get cardNo; CardPayload get payload;
/// Create a copy of GameCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameCardCopyWith<GameCard> get copyWith => _$GameCardCopyWithImpl<GameCard>(this as GameCard, _$identity);

  /// Serializes this GameCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameCard&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.payload, payload) || other.payload == payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardNo,payload);

@override
String toString() {
  return 'GameCard(cardNo: $cardNo, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $GameCardCopyWith<$Res>  {
  factory $GameCardCopyWith(GameCard value, $Res Function(GameCard) _then) = _$GameCardCopyWithImpl;
@useResult
$Res call({
 int cardNo, CardPayload payload
});


$CardPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$GameCardCopyWithImpl<$Res>
    implements $GameCardCopyWith<$Res> {
  _$GameCardCopyWithImpl(this._self, this._then);

  final GameCard _self;
  final $Res Function(GameCard) _then;

/// Create a copy of GameCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardNo = null,Object? payload = null,}) {
  return _then(_self.copyWith(
cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as CardPayload,
  ));
}
/// Create a copy of GameCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardPayloadCopyWith<$Res> get payload {
  
  return $CardPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameCard].
extension GameCardPatterns on GameCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameCard value)  $default,){
final _that = this;
switch (_that) {
case _GameCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameCard value)?  $default,){
final _that = this;
switch (_that) {
case _GameCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cardNo,  CardPayload payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameCard() when $default != null:
return $default(_that.cardNo,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cardNo,  CardPayload payload)  $default,) {final _that = this;
switch (_that) {
case _GameCard():
return $default(_that.cardNo,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cardNo,  CardPayload payload)?  $default,) {final _that = this;
switch (_that) {
case _GameCard() when $default != null:
return $default(_that.cardNo,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameCard implements GameCard {
  const _GameCard({required this.cardNo, required this.payload});
  factory _GameCard.fromJson(Map<String, dynamic> json) => _$GameCardFromJson(json);

@override final  int cardNo;
@override final  CardPayload payload;

/// Create a copy of GameCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameCardCopyWith<_GameCard> get copyWith => __$GameCardCopyWithImpl<_GameCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameCard&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.payload, payload) || other.payload == payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cardNo,payload);

@override
String toString() {
  return 'GameCard(cardNo: $cardNo, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$GameCardCopyWith<$Res> implements $GameCardCopyWith<$Res> {
  factory _$GameCardCopyWith(_GameCard value, $Res Function(_GameCard) _then) = __$GameCardCopyWithImpl;
@override @useResult
$Res call({
 int cardNo, CardPayload payload
});


@override $CardPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class __$GameCardCopyWithImpl<$Res>
    implements _$GameCardCopyWith<$Res> {
  __$GameCardCopyWithImpl(this._self, this._then);

  final _GameCard _self;
  final $Res Function(_GameCard) _then;

/// Create a copy of GameCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardNo = null,Object? payload = null,}) {
  return _then(_GameCard(
cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as CardPayload,
  ));
}

/// Create a copy of GameCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardPayloadCopyWith<$Res> get payload {
  
  return $CardPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

// dart format on
