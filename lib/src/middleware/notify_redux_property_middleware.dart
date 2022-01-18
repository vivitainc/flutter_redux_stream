import '../redux_middleware.dart';
import '../redux_property_notifier.dart';
import '../redux_store.dart';

/// [ReduxState] の特定プロパティを監視し、処理を行う.
///
/// NOTE:
/// 登録されているNotifierへの通知は順不同で行われる.
class NotifyReduxPropertyMiddleware<TState extends ReduxState, T>
    extends ReduxMiddleware<TState> {
  final _pendingNotifier = <_PendingNotifier<TState, T>>[];

  /// 登録されているNotifier.
  final _notifierList = <ReduxPropertyNotifier<TState, T>>{};

  /// 保留Notifierを持っている場合true
  bool get hasPendingNotifier => _pendingNotifier.isNotEmpty;

  /// 通知対象を追加する
  void addNotifier(ReduxPropertyNotifier<TState, T> notifier) {
    _pendingNotifier.add(_PendingNotifier(_PendingAction.add, notifier));
  }

  @override
  void onRegistered(ReduxStore<TState> store) {
    _refreshNotifiers(store.state);
  }

  @override
  void onStateChanged(
    ReduxStore<ReduxState> store,
    ReduxAction<ReduxState> action,
    TState oldState,
    TState newState,
  ) {
    _refreshNotifiers(oldState);
    for (final notifier in _notifierList) {
      notifier.onStateChanged(newState);
    }
  }

  @override
  void dispose() {
    for (final pending in _pendingNotifier) {
      pending.notifier.dispose();
    }
    for (final notifier in _notifierList) {
      notifier.dispose();
    }
  }

  /// 通知対象を削除する
  void removeNotifier(ReduxPropertyNotifier<TState, T> notifier) {
    _pendingNotifier.add(_PendingNotifier(_PendingAction.remove, notifier));
  }

  /// 保留されているNotifierを統合する
  void _refreshNotifiers(TState initial) {
    for (final pending in _pendingNotifier) {
      if (pending.action == _PendingAction.add) {
        _notifierList.add(pending.notifier);
        pending.notifier.onStateChanged(initial);
      } else {
        pending.notifier.dispose();
        _notifierList.remove(pending.notifier);
      }
    }
  }
}

enum _PendingAction {
  add,
  remove,
}

class _PendingNotifier<TState extends ReduxState, T> {
  final _PendingAction action;
  final ReduxPropertyNotifier<TState, T> notifier;
  _PendingNotifier(this.action, this.notifier);
}
