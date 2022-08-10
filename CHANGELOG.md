## 0.2.2

* ReduxStore.stateStream(データ通知)とReduxStore.renderStream(レンダリング制御通知)を分離
  * これにより更新がスパイクしてもRebuildが肥大化しないようになった

## 0.2.1

* ReduxStore.stateStream()の通知が最小になるように最適化
* ReduxStore.stateStreamをStreamを返却するように調整

## 0.2.0+3

* Mod Loggingに簡易タグを追加

## 0.2.0+2

* Fix MultiSourceBufferPlugin.
* Rename
    * ReduxAction.delegate() => ReduxAction.interrupt()


## 0.2.0+1

* Fix analyzer.

## 0.2.0

* Beta Release.
