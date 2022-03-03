import '../redux_store.dart';
import 'multi_source_redux_property_buffer_mixin.dart';

/// 複数のStateを統合して1つのStateを構築する際のサポートを行うReduxAction.
///
/// NOTE.
/// [MultiSourceReduxPropertyBufferMixin] オブジェクトはコンストラクタとして与えるか、
/// もしくはPluginとして登録されている必要がある.
abstract class MultiSourceReduxAction<TState extends ReduxState>
    extends ReduxAction<TState> {
  final MultiSourceReduxPropertyBufferMixin<TState>? _buffer;

  MultiSourceReduxAction({
    MultiSourceReduxPropertyBufferMixin<TState>? buffer,
  }) : _buffer = buffer;

  /// ReduxStore更新処理を生成する.
  ///
  /// 事前・事後処理はオプションであり、基本的には [onExecute] のみ指定すれば良い.
  /// [buffer] がnullである場合、ReduxStore.plugin()を通じて自動的に取得する.
  factory MultiSourceReduxAction.update({
    MultiSourceReduxPropertyBufferMixin<TState>? buffer,
    Stream<TState> Function(TState state)? onPreExecute,
    required Stream<TState> Function(TState state) onExecute,
    Stream<TState> Function(TState state)? onPostExecute,
  }) {
    return _MultiSourceReduxActionImpl(
      buffer: buffer,
      onPreExecuteDelegate: onPreExecute,
      onExecuteDelegate: onExecute,
      onPostExecuteDelegate: onPostExecute,
    );
  }

  /// マージを行うだけのActionを生成する.
  factory MultiSourceReduxAction.merge({
    MultiSourceReduxPropertyBufferMixin<TState>? buffer,
  }) {
    return MultiSourceReduxAction.update(
      onExecute: (state) => const Stream.empty(),
    );
  }

  /// Sourceバッファへアクセスする.
  MultiSourceReduxPropertyBufferMixin<TState> get buffer =>
      _buffer ?? store.plugin<MultiSourceReduxPropertyBufferMixin<TState>>();

  @override
  Stream<TState> execute(final TState state) async* {
    // 事前統合処理
    var copied = state;
    await for (final newState in buffer.merge(copied)) {
      copied = newState;
      await onPreMerge(copied);
      yield copied;
    }

    // 実際の処理
    await for (final newState in onExecute(copied)) {
      copied = newState;
      yield copied;
    }

    // 事後処理
    await for (final newState in buffer.merge(copied)) {
      copied = newState;
      await onPostMerge(copied);
      yield copied;
    }

    // 結合後最終処理
    await for (final newState in onPostExecute(copied)) {
      copied = newState;
      yield copied;
    }
  }

  /// メイン処理
  Stream<TState> onExecute(TState state);

  /// 事後処理
  Stream<TState> onPostExecute(TState state) => const Stream.empty();

  /// 事後統合処理進捗
  Future onPostMerge(TState state) => Future<void>.value(null);

  /// 事前処理
  Stream<TState> onPreExecute(TState state) => const Stream.empty();

  /// 事前統合処理進捗
  Future onPreMerge(TState state) => Future<void>.value(null);
}

class _MultiSourceReduxActionImpl<TState extends ReduxState>
    extends MultiSourceReduxAction<TState> {
  final Stream<TState> Function(TState state)? onPreExecuteDelegate;

  final Stream<TState> Function(TState state) onExecuteDelegate;

  final Stream<TState> Function(TState state)? onPostExecuteDelegate;

  _MultiSourceReduxActionImpl({
    MultiSourceReduxPropertyBufferMixin<TState>? buffer,
    required this.onPreExecuteDelegate,
    required this.onExecuteDelegate,
    required this.onPostExecuteDelegate,
  }) : super(buffer: buffer);

  @override
  Stream<TState> onExecute(TState state) => onExecuteDelegate(state);

  @override
  Stream<TState> onPostExecute(TState state) =>
      onPostExecuteDelegate?.call(state) ?? const Stream.empty();

  @override
  Stream<TState> onPreExecute(TState state) =>
      onPreExecuteDelegate?.call(state) ?? const Stream.empty();
}
