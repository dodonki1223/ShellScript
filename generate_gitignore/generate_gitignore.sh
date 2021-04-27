#!/bin/sh

#***********************************************************************************
#* バッチ名：.gitignore ファイル自動生成ツール
#* 処理内容：gitignore.io の API を使用し入力されたプロジェクトの .gitignore ファイル
#*           を自動で生成するツールです
#*           gitignore.io：https://www.toptal.com/developers/gitignore
#* 使用方法：sh generate_gitignore.sh を実行する
#*           wget コマンドがインストールされていない場合は使用できません
#***********************************************************************************
# wget コマンドの存在チェック
type wget > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "You will need to install the wget command"
    echo "Run brew install wget"
    exit 1
fi

# 対象のプロジェクト入力しカレントディレクトリに .gitignore ファイルを自動生成する
echo "Entering list will print out a gitignore supported list"
read -p "What .gitignore file do you want to generate?: " project

# list が指定された場合は対応している .gitignore の一覧を出力する
# ただし、peco がインストールされている場合は絞り込み機能を持った状態で一覧を出力する
# list 以外はそのまま .gitignore ファイルを作成する
if [ $project = "list" ]; then
  type peco > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    wget https://www.toptal.com/developers/gitignore/api/$project -O -
  else
    wget https://www.toptal.com/developers/gitignore/api/$project -O - | peco
  fi
else
    wget https://www.toptal.com/developers/gitignore/api/$project -O - > .gitignore
    echo ".gitignore file generated($PWD/.gitignore)"
fi
