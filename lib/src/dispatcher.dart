part of 'redux_store.dart';

/// Actionの処理順確定と実行処理を行う
///
/// 将来的に処理順の変更機能を盛り込む可能性があるが、
/// 2021-05時点では逐次実行のみをサポートする.
///
/// NOTE.
/// 一度execute()が発行されたActionは最後まで実行する権利を得る.
/// 内部で発生した [CancellationException] のタイミングに寄ってStateが不定になるのを防ぐため、
/// Actionは必ず正常終了しなければならない.
class Dispatcher<TState extends ReduxState> {
  final Notify _notify;

  /// 実行対象のAction
  /// 順番が保持され、逐次実行が行われる.
  final NotifyChannel<ReduxAction<TState>> _channel;

  /// 現在実行中のAction.
  ReduxAction<TState>? _current;

  Dispatcher(this._notify) : _channel = NotifyChannel(_notify);

  /// 処理を開始する
  void _start(ReduxStore<TState> store) => unawaited(_execute(store));

  /// Actionを処理キューに追加し、実行をリクエストする.
  /// 実行は非同期に行われる.
  ///
  /// デフォルトではdispatch()呼び出し順は保持され、順番に処理される.
  /// dispatch()をオーバーライドし、処理順を変更することも可能.
  void dispatch(ReduxAction<TState> action) {
    if (!_channel.isClosed) {
      _channel.send(action);
    }
  }

  /// 実行待ち、もしくは実行中のActionが存在する場合はtrue.
  bool hasActions() {
    return _channel.isNotEmpty || _current != null;
  }

  /// 実行待ちのActionが存在する場合true
  bool hasPendingActions() => _channel.isNotEmpty;

  Future _execute(ReduxStore<TState> store) async {
    logInfo('start Dispatcher<$TState>');
    try {
      while (true) {
        // 次に実行すべきActionを取得する
        // 動作がキャンセルされた場合、receive()が [CancellationException] 例外を投げるため、
        // それによってループから抜ける.
        //
        // 現実的にdispose()タイミングで都合よくループチェックタイミングにはならないため、
        // この対応で問題がない.
        final ReduxAction<TState> action;
        try {
          action = await _channel.receive(
            message: 'receive ReduxAction<$TState>',
          );
        } on CancellationException catch (_) {
          logInfo('Dispatcher<$TState> closed');
          return;
        }
        _current = action;
        // logInfo('dispatch: $action pending=${_channel.pendingItemCount}');

        // 処理が完了するまで取得
        action._state = _ActionState.execute;
        final oldState = store.state;
        var newState = oldState;
        try {
          try {
            final stream = action.execute(oldState);
            var number = 0;
            await for (final received in stream) {
              store._notify(action, number, received);
              newState = received;
              ++number;
            }
          } on Exception catch (e, stack) {
            logError('abort execute: $action', e, stack);
            if (kDebugMode &&
                !Platform.environment.containsKey('FLUTTER_TEST')) {
              logInfo(
                  '========================= Inspect ReduxStore<$TState> =========================');
              developer.inspect(store.state);
              developer.inspect(action);
              logInfo(
                  '===============================================================================');
              developer.debugger(
                message: 'Action<${action.runtimeType}> broken',
              );
            }
          }
        } finally {
          store._notify(action, ReduxStateNotify._done, newState);
          action._state = _ActionState.done;
          _current = null;
          // 通知送信.
          _notify.notify();
        }
      }
    } on Exception catch (e, stack) {
      if (e is! CancellationException) {
        logError('abort dispatcher: $store', e, stack);
        rethrow;
      } else {
        logError('cancel dispatcher: $store', e, stack);
      }
    } finally {
      logInfo('finish dispatcher: $store');
    }
  }

  Future dispose() async {}
}
