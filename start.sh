#!/bin/bash
set -ex
source ./env.sh

echo "Environment variables:"
env

echo "Running processes:"
ps aux

tree -h -L 3 $VOLUME_PATH
du -hs $VOLUME_PATH

if [ -n "$CUSTOM_INIT_COMMAND" ]; then
    $CUSTOM_INIT_COMMAND
fi

exec python3 ./src/handler.py
