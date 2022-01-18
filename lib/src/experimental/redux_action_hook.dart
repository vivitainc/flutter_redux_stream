import 'package:stdlib_plus/stdlib_plus.dart';

import '../redux_store.dart';

/// ReduxActionの事後に処理を差し込む.
///
/// Hookは非常に強力で、Actionが生成したStateを更新直前に値を変更することができる。
/// 例えば、生成されたStateを正規化する等の調整に使用する。
///
/// 非常に強力であるため、設計上は `Middleware` や `Action` 側で効率的に行えない処理だけに留めること.
abstract class ReduxActionHook<TState extends ReduxState> extends Disposable {
  /// StoreへMiddlewareが登録された.
  void onRegistered(ReduxStore<TState> store) {}

  /// 値の更新直前に呼び出される.
  /// このメソッドが返却したStateが、実際に書き込まれるStateとなる.
  TState shouldStateChange(
    ReduxStore<TState> store,
    ReduxAction<TState> action,
    TState oldState,
    TState newState,
  ) {
    return newState;
  }

  /// Storeから登録解除された
  /// dispose()の直前にも呼び出される.
  void onUnregistered(ReduxStore<TState> store) {}
}
