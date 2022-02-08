import '../redux_plugin.dart';
import '../redux_store.dart';
import 'redux_background_task.dart';

/// ReduxStoreのBackground動作を行う.
class ReduxBackgroundTaskPlugin<TState extends ReduxState>
    extends ReduxPlugin<TState> {
  final _taskList = <ReduxBackgroundTask<TState>>{};

  /// 実行対象のタスクを追加する
  void addTask(ReduxBackgroundTask<TState> task) {
    _taskList.add(task);
  }

  @override
  void dispose() {
    _gc(all: true);
  }

  @override
  void onDispatch(
      ReduxStore<TState> store, ReduxAction<TState> action, TState state) {
    _gc(all: false);
  }

  @override
  void onStateChanged(
    ReduxStore<TState> store,
    ReduxAction<TState> action,
    TState oldState,
    TState newState,
  ) {
    var requireGc = false;
    final list = {..._taskList};
    for (final task in list) {
      if (task.done) {
        requireGc = true;
      }
    }

    if (requireGc) {
      _gc(all: false);
    }
  }

  /// 実行対象のタスクを削除する
  void removeTask(
    ReduxBackgroundTask<TState> task, {
    required bool withDispose,
  }) {
    _taskList.remove(task);
    if (withDispose) {
      task.dispose();
    }
  }

  void _gc({required bool all}) {
    final list = {..._taskList};
    if (all) {
      for (final task in list) {
        task.dispose();
      }
      _taskList.clear();
      return;
    } else {
      final remove = <ReduxBackgroundTask<TState>>{};
      for (final task in list) {
        if (task.done) {
          remove.add(task);
        }
      }

      for (final task in remove) {
        task.dispose();
        _taskList.remove(task);
      }
    }
  }
}
