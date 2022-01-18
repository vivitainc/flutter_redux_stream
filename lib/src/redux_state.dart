part of 'redux_store.dart';

/// Redux PatternにおけるStateを示す.
///
/// Stateはannotationが示すとおり不変値であり、生成後の影響を受けてはならない.
/// 命名としてStateのほうがベターであるが、Flutter.Widgetとの競合を避けるためにReduxStateと名付ける.
@immutable
mixin ReduxState {}

extension ReduxStateExtension<T extends ReduxState> on T {
  /// Stateから特定のPropertyを探して返却する.
  /// このとき [selector] が例外を投げたら握りつぶしてnullとする.
  T2? select<T2>(T2? Function(T state) selector) {
    try {
      return selector(this);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }
}
