import 'redux_store.dart';

/// Modifierにより、簡易的なActionを実現する.
///
/// 何かしら簡易的な逐次実行処理を行いたい場合に使用する.
class UpdateReduxState<TState extends ReduxState, TProperty, TModifiedProperty>
    extends ReduxAction<TState> {
  /// 表示名オプション
  final String? name;

  /// Stateからプロパティを選択する関数
  final TProperty Function(TState state) selector;

  /// 更新処理を行う関数
  final Stream<TModifiedProperty> Function(TState state, TProperty property)
      modifier;

  /// [modifier] が吐き出したTModifiedPropertyをStateに統合する関数
  final TState Function(TState state, TModifiedProperty property) merger;

  UpdateReduxState({
    required this.selector,
    required this.modifier,
    required this.merger,
    this.name,
  });

  /// Propertyを選択せず、Stateをすべて書き換える.
  static UpdateReduxState<TState, TState, TState>
      all<TState extends ReduxState>(
    Stream<TState> Function(TState state) modifier, {
    String? name,
  }) {
    return UpdateReduxState<TState, TState, TState>(
      selector: (state) => state,
      modifier: (state, _) => modifier(state),
      merger: (_, newState) => newState,
      name: name,
    );
  }

  @override
  Stream<TState> execute(
    TState state,
  ) async* {
    final property = selector(state);
    var newState = state;
    await for (final modifiedProperty in modifier(state, property)) {
      newState = merger(newState, modifiedProperty);
      yield newState;
    }
  }

  @override
  String toString() =>
      'UpdateReduxState(name: ${name ?? runtimeType}, modifier: $modifier)';
}
