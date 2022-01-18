flutter_redux_stream

| CI / CD | ビルドステータス |
|---|---|
| Github Actions | [![Github Actions](https://github.com/vivitainc/flutter_redux_stream/actions/workflows/flutter-package-test.yaml/badge.svg)](https://github.com/vivitainc/flutter_redux_stream/actions/workflows/flutter-package-test.yaml) |

## Features

[Redux](https://redux.js.org/) をFlutterで実現するためのフレームワーク。

Reduxの処理がFutureではなくStreamで実装されており、Event等の通知に応用することができる.

下記の機能が実装済み

* State Interface
  * Reduxのステートを保持する
  * 常にImmutableとして実装すること
* Action Interface
  * Stateの操作処理を定義する
* Store
  * 現在のStateを保持する
  * Stateの変更はStreamで通知する
* Middleware
  * Store動作を拡張するためのインターフェースを提供する
  * Actionとは異なりState操作は行えないが、追加のリソースを管理したり、任意のタイミング（例えば毎秒1回）でActionを発行する等で使用する

特性上データコピーが頻発するため、低スペック端末に対応する場合は十分に注意して実装すること.

## Getting started

TODO.

```yaml
# pubspec.yaml
```

## Usage

TODO.

```dart
```
## Additional information
