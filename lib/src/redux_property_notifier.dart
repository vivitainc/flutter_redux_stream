import 'package:flutter/foundation.dart';
import 'package:stdlib_plus/stdlib_plus.dart';

import 'middleware/notify_redux_property_middleware.dart';
import 'redux_store.dart';

/// ReduxStateの特定プロパティが変更された際のハンドリングを行う.
class ReduxPropertyNotifier<TState extends ReduxState, T>
    implements Disposable {
  /// 最後に受け取ったState
  TState? _latestState;

  /// 最後に受け取ったプロパティ
  T? _latestProperty;

  /// Stateを受け取り、Propertyを選択して返却する
  final T? Function(TState state) selector;

  /// プロパティがnullから!= nullへ変化した.
  ///
  /// [_onPropertyCreated] -> [_onPropertyChangedWithState] の順にコールされる.
  final void Function(TState newState, T newProperty)? _onPropertyCreated;

  /// プロパティが変化した.際にコールバックされる.
  ///
  /// oldStateがnullの場合（初回）でもコールが行われる.
  final void Function(
    TState? oldState,
    T? oldProperty,
    TState newState,
    T? newProperty,
  )? _onPropertyChangedWithState;

  /// プロパティが変化した.際にコールバックされる.
  ///
  /// oldStateがnullの場合（初回）でもコールが行われる.
  final void Function(
    T? oldProperty,
    T? newProperty,
  )? _onPropertyChanged;

  /// プロパティが != nullから nullへ変化した.
  ///
  /// [_onPropertyChangedWithState] -> [_onPropertyCleared] の順にコールされる.
  final void Function(TState newState)? _onPropertyCleared;

  /// 同一性テスト.
  /// 標準では [ReduxPropertyNotifier.propertyEquals] 関数が使用される.
  final bool Function(T? a, T? b) equals;

  /// onDispose.
  final Function(TState state, T? property)? _onDispose;

  ReduxPropertyNotifier({
    required this.selector,

    /// カスタムEquals指定
    bool Function(T? a, T? b)? equals,

    /// プロパティ作成コールバック
    void Function(TState newState, T newProperty)? onPropertyCreated,

    /// State付きプロパティ変更通知コールバック
    void Function(
            TState? oldState, T? oldProperty, TState newState, T? newProperty)?
        onPropertyChangedWithState,

    /// プロパティ変更コールバック
    void Function(T? oldProperty, T? newProperty)? onPropertyChanged,

    /// プロパティ作成コールバック
    void Function(TState newState)? onPropertyCleared,

    /// 解放コールバック
    void Function(TState state, T? property)? onDispose,
  })  : equals = equals ?? ReduxPropertyNotifier.propertyEquals,
        _onPropertyCreated = onPropertyCreated,
        _onPropertyChangedWithState = onPropertyChangedWithState,
        _onPropertyChanged = onPropertyChanged,
        _onPropertyCleared = onPropertyCleared,
        _onDispose = onDispose;

  /// プロパティの更新ハンドリングを行う.
  void onStateChanged(TState newState) {
    final oldState = _latestState;
    final oldProperty = _latestProperty;

    final newProperty = newState.select(selector);
    _latestState = newState;
    _latestProperty = newProperty;

    if (oldProperty == null && newProperty != null) {
      _onPropertyCreated?.call(newState, newProperty);
    }
    if (!equals(oldProperty, newProperty)) {
      // 値が更新された
      _onPropertyChangedWithState?.call(
          oldState, oldProperty, newState, newProperty);
      _onPropertyChanged?.call(oldProperty, newProperty);
    }
    if (oldProperty != null && newProperty == null) {
      _onPropertyCleared?.call(newState);
    }
  }

  /// ReduxStateのequals標準実装.
  /// 可能な限り自動的に型をチェックし、その型にあった標準的なequalsでチェックを行う.
  static bool propertyEquals<T>(T? a, T? b) {
    if (identical(a, b)) {
      return true;
    } else if (a != null && b == null) {
      return false;
    } else if (b != null && a == null) {
      return false;
    } else if (a is List && b is List) {
      return listEquals<dynamic>(a, b);
    } else if (a is Set && b is Set) {
      return setEquals<dynamic>(a, b);
    } else if (a is Map && b is Map) {
      return mapEquals<dynamic, dynamic>(a, b);
    } else {
      return a == b;
    }
  }

  @override
  void dispose() {
    _onDispose?.call(_latestState!, _latestProperty);
  }
}

extension ReduxPropertyNotifierExtension<TState extends ReduxState>
    on ReduxStore<TState> {
  /// Notifierを [ReduxStore] へ登録する
  void addNotifier<T>(ReduxPropertyNotifier<TState, T> notifier) {
    final mw = middleware<NotifyReduxPropertyMiddleware<TState, T>>();
    mw.addNotifier(notifier);
  }

  /// Notifierを [ReduxStore] から削除する
  void removeNotifier<T>(ReduxPropertyNotifier<TState, T> notifier) {
    final mw = middleware<NotifyReduxPropertyMiddleware<TState, T>>();
    mw.removeNotifier(notifier);
  }
}
