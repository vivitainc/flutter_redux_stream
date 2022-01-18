import 'dart:async';

import 'package:flutter/material.dart';

import 'redux_property_notifier.dart';
import 'redux_store.dart';
import 'state_property.dart';
import 'store_provider.dart';

/// ReduxStoreの値を [selector] で選択し、 [listen] で処理を行う.
/// Widgetツリーから破棄されたタイミングでStreamは無効になる.
class StatePropertyNotify<TState extends ReduxState, T> extends StatefulWidget {
  final ReduxStore<TState>? store;

  final StatePropertySelector<TState, T> selector;

  /// 同期的にストリームを処理するListener
  final void Function(
    BuildContext buildContext,
    T value,
  )? listen;

  /// 同一性チェック関数.
  /// 指定しない場合、 [ReduxPropertyNotifier.propertyEquals] 関数が使用される.
  final bool Function(T a, T b)? equals;

  final Widget child;

  const StatePropertyNotify({
    Key? key,
    this.store,
    required this.selector,
    this.listen,
    this.equals,
    required this.child,
  }) : super(key: key);

  @override
  _StatePropertyNotifyState createState() =>
      _StatePropertyNotifyState<TState, T>();
}

class _StatePropertyNotifyState<TState extends ReduxState, T>
    extends State<StatePropertyNotify<TState, T>> {
  StreamSubscription? subscribe;

  /// 受信回数
  int notifyCount = 0;

  /// ビルド対象のProperty.
  /// Stream.distinct()相当を行いたいが、
  /// StreamBuilderでは同一値が2回発火してしまうため、Widget側でハンドリングを行う.
  late T lastProperty;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = widget.store ?? StoreProvider.of(context);
    subscribe ??= store.stateStream.listen(_listenState);
  }

  @override
  void dispose() {
    subscribe?.cancel();
    super.dispose();
  }

  /// 値の同一性チェックを行う
  bool equals(T a, T b) {
    return (widget.equals ?? ReduxPropertyNotifier.propertyEquals)(a, b);
  }

  T select(TState state) {
    try {
      return widget.selector(state);
    } on Exception catch (_) {
      return lastProperty;
    }
  }

  /// 現在のStateを受け取り、Selectorを通し、
  /// 必要であればリビルドを行わせる
  void _listenState(TState state) {
    final newProperty = select(state);
    if (notifyCount == 0 || !equals(newProperty, lastProperty)) {
      lastProperty = newProperty;
      ++notifyCount;

      final listen = widget.listen;
      if (listen != null) {
        listen(context, newProperty);
      }
    }
  }
}
