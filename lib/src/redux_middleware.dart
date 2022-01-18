import 'package:stdlib_plus/stdlib_plus.dart';

import 'redux_store.dart';

/// Redux Storeの各種タイミングでハンドリングを行う.
///
/// Actionとは違い、非同期処理やStateを変更することはできない.
/// ReduxStore.dispose()の呼び出し時にReduxMiddleware.dispose()が実行される.
abstract class ReduxMiddleware<TState extends ReduxState>
    implements Disposable {
  /// StoreへMiddlewareが登録された.
  void onRegistered(ReduxStore<TState> store) {}

  /// StoreへDispatch命令が発行された.
  ///
  /// 行えるのはイベントハンドリングのみで、Dispatchが実行されることを止めることはできない.
  ///
  /// また、イベントキューに登録される可能性があり、このメッセージ直後にActionが実行されること、
  /// キャンセルされるずに(Store.dispose()されずに）Actionが実行されることは保証されない.
  void onDispatch(
    ReduxStore<TState> store,
    ReduxAction<TState> action,
    TState state,
  ) {}

  /// Stateが実際に反映されたタイミングで呼び出される.
  void onStateChanged(
    ReduxStore<TState> store,
    ReduxAction<TState> action,
    TState oldState,
    TState newState,
  ) {}

  /// Storeから登録解除された
  /// dispose()の直前にも呼び出される.
  void onUnregistered(ReduxStore<TState> store) {}
}
