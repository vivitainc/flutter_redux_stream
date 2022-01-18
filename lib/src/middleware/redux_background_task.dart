import 'package:stdlib_plus/stdlib_plus.dart';

import '../redux_store.dart';
import 'redux_background_task_middleware.dart';

/// ReduxStoreのBackground処理を行う.
/// これは処理の分割やPlugin等の細かい処理を挿入するための用意されており、
/// 実際のState反映はあくまでReduxActionを要する.
///
/// NOTE:
/// このReduxBackgroundTaskは処理の簡略化のため、
/// ReduxStateが更新されたタイミングでgc処理される.
///
/// また、ReduxStore.dispose()がコールされると、強制的にdispose()が
/// コールされる.
/// その際は速やかにメモリを開放して処理を終了しなければならない.
///
/// 登録処理はActionとして行われるため、
/// gcまでには最低でも1Actionイテレーションは稼働可能なことになる.
abstract class ReduxBackgroundTask<TState extends ReduxState>
    extends Disposable {
  final ReduxStore<TState> store;

  ReduxBackgroundTask(this.store);

  /// 動作を完了したらtrue.
  bool get done;

  /// BackgroundTaskの処理を開始させる
  void onStart(TState state);

  /// Middlewareの動作リストに登録する
  void registerToMiddleware() {
    final mw = store.middleware<ReduxBackgroundTaskMiddleware<TState>>();
    store.dispatch(_RegisterBackgroundTask(mw, this));
  }
}

class _RegisterBackgroundTask<TState extends ReduxState>
    extends ReduxAction<TState> {
  final ReduxBackgroundTask<TState> _task;

  final ReduxBackgroundTaskMiddleware<TState> _middleware;

  _RegisterBackgroundTask(this._middleware, this._task);

  @override
  Stream<TState> execute(TState state) async* {
    _task.onStart(state);
    _middleware.addTask(_task);
  }
}
