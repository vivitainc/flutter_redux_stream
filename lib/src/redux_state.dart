part of 'redux_store.dart';

/// Redux PatternにおけるStateを示す.
///
/// Stateはannotationが示すとおり不変値であり、生成後の影響を受けてはならない.
/// 命名としてStateのほうがベターであるが、Flutter.Widgetとの競合を避けるためにReduxStateと名付ける.
@immutable
mixin ReduxState {}

/// ReduxStateのカスタム解放関数.
/// [ReduxStore.dispose] の終了タイミングでコールされる.
///
/// NOTE.
/// この関数がコールされるタイミングは、ReduxStore.dispose()の最中である.
/// そのため、ReduxStoreに対して処理を行おうとしてはいけない.
/// また、それを明示するために引数としてReduxStoreインスタンスを渡さない.
typedef ReduxStateDispose<TState extends ReduxState> = Future Function(
  TState state,
);
