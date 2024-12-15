#!/bin/bash
set -e  # エラーが発生したらスクリプトを終了する

git remote set-url origin git@github.com:14katsumix/100knocks-dp.git
git remote -v
\cp -f .gitignore-pub .gitignore
git rm -r --cached .
git status

git add -A
git commit -m "commit"
git push -u origin main

git remote set-url origin git@github.com:14katsumix/100knocks-dp-dev.git
\cp -f .gitignore-dev .gitignore
