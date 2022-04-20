part of 'redux_store.dart';

/// Redux PatternにおけるActionを定義する.
/// Storeはexecute()が返却したStreamから逐次値を取得し、Storeへ反映させる.
/// Stream<State>が閉じられた時点でexecute()が完了したとみなし、このActionは破棄される.
///
/// 設計上の制約:
/// Actionそのものは非同期に行われるが、 1つの`Action.execute()` が終了するまで、
/// ほかのActionは保留される.
abstract class ReduxAction<TState extends ReduxState> {
  // ignore: prefer_final_fields
  var _state = _ActionState.pending;

  late ReduxStore<TState> _store;

  /// 実行完了していればtrue.
  bool get done => _state == _ActionState.done;

  /// 実行対象のStoreを取得する.
  @protected
  ReduxStore<TState> get store => _store;

  /// Action内で別なActionを実行する.
  /// 他のActionを使い回すなどの利用方法がある.
  /// ただし、引数 [action] は使用済みとなるため、再利用はできない.
  @Deprecated('replace to "interrupt()"')
  Stream<TState> delegate(ReduxAction<TState> action, TState state) =>
      interrupt(action, state);

  Stream<TState> execute(TState state);

  /// Action内で別なActionを割り込み実行する.
  /// 他のActionを使い回すなどの利用方法がある.
  /// ただし、引数 [action] は使用済みとなるため、再利用はできない.
  Stream<TState> interrupt(ReduxAction<TState> action, TState state) async* {
    assert(action._state == _ActionState.pending, 'Invalid state, $action');
    try {
      action._state = _ActionState.execute;
      action._store = _store;
      yield* action.execute(state);
    } finally {
      action._state = _ActionState.done;
    }
  }
}

enum _ActionState {
  /// 実行保留中
  pending,

  /// 実行中
  execute,

  /// 完了
  done,
}
