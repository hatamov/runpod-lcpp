#!/bin/bash
set -ex

echo "Environment variables:"
env

echo "Running processes:"
ps aux


export VOLUME_PATH="/runpod-volume"
export MODELS_DIR="$VOLUME_PATH/models"
mkdir -p $MODELS_DIR
tree -L 3 $VOLUME_PATH

echo "Volume path: $VOLUME_PATH"
du -hs $VOLUME_PATH

if [ -n "$CUSTOM_INIT_COMMAND" ]; then
    $CUSTOM_INIT_COMMAND
fi

exec python3 ./src/handler.py
