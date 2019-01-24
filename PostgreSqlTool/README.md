# PostgreSqlTool.sh

### PostgreSQLのデータベースを操作する機能を提供するツール

#### environment.ini

- データベースへの接続先情報が書かれています

#### 提供する機能は下記の通りです

- Dumpファイルをリストアしデータベースを作成する
- データベースの初期化（VACUMM、REINDEX、ANALYZE）
- すべてのテーブルをTruncate
- すべてのシーケンスを初期化する（すべて1にする）
- 特定のテーブルをTruncateする
- 特定のシーケンスを初期化する（1にする）
- データをテキストファイル（tsv）からテーブルに投入する
- SQLファイルを実行する

#### sample.sh

- PostgreSqlTool.shを使用したサンプルのシェルスクリプトです

#### その他
- バージョン情報で確認
    - PostgreSQL：9.6.9
