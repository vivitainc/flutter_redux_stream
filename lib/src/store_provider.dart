import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'redux_store.dart';

typedef StoreCreate<T extends ReduxState> = ReduxStore<T> Function(
    BuildContext context);

typedef StoreDispose<T extends ReduxState> = Future Function(
    ReduxStore<T> store);

typedef WidgetBuilder<T extends ReduxState> = Widget Function(
  BuildContext context,
  ReduxStore<T> store,
);

/// Widget Treeに対してStoreを埋め込む.
///
/// StoreProvider<TState>はProvider<TState>と互換性がある.
/// StreamBuilder.やProxyProviderなど、設計上の都合に応じてUIにマッピングする.
///
/// link:
/// https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html
class StoreProvider<TState extends ReduxState> extends StatelessWidget {
  final StoreCreate<TState> create;

  final StoreDispose<TState>? storeDispose;

  final WidgetBuilder<TState> builder;

  const StoreProvider({
    Key? key,
    required StoreCreate<TState> storeBuilder,
    required WidgetBuilder<TState> widgetBuilder,
    this.storeDispose,
  })  : create = storeBuilder,
        builder = widgetBuilder,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<ReduxStore<TState>>(
      create: (context) => create(context),
      dispose: (_, value) {
        if (storeDispose != null) {
          unawaited(storeDispose!(value));
        } else {
          unawaited(value.dispose());
        }
      },
      builder: (context, child) {
        final store = StoreProvider.of<TState>(context);
        return child ??= ChangeNotifierProvider<_ReduxStateNotifier<TState>>(
          create: (context) => _ReduxStateNotifier(store),
          builder: (context, child) {
            return child ??= ProxyProvider<_ReduxStateNotifier<TState>, TState>(
              update: (context, value, previous) {
                return value.store.state;
              },
              builder: (context, child) {
                return child ??= builder(context, store);
              },
            );
          },
        );
      },
    );
  }

  /// 上位WidgetからReduxStoreを取得する.
  static ReduxStore<TState> of<TState extends ReduxState>(
    BuildContext context,
  ) =>
      Provider.of<ReduxStore<TState>>(
        context,
        listen: false,
      );
}

class _ReduxStateNotifier<TState extends ReduxState> extends ChangeNotifier {
  final ReduxStore<TState> store;

  final subscription = CompositeSubscription();

  _ReduxStateNotifier(this.store) {
    subscription.add(store.stateStream.listen((value) {
      notifyListeners();
    }));
  }

  @override
  void dispose() {
    subscription.dispose();
    super.dispose();
  }
}
