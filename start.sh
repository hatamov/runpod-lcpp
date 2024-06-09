#!/bin/bash
set -ex
git pull origin_https master -f
exec python3 ./src/handler.py
