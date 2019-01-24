#!/bin/bash -xv

#***********************************************************************************
#* バッチ名：PostgreSqlToolを使用したサンプルシェル
#* 処理内容：更新前のDumpファイルを作成し、もし更新処理中にエラーが発生した場合は、
#*           更新前のDumpファイルからデータを元に戻す。
#*           ログファイル、Dumpファイルは「environment.ini」ファイルに指定された
#*          「ログファイルの削除日数」、「Dumpファイルの削除日数」設定を元にファイル
#*           を削除する
#* 使用方法：「sh sample.sh」で実行して下さい
#***********************************************************************************

#*****************************************************************************
#* 処 理 名：データベースを元に戻す
#* 引    数：$1 エラーコード
#*           $2 元に戻す対象のDumpファイル
#*           $3 ログファイル
#* 処理内容：引数で渡されたエラーコードが「0」以外の時、データベースを元に戻す
#*           ※エラーコードが0で無い時は処理が失敗した時です
#*****************************************************************************
RestoreDataBase()
{

    # 引数からエラーコード、Dumpファイル名を取得する
    errorCode=$1
    dumpFile=$2
    logFile=$3

    # エラーコードが「0」の時は処理を終了
    # ※エラーコードは正常に終了した時は「0」を返すため
    if [ $errorCode -eq 0 ]; then
        return 0
    fi

    echo                                                            >> ${logFile} 2>&1
    echo データベースの更新中にエラーが発生したため、元にもどします >> ${logFile} 2>&1
    echo                                                            >> ${logFile} 2>&1


    # スキーマーを削除し、Dumpファイルからデータベースを元に戻す
    DropSchema                                                      >> ${logFile} 2>&1
    RestoreDump "${dumpFile}"                                       >> ${logFile} 2>&1

    echo バッチの処理終了

    # シェルスクリプトの処理を終了
    exit 

}

# スクリプト開始時間を取得
startTime=`date +%s`

# シェルを実行したディレクトリに移動する
# このシェルがどこから呼び出されても正しく動作するようにするため
# ※$0は実行したシェルスクリプトのフルパスがセットされているため、$0を使用し
#   dirnameコマンドを使用するとこで実行したシェルスクリプトのディレクトリを知ることができます
cd `dirname $0`

# DBツールを読み込み
source ./01_PostgreSqlTool/PostgreSqlTool.sh "./00_environment/environment.ini"

# 実行時間を取得する
nowTime=$(date -d '9 hours' +%Y%m%d%H%M%S)

# ログファイル名を作成 ※sample_現在日付時刻.logの形式で作成されます
logFileName=./02_Log/sample_${nowTime}.log

# Dumpファイル名を作成 ※Export_現在日付時刻.SQLの形式で作成されます
exportDumpFileName=Export_${nowTime}.SQL

# すべてのtmpフォルダを削除する
DeleteFileInTmpFolder




# DB情報をログファイルに書き込む
WriteDbInfoToLogFile $logFileName

# ○日前より前のログファイルを削除する
# ※.iniファイルのログファイル削除日数設定で指定された日数から削除日数を指定する
echo                                                                                                     >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo ${LOGFILE_DELETE_DAYS_COUNT}日より前のログファイルを削除します                                      >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo                                                                                                     >> ${logFileName} 2>&1
find ./02_Log -name \*.log -mtime +${LOGFILE_DELETE_DAYS_COUNT} -exec ls -l {} \;                        >> ${logFileName} 2>&1
echo                                                                                                     >> ${logFileName} 2>&1
find ./02_Log -name \*.log -mtime +${LOGFILE_DELETE_DAYS_COUNT} -exec rm -f {} \;                        >> ${logFileName} 2>&1

# ○日前より前のDumpファイルを削除する
# ※.iniファイルのDumpファイル削除日数設定で指定された日数から削除日数を指定する
echo                                                                                                     >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo ${DUMPFILE_DELETE_DAYS_COUNT}日より前のDumpファイルを削除します                                     >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo                                                                                                     >> ${logFileName} 2>&1
find ./01_PostgreSqlTool/09_Dump -name \*Export* -mtime +${DUMPFILE_DELETE_DAYS_COUNT} -exec ls -l {} \; >> ${logFileName} 2>&1
echo                                                                                                     >> ${logFileName} 2>&1
find ./01_PostgreSqlTool/09_Dump -name \*Export* -mtime +${DUMPFILE_DELETE_DAYS_COUNT} -exec rm -f {} \; >> ${logFileName} 2>&1




echo                                                                                                     >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo 現在の状態のDumpファイルを作成する                                                                  >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo                                                                                                     >> ${logFileName} 2>&1

# バッチの実行前のDumpファイルを作成する
ExportDump "${exportDumpFileName}"                                                                       >> ${logFileName} 2>&1


# sample.SQLを実行する失敗した時はDumpファイルからデータを元に戻す
RunSQL "sample.SQL" "-t --set ON_ERROR_STOP=on"                                                          >> ${logFileName} 2>&1
RestoreDataBase "${?}" "${exportDumpFileName}" "${logFileName}"



# スクリプト終了時間を取得しスクリプトの処理時間を計算する
endTime=`date +%s`
processingTime=$((endTime - startTime))

# スクリプトの処理時間をログに出力
echo                                                                                                     >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo バッチ処理時間：${processingTime}                                                                   >> ${logFileName} 2>&1
echo -------------------------------------------------------------------                                 >> ${logFileName} 2>&1
echo                                                                                                     >> ${logFileName} 2>&1

echo バッチの処理終了
