part of 'redux_store.dart';

/// Store.state更新イベントを通知する.
@immutable
class ReduxStateNotify<TState extends ReduxState> {
  /// Store全体の更新回数
  final int storeUpdateNumber;

  /// ステート変更を行ったAction.
  final ReduxAction<TState> action;

  /// このActionでの更新回数
  final int actionUpdateNumber;

  /// 更新前のState.
  final TState oldState;

  /// 更新後のState.
  final TState newState;

  const ReduxStateNotify._init(
    this.storeUpdateNumber,
    this.action,
    this.actionUpdateNumber,
    this.oldState,
    this.newState,
  );

  /// 更新終了メッセージの場合はtrue.
  bool get done => actionUpdateNumber == _done;

  static const _done = -1;
}
