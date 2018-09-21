#!/bin/bash

#*****************************************************************************
#* バッチ名：PostgreSQLのデータベースにdumpファイルをImportする
#* 処理内容：dumpファイルをImportする前後に特定のSQLファイルを実行できる
#*           設定ファイル：import.conf
#*****************************************************************************

# 設定ファイルの読み込み
. ./import.conf

#-------------------------------------- 関数群 --------------------------------------
#*****************************************************************************
#* 処 理 名：ファイルが存在するか
#* 引    数：$1 存在を確認するファイル
#* 処理内容：ファイルの存在を確認しファイルが存在しなかった時はファイル作成する
#*****************************************************************************
IsExistsFile() {

    # 引数からファイル名を取得
    targetFile=$1

    # ファイルが存在しなかったらファイルを作成する
    if [ ! -d ${targetFile} ]; then
        echo "ファイル[$targetFile]を作成しました"
        touch $targetFile
    fi

}

#*****************************************************************************
#* 処 理 名：ログに書き込む
#* 引    数：$1 ログに書き込む内容
#* 処理内容：ログファイルにログを書き込む
#*           ログの書き込まれる形式は「[9999/99/99-99:99:99] 書き込まれる内容」
#*           になります
#*****************************************************************************
WriteLog() {

    # 引数からログに書き込む内容とログファイルを取得
    writeContent=$1
    logFile=$2

    # コンソールとログファイルに書き込む
    echo [$(date -d '9 hours' +%Y/%m/%d-%H:%M:%S)] $writeContent
    echo [$(date -d '9 hours' +%Y/%m/%d-%H:%M:%S)] $writeContent >> $logFile

}

#*****************************************************************************
#* 処 理 名：実行前処理
#* 引    数：$1 ログファイル
#*           $2 処理内容
#*           $3 対象のフォルダ
#*           $4 実行するファイルのリスト
#* 処理内容：データーベースに対して処理を実行する前の処理（tmpフォルダ内のファ
#*           イルの削除、実行するファイルの一覧をリストに出力）
#*****************************************************************************
BeforeProcess() {

    logFile=$1
    processName=$2
    targetFolder=$3
    listFile=$4

    echo
    WriteLog "$processNameの実行" $logFile

    # tmpフォルダ内を全て削除する
    WriteLog "tmpフォルダの削除" $logFile
    rm -f $targetFolder/tmp/*

    # 対象フォルダのSQLファイルの一覧をテキストに出力
    WriteLog "実行するファイルの一覧をテキストに出力" $logFile
    ls $targetFolder/ | grep -E .sql > $listFile

}

#*****************************************************************************
#* 処 理 名：実行後処理
#* 引    数：$1 処理内容
#* 処理内容：データーベースに対して処理を実行後の処理
#*****************************************************************************
AfterProcess() {

    processName=$1
    WriteLog "$processNameの終了" $logFile

}

#*****************************************************************************
#* 処 理 名：Import前処理の実行
#* 引    数：$1 実行するファイルリスト
#*           $2 対象となるフォルダ
#* 処理内容：DumpのImport前の処理を行う。対象となるフォルダ内にあるSQLファイル
#*           分処理を実行する
#*****************************************************************************
RunBeforeImport() {

    fileList=$1
    targetFolder=$2

    # 実行するファイルリストごとSQLファイルの実行を行う
    cat $fileList |\
    while read list ;do

        # 読み込みファイルと実行用のファイルのパスを取得
        readSqlFile=$targetFolder/${list}
        runSqlFile=$targetFolder/tmp/${list}

        # tmpフォルダに実行用のSQLファイルを作成
        # 文字列置換前のSQLファイルを作成した後、文字列を置換して実行用のSQLファイルを作成
        cat $readSqlFile >> $runSqlFile
        sed -i -e 's/__DATABASE_NAME__/'$databaseName'/g'\
               -e 's/__ROLE_NAME__/'$databaseRoleName'/g' $runSqlFile

        # 作成したSQLファイルを実行
        # ※2>&1：標準出力、標準エラーをログファイルに出力
        WriteLog ''$runSqlFile'を実行開始' $logFile
        psql -h $databaseServer -U $databaseLoginUser -f $runSqlFile 2>&1 >> $logFile
        WriteLog ''$runSqlFile'の実行終了' $logFile

    done

}

#*****************************************************************************
#* 処 理 名：Import後処理の実行
#* 引    数：$1 実行するファイルリスト
#*           $2 対象となるフォルダ
#* 処理内容：DumpのImport後の処理を行う。対象となるフォルダ内にあるSQLファイル
#*           分処理を実行する
#*****************************************************************************
RunImport() {

    fileList=$1

    cat $fileList |\
    while read list ;do

        # 読み込みファイルと実行用のファイルのパスを取得
        readSqlFile=$dumpFolder/${list}

        # DumpファイルのImport処理の実行
        # ※2>&1：標準出力、標準エラーをログファイルに出力
        WriteLog 'DumpファイルのImportを実行（'$readSqlFile'を実行開始）' $logFile
        psql -h $databaseServer -U $databaseLoginUser -d $databaseName < $readSqlFile 2>&1 >> $logFile
        WriteLog 'DumpファイルのImportを実行（'$readSqlFile'を実行終了）' $logFile

    done

}

#*****************************************************************************
#* 処 理 名：Import後処理の実行
#* 引    数：$1 実行するファイルリスト
#*           $2 対象となるフォルダ
#* 処理内容：DumpのImport後の処理を行う。対象となるフォルダ内にあるSQLファイル
#*           分処理を実行する
#*****************************************************************************
RunAfterImport() {

    fileList=$1
    targetFolder=$2

    # 実行するファイルリストごとSQLファイルの実行を行う
    cat $fileList |\
    while read list ;do

        # 読み込みファイルと実行用のファイルのパスを取得
        readSqlFile=$targetFolder/${list}
        runSqlFile=$targetFolder/tmp/${list}

        # tmpフォルダに実行用のSQLファイルを作成
        # 文字列置換前のSQLファイルを作成した後、文字列を置換して実行用のSQLファイルを作成
        cat $readSqlFile >> $runSqlFile
        sed -i -e 's/__DATABASE_NAME__/'$databaseName'/g' $runSqlFile

        # 作成したSQLファイルを実行
        # ※2>&1：標準出力、標準エラーをログファイルに出力
        psql -h $databaseServer -U $databaseLoginUser -f $runSqlFile 2>&1 >> $logFile

    done

}

#------------------------------------ メイン処理 ------------------------------------

#-------------------------------------
# ログファイの作成
#-------------------------------------
# ログファイル名を取得（実行時間.logの形式で作成）
logFile=$(date -d '9 hours' +%Y%m%d%H%M%S).log

# 既存のログファイルを削除
find ./ -name "*.log" | xargs rm

# ログファイルを新規に作成
WriteLog "ログファイルを作成" $logFile
IsExistsFile $logFile

#-------------------------------------
# DumpファイルのImport前処理
#-------------------------------------
# DumpファイルのImport前処理で実行するSQLのリストファイルを取得
initialFileList=$initialFolder/tmp/$initialFolder.list

# Import前処理の前処理を実行
BeforeProcess $logFile "DumpファイルImport前処理" $initialFolder $initialFileList

# Import前処理の実行
RunBeforeImport $initialFileList $initialFolder

# Import前処理の後処理を実行
AfterProcess "DumpファイルImport前処理"

#-------------------------------------
# DumpファイルのImport処理
#-------------------------------------
# DumpファイルのImport前処理で実行するSQLのリストファイルを取得
dumpFileList=$dumpFolder/tmp/$dumpFolder.list

# Import処理の前処理を実行
BeforeProcess $logFile "DumpファイルImport処理" $dumpFolder $dumpFileList

# DumpファイルのImport処理を実行
RunImport $dumpFileList

# Import処理の後処理を実行
AfterProcess "DumpファイルImport処理"

#-------------------------------------
# DumpファイルのImport後処理
#-------------------------------------
# DumpファイルのImport後処理で実行するSQLのリストファイルを取得
LastFileList=$lastFolder/tmp/$lastFolder.list

# Import後処理の前処理を実行
BeforeProcess $logFile "DumpファイルImport後処理" $lastFolder $LastFileList

# Import後処理を実行
RunBeforeImport $LastFileList $lastFolder

# Import後処理の後処理を実行
AfterProcess "DumpファイルImport後処理"
