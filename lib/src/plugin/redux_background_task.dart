import '../redux_store.dart';
import 'redux_background_task_plugin.dart';

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
abstract class ReduxBackgroundTask<TState extends ReduxState> {
  final ReduxStore<TState> store;

  ReduxBackgroundTask(this.store);

  /// 動作を完了したらtrue.
  bool get done;

  Future dispose();

  /// BackgroundTaskの処理を開始させる
  void onStart(TState state);

  /// Pluginの動作リストに登録する
  void registerToPlugin() {
    final mw = store.plugin<ReduxBackgroundTaskPlugin<TState>>();
    store.dispatch(_RegisterBackgroundTask(mw, this));
  }
}

class _RegisterBackgroundTask<TState extends ReduxState>
    extends ReduxAction<TState> {
  final ReduxBackgroundTask<TState> _task;

  final ReduxBackgroundTaskPlugin<TState> _plugin;

  _RegisterBackgroundTask(this._plugin, this._task);

  @override
  Stream<TState> execute(TState state) async* {
    _task.onStart(state);
    _plugin.addTask(_task);
  }
}
