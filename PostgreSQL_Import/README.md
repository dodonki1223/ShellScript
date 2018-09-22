# PostgreSQLのデータベースのDumpファイルをImportする

### 設定ファイルの内容からDumpファイルをImportします。Dumpファイルは「02_dump」フォルダに◯◯◯.sqlの形式でファイルを入れて下さい

#### import.confについて
- databaseServer
    - データベースサーバー
- databaseName
    - データーベース名
- databaseLoginUser
    - データベースにログインするユーザー
- databaseRoleName
    - データベースに権限を付与するロール名

#### その他
- バージョン情報
    - PostgreSQL：9.6.9
