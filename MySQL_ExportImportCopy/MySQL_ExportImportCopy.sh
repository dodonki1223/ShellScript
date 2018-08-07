#!/bin/sh

#*****************************************************************************
#* バッチ名：既存のデータベースの内容を別のデータベースにコピーする
#* 処理内容：既存のデータベースからDumpファイルを作成し、そのDumpファイルから
#*           別のデータベース（存在しなければ作成する）にインポートします
#*****************************************************************************

#------------------------------------ メソッド郡 ------------------------------------
#*****************************************************************************
#* 処 理 名：スクリプトの終了処理
#* 引    数：なし
#* 処理内容：終了時に行う処理です
#*****************************************************************************
End () {
    echo
    echo 処理を終了します......
    echo
}

#*****************************************************************************
#* 処 理 名：データベースのエクスポート処理
#* 引    数：データベースサーバー名
#*           データベースログインユーザー名
#*           データベースログインパスワード
#*           コピーDMPファイル名
#* 処理内容：データベースからdumpファイルを作成します
#*****************************************************************************
ExportProcess () {

    #引数の受け取り
    DatabaseServer=$1
    DatabaseLoginUser=$2
    DatabaseLoginPassword=$3
    DumpFileName=$4_dump.sql
    SchemaName=$4

    #Dumpファイルの作成処理
    echo
    echo 「$DumpFileName」ファイルの作成を開始します
    mysqldump -u $DatabaseLoginUser -p$DatabaseLoginPassword -h $DatabaseServer $SchemaName > $DumpFileName
    #作成処理成功のメッセージを表示
    echo
    echo 「$DumpFileName」ファイルの作成処理に成功

}

#*****************************************************************************
#* 処 理 名：データベースへのインポート処理
#* 引    数：データベースログインユーザー名
#*           データベースログインパスワード
#*           インポート先データベース名
#*           コピーDMPファイル名
#* 処理内容：dumpファイルからインポート先データベースへデータをセット
#*           インポート先データベースが存在しない時はデータベースを作成する
#*****************************************************************************
ImportProcess () {

    #引数の受け取り
    DatabaseLoginUser=$1
    DatabaseLoginPassword=$2
    DumpFileName=$3_dump.sql
    SchemaName=$4

    #インポート先のデータベースを作成 ※存在しなかったら作成する
    echo
    echo インポート先データベースが存在しなかったら作成します
    echo
    RunSql="CREATE DATABASE IF NOT EXISTS "$SchemaName";"
    echo "$RunSql" | mysql -u $DatabaseLoginUser -p$DatabaseLoginPassword

    #インポート処理の実行
    echo
    echo DUMPファイルからインポート先へデータをインポートします
    mysql -u $DatabaseLoginUser -p$DatabaseLoginPassword $SchemaName < $DumpFileName

    #インポート後のメッセージを表示
    echo
    echo 「$SchemaName」へインポート処理が終了しました
}

#--------------------------------------- 設定 ---------------------------------------
#データベースにログインするサーバー名
DatabaseServer=localhost
#データベースにログインするユーザー名
DatabaseLoginUser=root
#バックアップ対象のデータベース名設定 ※無くても良い
DefaultCopyDatabaseName=fukully
#インポート対象データベース名設定     ※無くても良い
DefaultImportDatabaseName=fukully_test
#------------------------------------ メイン処理 ------------------------------------

#-------------------------------------
#  タイトルの表示処理
#-------------------------------------
echo
echo ---------------------------------------------------------------------------
echo タイトル：既存のデータベースの内容を別のデータベースにコピーする
echo 処理内容：既存のデータベースからDumpファイルを作成し、そのDumpファイルから
echo 　　　　　別のデータベース（存在しなければ作成する）にインポートします
echo ---------------------------------------------------------------------------
echo

#-------------------------------------
#  エクスポート、インポート情報の入力
#-------------------------------------
#ユーザーから対話でデータベース名を入力してもらう
echo
CopyDatabaseName=""
echo -n コピー対象のデータベース名を入力して下さい（デフォルト値は「$DefaultCopyDatabaseName」）: 
read CopyDatabaseName

#ユーザーから入力してもらった値が空の時はデフォルトのコピー対象データベース名をセットする
if [ "${CopyDatabaseName}" = "" ]; then
    CopyDatabaseName=$DefaultCopyDatabaseName
fi

#ユーザーから対話でインポート先データベース名を入力してもらう
echo
ImportDatabaseName=""
echo -n インポート先データベース名を入力して下さい（デフォルト値は「$DefaultImportDatabaseName」）: 
read ImportDatabaseName

#ユーザーから入力してもらった値が空の時はデフォルトのインポート対象データベース名をセットする
if [ "${ImportDatabaseName}" = "" ]; then
    ImportDatabaseName=$DefaultImportDatabaseName
fi

#-------------------------------------
#  入力情報の表示
#-------------------------------------
echo
echo エクスポート：$CopyDatabaseName
echo インポート　：$ImportDatabaseName
echo 「$CopyDatabaseName」→「$ImportDatabaseName」
echo
echo -n 上記設定でエクスポート、インポートを実行してもよろしいですか[y/n]？：
read RunAnswer
echo

#-------------------------------------
#  処理の続行有無をユーザーに確認
#-------------------------------------
case $RunAnswer in
    "" | "Y" | "y") 
        echo -n データベースへログインするためのパスワードを入力して下さい：
        read DatabaseLoginPassword
        ExportProcess $DatabaseServer $DatabaseLoginUser $DatabaseLoginPassword $CopyDatabaseName
        ImportProcess $DatabaseLoginUser $DatabaseLoginPassword $CopyDatabaseName $ImportDatabaseName
        End
        ;;
    * ) 
        #終了処理を実行
        End;;
esac
