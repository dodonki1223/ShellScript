#!/bin/bash

#***********************************************************************************
#* バッチ名：ssh接続ツール
#* 処理内容：接続先設定ファイルを読み込み、その内容を画面に表示しどの環境に接続するか
#*           ユーザーに対話し接続先を指定するツール
#* 使用方法：このシェルスクリプトと同階層にあるserver_connection_info.confのファイル
#*           にサーバーの接続先情報を設定して下さい
#*           設定ファイルにはカンマ区切りで下記のように設定して下さい
#*             環境名,sshキーファイルの場所,サーバー情報(「ユーザー名@IPアドレス」形式)
#***********************************************************************************

# このシェルスクリプトの実行パスを取得する
scriptPath=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

# 接続先設定ファイル
connection_setting=$scriptPath/server_connection.conf

#*****************************************************************************
#* 処 理 名：接続先の環境選択処理
#* 引    数：なし
#* 処理内容：不正な値を入力した時は、エラーを表示
#*           targetNumber変数に対象の環境番号をセットする
#*           ※接続先設定ファイルで読み込んだ環境ごとに番号を１から割り振って
#*             あり、その内容を元に入力された番号が存在するかチェックする
#*           ※$targetNumber、$numbersはグローバル変数です
#*****************************************************************************
inputEnvironmentNumber()
{
    read -p "接続したい環境の番号を入力して下さい: " targetNumber
    isExistsNumber ${numbers[*]}
    result=$?
    echo
    return $result
}

#*****************************************************************************
#* 処 理 名：入力された番号が存在するか
#* 引    数：特になし
#* 処理内容：画面で入力された番号が存在するかどうかチェックする
#*           存在する場合は1を返し、存在しない場合はメッセージを表示し0を返す
#*           ※$targetNumber、$numbersはグローバル変数です
#*****************************************************************************
isExistsNumber()
{

    # 入力された値が空文字の時は入力値が不正と判断する
    if [ -z "${targetNumber}" ]; then
        echo "入力値が不正です。正しい値を入力して下さい！！"
        return 0
    fi

    # 配列内に対象の番号があるかどうかチェック
    for number in ${numbers[*]}
    do
        if  [ $number = $targetNumber ]; then
            return 1
        fi
    done

    # 配列内に対象の番号が存在しなかった時
    echo "入力値が不正です。正しい値を入力して下さい！！"
    return 0
}

# タイトルの表示
echo -----------------------------------------------------------
echo \<ssh接続ツール\>
echo 接続先のサーバーの一覧が表示されるので、接続したいサーバー
echo の番号を入力して下さい。入力した番号のサーバーにssh接続しま
echo す。サーバーのリストを編集したい時はserver_connection.conf
echo を修正して下さい。
echo -----------------------------------------------------------

# 接続先設定ファイルの読み込み処理
# ※それぞれ配列にセットする
numbers=(`awk -F'[,]' '{print NR}' "${connection_setting}"`)
environments=(`awk -F'[,]' '{print $1}' "${connection_setting}"`)
sshkeys=(`awk -F'[,]' '{print $2}' "${connection_setting}"`)
servers=(`awk -F'[,]' '{print $3}' "${connection_setting}"`)

# 接続先の環境の一覧を画面に表示
echo
echo \<接続先環境の一覧\>
environmentCount=0
for environment in ${environments[*]}
do
    echo ${numbers[$environmentCount]}：$environment
    environmentCount=$((environmentCount+1))
done

# 接続先環境の入力処理
echo
inputEnvironmentNumber
result=$?
while [ $result = 0 ]
do
    inputEnvironmentNumber
    result=$?
done

# 配列と一致させるために添え字の番号を調節
targetSubscript=$(($targetNumber-1))
echo ---------------------------------------------
echo \<接続先情報\>
echo 接続先名　　　：${environments[$targetSubscript]}
echo ＳＳＨキー情報：${sshkeys[$targetSubscript]}
echo サーバー情報　：${servers[$targetSubscript]}
echo ---------------------------------------------
echo

# 処理を続行するかユーザーに確認
echo 上記のサーバーへ下記のコマンドを実行して接続します。よろしいですか？
echo ssh -i ${sshkeys[$targetSubscript]} ${servers[$targetSubscript]}
echo
echo 「Enter」キーを押すとそのまま処理が続行されます
echo 処理をやめる時はCtrl+Cで終了して下さい……
echo
read -p "Hit enter: "
echo

# サーバー接続処理の実行
ssh -i ${sshkeys[$targetSubscript]} ${servers[$targetSubscript]}
