#!/bin/bash
set -ex

git git remote set-url origin https://github.com/hatamov/runpod-lcpp.git
git fetch origin master
git reset --hard origin/master

exec /repo/start.sh