import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'internal/logger.dart';
import 'redux_property_notifier.dart';
import 'redux_store.dart';
import 'store_provider.dart';

/// StateからWidgetを構築する.
typedef ReduxStreamWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T snapshot,
);

/// StateからWidgetを構築する.
typedef ReduxStreamWidgetBuilderWithState<TState extends ReduxState, T> = Widget
    Function(
  BuildContext context,
  TState state,
  T snapshot,
);

/// Stateから特定値を取得する.
typedef StatePropertySelector<TState extends ReduxState, T> = T Function(
    TState state);

/// ReduxStoreの特定Propertyを表示するWidget.
///
/// [selector] が返した<T>を [builder] コールバックにわたす。
/// このとき、リビルドが最小限になるように [equals] がチェックを行う.
///
/// ポリシーとして、Equalなプロパティに対してBuildされる結果は同一である.
/// そのため、<T>の値が同一である場合、リビルドが走らないように制御を行う.
class StateProperty<TState extends ReduxState, T> extends StatefulWidget {
  final ReduxStore<TState>? store;

  final StatePropertySelector<TState, T> selector;

  /// 変動したプロパティにのみ着目してビルドを行う場合のBuilder関数
  final ReduxStreamWidgetBuilder<T>? builder;

  /// 変動したプロパティ及び、変動した時点のStateに基づいてビルドを行う場合のBuilder関数.
  final ReduxStreamWidgetBuilderWithState<TState, T>? builderWithState;

  /// 同一性チェック関数.
  /// 指定しない場合、 [ReduxPropertyNotifier.propertyEquals] 関数が使用される.
  final bool Function(T a, T b)? equals;

  StateProperty({
    this.store,
    Key? key,
    required this.selector,
    this.equals,
    this.builder,
    this.builderWithState,
  }) : super(key: key) {
    final assertBuilderNum =
        (builder != null ? 1 : 0) + (builderWithState != null ? 1 : 0);
    assert(
      assertBuilderNum == 1,
      'Invalid [builder | builderWithState]',
    );
  }

  @override
  State createState() => _StatePropertyState<TState, T>();
}

class _StatePropertyState<TState extends ReduxState, T>
    extends State<StateProperty<TState, T>> {
  StreamSubscription? subscribe;

  /// ビルド対象のProperty.
  /// Stream.distinct()相当を行いたいが、
  /// StreamBuilderでは同一値が2回発火してしまうため、Widget側でハンドリングを行う.
  late T lastBuildProperty;

  /// 最後にPropertyが変動した際のState.
  /// 現在Stateではなく、あくまで「最後に該当Propertyが変更された際の」Stateである点に留意する.
  late TState lastBuildState;

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(context, lastBuildProperty);
    } else if (widget.builderWithState != null) {
      return widget.builderWithState!(
        context,
        lastBuildState,
        lastBuildProperty,
      );
    }
    throw Exception('Invalid Builder');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = widget.store ?? StoreProvider.of(context);
    lastBuildState = store.state;
    lastBuildProperty = select(lastBuildState);
    subscribe ??= store.renderStream.listen(_listenState);
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
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        logError('fail: ${widget.selector}', e, stackTrace);
      }
      return lastBuildProperty;
    }
  }

  /// 現在のStateを受け取り、Selectorを通し、
  /// 必要であればリビルドを行わせる
  void _listenState(TState state) {
    final newProperty = select(state);
    if (!equals(newProperty, lastBuildProperty)) {
      setState(() {
        lastBuildProperty = newProperty;
        lastBuildState = state;
      });
    }
  }
}
