-- データベースを削除するする
DROP DATABASE __DATABASE_NAME__;

-- データベースを作成する
CREATE DATABASE __DATABASE_NAME__;

-- データベースに権限を付与する
-- ※「__DATABASE_NAME__」データベースの利用可能な全ての権限を「__ROLE_NAME__」ロール（ユーザー）に付与する
GRANT ALL PRIVILEGES ON DATABASE __DATABASE_NAME__ TO __ROLE_NAME__;
