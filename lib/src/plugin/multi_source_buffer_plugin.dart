import 'package:rxdart/rxdart.dart';

import '../redux_plugin.dart';
import '../redux_store.dart';
import 'multi_source_redux_action.dart';
import 'multi_source_redux_property_buffer_mixin.dart';

/// [MultiSourceReduxPropertyBufferMixin] および [MultiSourceReduxPropertyBufferMixin] を
/// 簡潔に扱えるようにラップするPlugin.
class MultiSourceBufferPlugin<TState extends ReduxState>
    extends ReduxPlugin<TState>
    with MultiSourceReduxPropertyBufferMixin<TState> {
  ReduxStore<TState>? _store;

  final _subscription = CompositeSubscription();

  /// Streamからデータを受け取り、Storeへとマージする.
  /// StreamはReduxStoreのライフサイクル終了時に自動的に解放される.
  void addStreamSource<T>(
    Stream<T> source,
    TState Function(TState state, T value) merge,
  ) {
    _subscription.add(source.listen((event) {
      push<T>(event, merge: merge);
      final store = _store;
      if (store != null && !store.hasActions()) {
        // 実行中のActionがなければマージを促す
        store.dispatch(MultiSourceReduxAction.merge());
      }
    }));
  }

  @override
  void dispose() {
    _subscription.dispose();
  }

  @override
  void onRegistered(ReduxStore<TState> store) {
    _store = store;
  }
}
