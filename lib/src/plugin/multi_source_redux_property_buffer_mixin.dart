import 'dart:collection';

import '../redux_store.dart';
import 'multi_source_buffer_plugin.dart';
import 'multi_source_redux_action.dart';

/// 複数のStateをマージするためのHelper Class.
///
/// 分割されたStateはBufferにキューイングされ、適切にマージされる.
/// Actionを通じて実際のStateに反映される.
///
/// [MultiSourceBufferPlugin] と [MultiSourceReduxAction] を使用するとActionからアクセスでき、
/// 分離したPropertyのマージを行うことができる.
mixin MultiSourceReduxPropertyBufferMixin<TState extends ReduxState> {
  /// マージ対象のプロパティリスト.
  final _queue = Queue<_StateOperator>();

  /// 登録順を守り、キューが空になるまで順にマージするStreamを生成する.
  /// Stateの切り替わりをトレースする必要があるため、Stateのスキップ/フィルタリングは行わない.
  Stream<TState> merge(TState state) {
    if (_queue.isEmpty) {
      return const Stream.empty();
    }

    return _mergeImpl(state);
  }

  /// Stateの事前マージと事後マージを行う.
  Stream<TState> mergeWithExecute(
    TState state, {
    required Stream<TState> Function(TState state) execute,
  }) async* {
    var copied = state;
    await for (final newState in merge(copied)) {
      copied = newState;
      yield copied;
    }

    await for (final newState in execute(copied)) {
      copied = newState;
      yield copied;
    }

    await for (final newState in merge(copied)) {
      copied = newState;
      yield copied;
    }
  }

  /// 未ハンドリングの新しいStateを追加する.
  void push<TProperty>(
    TProperty newProperty, {
    required TState Function(TState state, TProperty value) merge,
  }) {
    _queue.add(_StateOperator<TState, TProperty>(
      property: newProperty,
      merge: merge,
    ));
  }

  Stream<TState> _mergeImpl(TState state) async* {
    var copied = state;
    while (true) {
      final operator = _pop();
      if (operator == null) {
        return;
      }

      copied = operator.run(copied) as TState;
      yield copied;
    }
  }

  /// TaskQueueの先頭を取得する.
  /// Queueが空になった場合、nullを返却する.
  _StateOperator? _pop() {
    if (_queue.isEmpty) {
      return null;
    } else {
      return _queue.removeFirst();
    }
  }
}

class _StateOperator<TState extends ReduxState, TProperty> {
  /// マージ対象のプロパティ
  final TProperty property;

  /// マージ関数
  final TState Function(TState state, TProperty value) merge;

  _StateOperator({
    required this.property,
    required this.merge,
  });

  TState run(TState state) => merge(state, property);
}
