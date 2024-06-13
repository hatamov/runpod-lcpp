#!/bin/bash
set -ex

UPSTREAM_REPO_DEFAULT="https://github.com/hatamov/runpod-lcpp.git"
UPSTREAM_REPO="${UPSTREAM_REPO:-$UPSTREAM_REPO_DEFAULT}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"

git remote set-url origin "$UPSTREAM_REPO"
git fetch origin "$UPSTREAM_BRANCH"
git reset --hard "origin/$UPSTREAM_BRANCH"

exec ./start.sh
