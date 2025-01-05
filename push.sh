#!/bin/bash
set -e  # エラーが発生したらスクリプトを終了する

if [ "$1" == "dev" ]; then
    # 
    \cp -pf .gitignore-dev .gitignore
    sleep 3s
    echo "Switched to development .gitignore"
    # 
    git remote set-url origin git@github.com:14katsumix/100knocks-dp-dev.git
    git remote -v
    git switch main
    git add -A
    git commit -m "commit"
    git push -u origin main
    #
elif [ "$1" == "pub" ]; then
    # 
    \cp -pf .gitignore-pub .gitignore
    sleep 6s
    echo "Switched to public .gitignore"
    # 
    git remote set-url origin git@github.com:14katsumix/100knocks-dp.git
    git remote -v
    git switch main
    git add -A
    git commit -m "commit"
    git push -u origin main
    # 
    \cp -pf .gitignore-dev .gitignore
    echo "Switched to development .gitignore"
    git remote set-url origin git@github.com:14katsumix/100knocks-dp-dev.git
    git remote -v
    # 
else
    echo "Usage: $0 [dev|pub]"
fi
