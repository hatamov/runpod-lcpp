#!/bin/bash
set -ex

git fetch origin master
git reset --hard origin/master

exec /repo/start.sh