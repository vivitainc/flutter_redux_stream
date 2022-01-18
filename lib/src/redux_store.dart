import 'dart:async';
import 'dart:developer' as developer;

import 'package:async_plus/async_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stdlib_plus/stdlib_plus.dart';

import 'experimental/redux_action_hook.dart';
import 'internal/logger.dart';
import 'redux_middleware.dart';

part 'dispatcher.dart';
part 'redux_action.dart';
part 'redux_state.dart';
part 'redux_state_notify.dart';

/// Redux PatternにおけるStoreを定義する.
/// Storeは現在のステートと処理主体であるReducerを持つ.
///
/// Storeは配下に持つReducer等のライフサイクルも管理する.
/// Store.dispose()されたタイミングでLifecycle.onDestroy()が実行され、
/// 非同期処理等が逐次キャンセルされる.
class ReduxStore<TState extends ReduxState> implements Disposable {
  final _notifier = Notify();

  final BehaviorSubject<TState> _state;

  final PublishSubject<ReduxStateNotify<TState>> _notifyEvent =
      PublishSubject();

  late Dispatcher<TState> _dispatcher;

  final List<ReduxMiddleware<TState>> _middlewareList = [];

  final List<ReduxActionHook<TState>> _hookList = [];

  /// 通知番号
  /// Initialを除き、データが更新されるタイミングで発行される.
  var _notifyNumber = 0;

  ReduxStore({
    required TState initial,
  }) : _state = BehaviorSubject.seeded(initial) {
    _dispatcher = Dispatcher(_notifier);
    _dispatcher._start(this);
  }

  /// 更新タイミングで付加情報を取得する.
  ///
  /// 更新回数や実行されたAction等も取得できる.
  /// この値はEventとして動作するため、Storeに保持されない.
  Subject<ReduxStateNotify<TState>> get notifyEvent => _notifyEvent;

  /// 現在のStateを取得する.
  TState get state => _state.value;

  /// StateをStreamとして取得する.
  Subject<TState> get stateStream => _state;

  /// Action実行をリクエストする.
  ///
  /// この処理はFire & Forgetのため、終了を待ち合わせることはできない.
  void dispatch(ReduxAction<TState> action) {
    action._store = this;
    for (final element in _middlewareList) {
      element.onDispatch(this, action, state);
    }
    _dispatcher.dispatch(action);
    _notifier.notify();
  }

  /// Action実行をリクエストし、終了待ちのFuture<TState>を返却する.
  ///
  /// MEMO:
  /// async funcにすると実行タイミングにズレが生じるため、
  /// 即時実行 + 非同期関数として動作する.
  Future<TState> dispatchAndResult(ReduxAction<TState> action) {
    final future = () async {
      await for (final notify in notifyEvent) {
        if (notify.action != action) {
          continue;
        }
        if (notify.done) {
          // logInfo('done dispatchAndResult($action)');
          return notify.newState;
        }
      }
      throw CancellationException('.notifyEvent canceled: $action');
    }();
    dispatch(action);
    return future;
  }

  /// Action実行をリクエストし、値取得用のStream<TState>を返却する.
  /// Actionの実行に合わせてStreamに通知され、Action終了時にStreamがcloseされる.
  ///
  /// MEMO:
  /// async funcにすると実行タイミングにズレが生じるため、
  /// 即時実行 + 非同期関数として動作する.
  Stream<TState> dispatchAndStream(ReduxAction<TState> action) {
    final Stream<TState> stream = () async* {
      await for (final notify in notifyEvent) {
        if (notify.action != action) {
          continue;
        }
        yield notify.newState;
        if (notify.done) {
          break;
        }
      }
      // logInfo('close dispatchAndStream($action)');
    }();
    dispatch(action);
    return stream;
  }

  /// Storeの終了処理を行う
  @mustCallSuper
  @override
  void dispose() {
    _notifier.dispose();
    _middlewareList
      ..forEach((element) {
        element
          ..onUnregistered(this)
          ..dispose();
      })
      ..clear();
    _hookList
      ..forEach((element) {
        element
          ..onUnregistered(this)
          ..dispose();
      })
      ..clear();
    _notifyEvent.close();
    _dispatcher.dispose();
    _state.close();
  }

  /// 実行待ち、もしくは実行中のActionがあればtrueを返却する.
  bool hasActions() => _dispatcher.hasActions();

  /// 指定Middlewareを取得する.
  /// 指定型のMiddlewareが見つからない場合、このメソッドは例外を投げる.
  TMiddleware middleware<TMiddleware>() {
    final itr = _middlewareList.whereType<TMiddleware>();
    check(itr.isNotEmpty, () => 'Invalid Middleware<$TMiddleware>');
    return itr.first;
  }

  /// 指定Middlewareを取得する.
  /// 指定型のMiddlewareが見つからない場合、このメソッドは例外を投げる.
  TMiddleware? middlewareOrNull<TMiddleware>() {
    final itr = _middlewareList.whereType<TMiddleware>();
    if (itr.isEmpty) {
      return null;
    }
    return itr.first;
  }

  /// Hookを登録する.
  /// Hook処理は強力なため、十分に利用可否を検討する必要がある.
  void registerHook(ReduxActionHook<TState> hook) {
    assert(!_hookList.contains(hook), 'hook is registered');

    _hookList.add(hook);
    hook.onRegistered(this);
  }

  /// MiddlewareをStoreへ登録する.
  void registerMiddleware(ReduxMiddleware<TState> middleware) {
    assert(!_middlewareList.contains(middleware), 'middleware is registered');

    _middlewareList.add(middleware);
    middleware.onRegistered(this);
  }

  /// 指定型と条件に一致するMiddlewareを検索する
  TMiddleware whereMiddleware<TMiddleware>(
      bool Function(ReduxMiddleware<TState> element) test) {
    final itr = _middlewareList.where(test).whereType<TMiddleware>();
    check(itr.isNotEmpty, () => 'Invalid Middleware<$TMiddleware>');
    return itr.first;
  }

  /// 新しいデータをStoreに反映させる
  void _notify(ReduxAction<TState> action, int number, TState rawNewState) {
    if (_notifier.isClosed) {
      // closeされているので何もしない
      return;
    }
    final oldState = state;

    // Middlewareに値の正規化を行わせる.
    var newState = rawNewState;
    for (final element in _hookList) {
      newState = element.shouldStateChange(
        this,
        action,
        oldState,
        newState,
      );
    }

    // 正規化済みの値を書き込む.
    _state.value = newState;
    _notifyEvent.add(ReduxStateNotify._init(
      _notifyNumber,
      action,
      number,
      oldState,
      newState,
    ));
    _notifyNumber++;
    for (final element in _middlewareList) {
      element.onStateChanged(
        this,
        action,
        oldState,
        newState,
      );
    }
    _notifier.notify(); // 通知待ちオブジェクトに処理を継続させる.
  }
}
