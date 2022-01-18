import 'package:flutter/material.dart';
import 'package:stdlib_plus/stdlib_plus.dart';

/// Reduxで参照カウンタを実現するためのUtil
///
/// 誤った代入をコンパイラレベルで防ぐため、Generics型を与えている.
@immutable
class ReferenceCount<T> {
  final int _value;

  const ReferenceCount._(this._value);

  /// どこからも参照されていない参照カウンタを生成する.
  const ReferenceCount.zero() : this._(0);

  /// 参照カウンタを1減らしたインスタンスを生成する.
  ReferenceCount<T> release() {
    check(_value > 0, () => 'Invalid reference count');

    return ReferenceCount._(_value - 1);
  }

  /// 参照カウンタを1増やしたインスタンスを生成する.
  ReferenceCount<T> addRef() {
    return ReferenceCount._(_value + 1);
  }

  /// 参照カウンタが1以上になったらtrue.
  bool isCreated({required ReferenceCount<T> oldValue}) {
    return _value > 0 && oldValue._value == 0;
  }

  /// 参照が0になり、対象オブジェクトの破棄が可能になったらtrue
  bool isDisposed({required ReferenceCount<T> oldValue}) {
    return _value == 0 && oldValue._value > 0;
  }

  /// カウンタが0であればtrue.
  bool get isEmpty => _value == 0;

  /// カウンタが0でなければtrue.
  bool get isNotEmpty => _value > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ReferenceCount && other._value == _value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'ReferenceCount($_value)';
}
