import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../redux_plugin.dart';
import '../redux_store.dart';
import 'multi_source_redux_action.dart';
import 'multi_source_redux_property_buffer_mixin.dart';

/// [MultiSourceReduxPropertyBufferMixin] および [MultiSourceReduxPropertyBufferMixin] を
/// 簡潔に扱えるようにラップするPlugin.
class MultiSourceBufferPlugin<TState extends ReduxState>
    extends ReduxPlugin<TState>
    with MultiSourceReduxPropertyBufferMixin<TState> {
  @protected
  ReduxStore<TState>? store;

  final _subscription = CompositeSubscription();

  /// Streamからデータを受け取り、Storeへとマージする.
  /// StreamはReduxStoreのライフサイクル終了時に自動的に解放される.
  StreamSubscription<T> addStreamSource<T>(
    Stream<T> source,
    TState Function(TState state, T value) merge, {
    bool forceMerge = false,
  }) {
    return _subscription.add(source.listen((event) {
      pushWithMerge(event, merge: merge, forceMerge: forceMerge);
    }));
  }

  @override
  Future dispose() async {
    return _subscription.dispose();
  }

  @override
  void onRegistered(ReduxStore<TState> store) {
    this.store = store;
  }

  /// Bufferへ値を追加し、必要であればStoreのDispatchイベントを発行する.
  void pushWithMerge<T>(
    T newProperty, {
    required TState Function(TState state, T value) merge,
    bool forceMerge = false,
  }) {
    push<T>(newProperty, merge: merge);
    final store = this.store;
    if (forceMerge || store?.hasPendingActions() == false) {
      // 実行中のActionがなければマージを促す
      store?.dispatch(MultiSourceReduxAction.merge());
    }
  }
}
