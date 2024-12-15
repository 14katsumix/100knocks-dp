#!/bin/bash
set -e  # エラーが発生したらスクリプトを終了する

if [ "$1" == "dev" ]; then
    # 
    cp -f .gitignore-dev .gitignore
    echo "Switched to development .gitignore"
    # 
    git add -A
    git commit -m "commit"
    git remote set-url origin git@github.com:14katsumix/100knocks-dp-dev.git
    git remote -v
    git switch main
    git push -u origin main
    #
elif [ "$1" == "pub" ]; then
    # 
    cp -f .gitignore-pub .gitignore
    echo "Switched to public .gitignore"
    # 
    git remote set-url origin git@github.com:14katsumix/100knocks-dp.git
    git remote -v
    git switch main
    git push -u origin main
    # 
    git remote set-url origin git@github.com:14katsumix/100knocks-dp-dev.git
    git remote -v
    cp -f .gitignore-dev .gitignore
    echo "Switched to development .gitignore"
    # 
else
    echo "Usage: $0 [dev|pub]"
fi
