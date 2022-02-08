part of 'redux_store.dart';

/// Redux PatternにおけるStateを示す.
///
/// Stateはannotationが示すとおり不変値であり、生成後の影響を受けてはならない.
/// 命名としてStateのほうがベターであるが、Flutter.Widgetとの競合を避けるためにReduxStateと名付ける.
@immutable
mixin ReduxState {}
