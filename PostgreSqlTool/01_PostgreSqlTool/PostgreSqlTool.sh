#!/bin/bash -xv

#***********************************************************************************
#* バッチ名：PostgreSQLをシェルから使用するためのツール群です
#* 処理内容：PostgreSQLをシェルから簡単に使用するためのツールを提供します。
#*           提供する機能は下記の通りです
#*           ・Dumpファイルをリストアしデータベースを作成する
#*           ・データベースの初期化（VACUMM、REINDEX、ANALYZE）
#*           ・すべてのテーブルをTruncate
#*           ・すべてのシーケンスを初期化する（すべて1にする）
#*           ・特定のテーブルをTruncateする
#*           ・特定のシーケンスを初期化する（1にする）
#*           ・データをテキストファイル（tsv）からテーブルに投入する
#*           ・SQLファイルを実行する
#* 使用方法：このシェルに設定ファイルを引数として与えて読み込むこと
#*           例) source ./01_DbTool/DbTool.sh "./00_environment/environment.ini"
#*               設定ファイルには下記の情報を記述すること
#*                 DATABASE_IP=sampleIP
#*                 DATABASE_NAME=sampleDB
#*                 DATABASE_USER=postgres
#***********************************************************************************

# このシェルスクリプトの実行パスを取得する
scriptPath=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

# このシェルが読み込まれた時間を取得する
readTime=$(date -d '9 hours' +%Y%m%d%H%M%S)

# データベースの接続情報を設定ファイルから読み込み
databaseConnectFilePath=${1}
source ${databaseConnectFilePath}

#*****************************************
#* フォルダ情報をセットする
#*****************************************
# 実行用のSQLフォルダ・インサート用のデータフォルダを取得
inesrtSqlFolder=${scriptPath}/01_InsertSQL
insertDataFolder=${scriptPath}/02_InsertData
initializeSequenceSQLFolder=${scriptPath}/03_InitializeSequenceSQL
truncateSqlFolder=${scriptPath}/04_TruncateSQL
allInitializeSequenceSQLFolder=${scriptPath}/05_AllInitializeSequenceSQL
allTruncateSqlFolder=${scriptPath}/06_AllTruncateSQL
initialDBSqlFolder=${scriptPath}/07_InitialDBSQL
runSqlFolder=${scriptPath}/08_RunSQL
dumpFolder=${scriptPath}/09_Dump
dropSchemaFolder=${scriptPath}/10_DropSchema

# tmpフォルダ情報を取得する
tmpInesrtSqlFolder=${inesrtSqlFolder}/tmp
tmpInitializeSequenceSQLFolder=${initializeSequenceSQLFolder}/tmp
tmptruncateSqlFolder=${truncateSqlFolder}/tmp
tmpAllInitializeSequenceSQLFolder=${allInitializeSequenceSQLFolder}/tmp
tmpAllTruncateSqlFolder=${allTruncateSqlFolder}/tmp
tmpAllTruncateSqlFolder=${allTruncateSqlFolder}/tmp
tmpInitialDBSqlFolder=${initialDBSqlFolder}/tmp

#*****************************************
#* 実行情報を画面に表示する
#*****************************************
echo 
echo ---------------------------------------------
echo \<データベースの接続情報\>
echo psqlバージョン：$(psql --version)
echo DATABASE_IP　 ：${DATABASE_IP}
echo DATABASE_PORT ：${DATABASE_PORT}
echo DATABASE_NAME ：${DATABASE_NAME}
echo DATABASE_USER ：${DATABASE_USER}
echo ---------------------------------------------
echo

#*****************************************************************************
#* 処 理 名：DBの情報をログファイルに書き込む
#* 引    数：$1 ログを書き込むログファイルパス
#* 処理内容：引数で渡されたログファイルのパスにDB情報を追記する
#*****************************************************************************
WriteDbInfoToLogFile()
{

    logFilePath=$1

    echo                                               >> ${logFilePath} 2>&1
    echo --------------------------------------------- >> ${logFilePath} 2>&1
    echo \<データベースの接続情報\>                    >> ${logFilePath} 2>&1
    echo psqlバージョン：$(psql --version)             >> ${logFilePath} 2>&1
    echo DATABASE_IP　 ：${DATABASE_IP}                >> ${logFilePath} 2>&1
    echo DATABASE_PORT ：${DATABASE_PORT}              >> ${logFilePath} 2>&1
    echo DATABASE_NAME ：${DATABASE_NAME}              >> ${logFilePath} 2>&1
    echo DATABASE_USER ：${DATABASE_USER}              >> ${logFilePath} 2>&1
    echo --------------------------------------------- >> ${logFilePath} 2>&1
    echo                                               >> ${logFilePath} 2>&1

}

#*****************************************************************************
#* 処 理 名：tmpフォルダ内のファイルをすべて削除する
#* 引    数：なし
#* 処理内容：tmpファオルダ内にできているSQLファイルをすべて削除する
#*****************************************************************************
DeleteFileInTmpFolder()
{

    # echo ---------------------------------------------
    # echo \<tmpフォルダ内のファイルをすべて削除します\>
    # echo ---------------------------------------------
    # echo \<tmpフォルダ情報\>
    # echo InsertSQLTmpフォルダ　　　 　 ：${tmpInesrtSqlFolder}
    # echo シーケンス初期化Tmpフォルダ 　：${tmpInitializeSequenceSQLFolder}
    # echo TruncateSQLTmpフォルダ 　 　　：${tmptruncateSqlFolder}
    # echo Allシーケンス初期化Tmpフォルダ：${tmpAllInitializeSequenceSQLFolder}
    # echo AllTruncateSQLTmpフォルダ 　　：${tmpAllTruncateSqlFolder}
    # echo InitialDBSQLTmpフォルダ 　　　：${tmpInitialDBSqlFolder}
    # echo ---------------------------------------------

    # InsertSQLTmpフォルダ内のファイルを削除する
    # echo InsertSQLTmpフォルダ内のファイルを削除します
    rm -f $tmpInesrtSqlFolder/*.SQL
    # echo

    # シーケンス初期化Tmpフォルダ内のファイルを削除する
    # echo シーケンス初期化Tmpフォルダ内のファイルを削除します
    rm -f $tmpInitializeSequenceSQLFolder/*.SQL
    # echo

    # TruncateSQLTmpフォルダ内のファイルを削除する
    # echo TruncateSQLTmpフォルダ内のファイルを削除します
    rm -f $tmptruncateSqlFolder/*.SQL
    # echo

    # Allシーケンス初期化Tmpフォルダ内のファイルを削除する
    # echo Allシーケンス初期化Tmpフォルダ内のファイルを削除します
    rm -f $tmpAllInitializeSequenceSQLFolder/*.SQL
    # echo

    # AllTruncateSQLTmpフォルダ内のファイルを削除する
    # echo AllTruncateSQLTmpフォルダ内のファイルを削除します
    rm -f $tmpAllTruncateSqlFolder/*.SQL
    # echo

    # InitialDbSQLTmpフォルダ内のファイルを削除する
    # echo InitialDBSQLTmpフォルダ内のファイルを削除します
    rm -f $tmpInitialDBSqlFolder/*.SQL
    # echo

}

#*****************************************************************************
#* 処 理 名：スキーマーを削除する
#* 引    数：$1 psqlコマンドを実行するための追加オプション
#* 処理内容：引数で渡されたオプションを元に実行します
#*****************************************************************************
DropSchema()
{
    # 引数から追加オプションを取得する
    options=$1

    # 実行するSQLファイルのフルパスを取得する
    dropSchemaPath=${dropSchemaFolder}/drop_schemas.SQL

    # スキーマーの削除処理を実行する
    echo ---------------------------------------------
    echo \<スキーマー削除の実行処理\>
    echo 実行SQLファイル：${dropSchemaPath}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $dropSchemaPath $options

    # psqlコマンドの実行結果を取得する
    DropSchemaResult=$?
    echo

    return $DropSchemaResult

}

#*****************************************************************************
#* 処 理 名：Dumpファイルをリストアする
#* 引    数：$1 Dumpファイル名
#*           $2 psqlコマンドを実行するための追加オプション
#* 処理内容：指定されたDumpファイルからリストアする
#*****************************************************************************
RestoreDump()
{

    # Dumpファイルのフルパスを取得
    dumpFilePath=${dumpFolder}/$1

    # 引数から追加オプションを取得する
    options=$2

    # Dumpファイルをリストアします
    echo ---------------------------------------------
    echo \<Dumpファイルのリストア実行\>
    echo 実行SQLファイル：${dumpFilePath}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT $options < ${dumpFilePath}

    # psqlコマンドの実行結果を取得する
    RestoreDumpResult=$?
    echo

    return $RestoreDumpResult

}

#*****************************************************************************
#* 処 理 名：Dumpファイルを作成する
#* 引    数：$1 Dumpファイル名
#*           $2 pg_dumpコマンドを実行するための追加オプション
#* 処理内容：現在のデータベースからDumpファイルを作成する
#*****************************************************************************
ExportDump()
{

    # Dumpファイルのフルパスを取得
    dumpFilePath=${dumpFolder}/$1

    # 引数から追加オプションを取得する
    options=$2

    # Dumpファイルを作成します
    echo ---------------------------------------------
    echo \<Dumpファイルの作成実行\>
    echo Dumpファイル作成場所：${dumpFilePath}
    echo ---------------------------------------------
    echo
    pg_dump -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT $options > ${dumpFilePath}

    # pg_dumpコマンドの実行結果を取得する
    ExportDumpResult=$?
    echo

    return $ExportDumpResult

}

#*****************************************************************************
#* 処 理 名：データベースを初期化する
#* 引    数：$1 psqlコマンドを実行するための追加オプション
#* 処理内容：対象のデータベースを初期化する（VACUMM、REINDEX、ANALYZEを実行）
#*           VACUMM ：不要タプルが使用する領域を回収する。削除されたタプルや更新
#*                    によって不要となったタプルは、テーブルから物理的には削除されません
#*           REINDEX：インデックスのテーブルに保存されたデータを使用してインデック
#*                    スを再構築し、古いインデックスのコピーと置き換えます
#*           ANALYZE：データーベースに関する統計を集計する
#*****************************************************************************
InitialDB()
{

    # InitialDB実行用のSQLファイルを取得
    initialDBSqlFile=${initialDBSqlFolder}/InitialDB.SQL

    # 引数から追加オプションを取得する
    options=$1

    # tmpフォルダに実行用のSQLファイルを作成
    # 文字列置換前のSQLファイルを作成した後、文字列を置換して実行用のSQLファイルを作成
    runSqlFile=${initialDBSqlFolder}/tmp/$$_initialDB.SQL
    cat $initialDBSqlFile >> $runSqlFile
    sed -i -e 's/__DATABASE_NAME__/'$DATABASE_NAME'/g' $runSqlFile

    # InitialDB処理を実行する
    echo ---------------------------------------------
    echo \<InitialDB処理を実行\>
    echo 実行SQLファイル：${runSqlFile}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $runSqlFile $options

    # psqlコマンドの実行結果を取得する
    InitialDBResult=$?
    echo

    return $InitialDBResult

}

#*****************************************************************************
#* 処 理 名：すべてのテーブルをTRUNCATEする
#* 引    数：$1 psqlコマンドを実行するための追加オプション
#* 処理内容：対象のデータベースのすべてのテーブルのTRUNCATEを実行します
#*           \dtコマンドとawkコマンドを使用しTRUNCATEのTABLEのリストを作成する
#*****************************************************************************
AllTruncateTable()
{

    # 実行用のSQLファイルの作成パス
    runSqlFile=${allTruncateSqlFolder}/tmp/$$_all_truncate.SQL

    # 引数から追加オプションを取得する
    options=$1

    # スキーマーがpublicのテーブルの「TRUNCATE TABLE」のリストを出力する
    psql -h ${DATABASE_IP} ${DATABASE_NAME} -U ${DATABASE_USER} -c '\dt public.*' -A -t -F " " |
    awk '{print "TRUNCATE TABLE "$1"."$2" RESTART IDENTITY CASCADE;"}' > $runSqlFile

    # スキーマーがprivateのテーブルの「TRUNCATE TABLE」のリストを出力する
    psql -h ${DATABASE_IP} ${DATABASE_NAME} -U ${DATABASE_USER} -c '\dt private.*' -A -t -F " " |
    awk '{print "TRUNCATE TABLE "$1"."$2" RESTART IDENTITY CASCADE;"}' >> $runSqlFile


    # すべてのテーブルのTRUNCATE処理を実行する
    echo ---------------------------------------------
    echo \<すべてのテーブルのTruncate処理を実行\>
    echo 実行SQLファイル：$runSqlFile
    echo ---------------------------------------------
    echo 
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $runSqlFile $options 

    # psqlコマンドの実行結果を取得する
    AllTruncateTableResult=$?
    echo

    return $AllTruncateTableResult

}

#*****************************************************************************
#* 処 理 名：テーブルのTruncate処理の実行
#* 引    数：$1 対象となるテーブル名
#*           $2 psqlコマンドを実行するための追加オプション
#* 処理内容：引数で渡されたテーブル名を元にTruncate処理を実行する
#*           ※Truncateを実行したSQLファイルは/tmp/PID_truncate_テーブル名.SQL
#*             の形で出力されます
#*****************************************************************************
TruncateTable() 
{

    # 引数からテーブル名、追加オプションを取得する
    tableName=$1
    options=$2

    # Truncate実行用のSQLファイルを取得
    trncateSqlFile=${truncateSqlFolder}/TruncateTable.SQL

    # tmpフォルダに実行用のSQLファイルを作成
    # 文字列置換前のSQLファイルを作成した後、文字列を置換して実行用のSQLファイルを作成
    runSqlFile=${truncateSqlFolder}/tmp/$$_truncate_${tableName}.SQL
    cat $trncateSqlFile >> $runSqlFile
    sed -i -e 's/__TABLE_NAME__/'$tableName'/g' $runSqlFile

    # Truncate処理を実行する
    echo ---------------------------------------------
    echo \<Truncate処理を実行\>
    echo テーブル名　　 ：${tableName}
    echo 実行SQLファイル：${runSqlFile}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $runSqlFile $options

    # psqlコマンドの実行結果を取得する
    TruncateTableResult=$?
    echo

    return $TruncateTableResult

}

#*****************************************************************************
#* 処 理 名：すべてのシーケンスの初期化処理
#* 引    数：$1 対象となるシーケンス名
#*           $2 psqlコマンドを実行するための追加オプション
#* 処理内容：引数で渡されたシーケンス名を元にsetval処理を実行する
#*           ※setvalを実行したSQLファイルは/tmp/PID_init_テーブル名.SQLの形で
#*             出力されます
#*****************************************************************************
AllInitializeSequence()
{

    # すべてのシーケンスを初期化する実行用のSQLファイルを取得する
    runSqlFile=${allInitializeSequenceSQLFolder}/tmp/$$_init_AllInitializeSequence.SQL

    # 引数から追加オプションを取得する
    options=$2
    
    # tmpフォルダに実行用のSQLファイルを作成する
    createRunSqlFile=${allInitializeSequenceSQLFolder}/AllInitializeSequence.SQL
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -f $createRunSqlFile > $runSqlFile

    # 余分な行を削除する（最初の２行、最後の２行）
    # ※SELECT文で作成しているのでカラム行と返ってきたレコード数の部分を削除する
    sed -i -e '1,2d' $runSqlFile
    sed -i -e '$d' $runSqlFile
    sed -i -e '$d' $runSqlFile

    # すべてのシーケンスを初期化する処理を実行する
    echo ---------------------------------------------
    echo \<すべてシーケンスを初期化する処理を実行\>
    echo 実行SQLファイル：${runSqlFile}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $runSqlFile $options

    # psqlコマンドの実行結果を取得する
    AllInitializeSequenceResult=$?
    echo

    return $AllInitializeSequenceResult

}

#*****************************************************************************
#* 処 理 名：シーケンスの初期化処理
#* 引    数：$1 対象となるシーケンス名
#*           $2 psqlコマンドを実行するための追加オプション
#* 処理内容：引数で渡されたシーケンス名を元にsetval処理を実行する
#*           ※setvalを実行したSQLファイルは/tmp/PID_init_テーブル名.SQLの形で
#*             出力されます
#*****************************************************************************
InitializeSequence()
{

    # 引数からシーケンス名、追加オプションを取得する
    sequenceName=$1
    options=$2

    # シーケンスを初期化する実行用のSQLファイルを取得
    initSequenceSqlFile=${initializeSequenceSQLFolder}/InitializeSequence.SQL

    # tmpフォルダに実行用のSQLファイルを作成
    # 文字列置換前のSQLファイルを作成した後、文字列を置換して実行用のSQLファイルを作成
    runSqlFile=${initializeSequenceSQLFolder}/tmp/$$_init_${sequenceName}.SQL
    cat $initSequenceSqlFile >> $runSqlFile
    sed -i -e 's/__SEQUENCE_NAME__/'$sequenceName'/g' $runSqlFile

    # Truncate処理を実行する
    echo ---------------------------------------------
    echo \<シーケンスを初期化する処理を実行\>
    echo シーケンス名　 ：${sequenceName}
    echo 実行SQLファイル：${runSqlFile}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $runSqlFile $options

    # psqlコマンドの実行結果を取得する
    InitializeSequenceResult=$?
    echo

    return $InitializeSequenceResult

}

#*****************************************************************************
#* 処 理 名：データをテキストファイル（tsv）からテーブルに投入する
#* 引    数：$1 対象となるテーブル名
#*           $2 psqlコマンドを実行するための追加オプション
#* 処理内容：引数で渡されたテーブル名を元に「\COPY」コマンドを実行する
#*           ※\COPYを実行したSQLファイルは/tmp/PID_insert_テーブル名.SQLの形
#*             で出力されます
#*****************************************************************************
InsertData()
{

    # 引数からテーブル名、追加オプションを取得する
    tableName=$1
    options=$2

    # 追加用データ、Insertを行うSQLファイルを取得
    insertData=${insertDataFolder}/${tableName}.tsv
    insertSqlFile=${inesrtSqlFolder}/${tableName}.SQL

    # 追加用データから制御文字の「\」バックスラッシュをエスケープする
    # ※変換前のファイルは「.org」をファイル名の最後に付加して保存する
    sed -i'.org' -e 's/\\/\\\\/g' $insertData

    # tmpフォルダに実行用のSQLファイルを作成
    # 文字列置換前のSQLファイルを作成した後、文字列を置換して実行用のSQLファイルを作成
    runSqlFile=${inesrtSqlFolder}/tmp/$$_insert_${tableName}.SQL
    escapeInsertDataPath=$(echo $insertData | sed 's/\//\\\//g')
    cat $insertSqlFile >> $runSqlFile
    sed -i -e 's/__TABLE_NAME__/'$tableName'/g'\
           -e 's/__INSERT_FILE_NAME__/'$escapeInsertDataPath'/g' $runSqlFile

    # Insert処理を実行する
    echo ---------------------------------------------
    echo \<Insert処理を実行\>
    echo テーブル名　　 ：${tableName}
    echo 追加データ　　 ：${insertData}
    echo 実行SQLファイル：${runSqlFile}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $runSqlFile $options

    # psqlコマンドの実行結果を取得する
    InsertDataResult=$?
    echo

    return $InsertDataResult

}

#*****************************************************************************
#* 処 理 名：SQLファイルを実行します
#* 引    数：$1 実行するSQLファイル名
#*           $2 psqlコマンドを実行するための追加オプション
#* 処理内容：引数で渡されたSQLファイル名とオプションを元に実行します
#*           ※実行されるSQLファイルは「08_RunSQL」フォルダに入っていること
#*****************************************************************************
RunSQL()
{
    # 引数から実行するSQLファイル名、追加オプションを取得する
    runSqlFile=$1
    options=$2

    # 実行するSQLファイルのフルパスを取得する
    runSqlFileFullPathr=${runSqlFolder}/${runSqlFile}

    # SQLファイルを実行する
    echo ---------------------------------------------
    echo \<SQLファイルの実行処理\>
    echo 実行SQLファイル：${runSqlFileFullPathr}
    echo ---------------------------------------------
    echo
    psql -h $DATABASE_IP -U $DATABASE_USER -d $DATABASE_NAME -p $DATABASE_PORT -f $runSqlFileFullPathr $options

    # psqlコマンドの実行結果を取得する
    RunSQLResult=$?
    echo

    return $RunSQLResult

}
