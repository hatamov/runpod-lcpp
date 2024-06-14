#!/bin/bash
set -ex

echo "Environment variables:"
env

echo "Running processes:"
ps aux

# apt-get install -y libcublas-12-1
export LD_LIBRARY_PATH="/usr/local/cuda-12.1/compat:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib"

export VOLUME_PATH="/runpod-volume"
export MODELS_DIR="$VOLUME_PATH/models"
mkdir -p $MODELS_DIR
tree -h -L 3 $VOLUME_PATH

echo "Volume path: $VOLUME_PATH"
du -h -d 2 $VOLUME_PATH

if [ -n "$CUSTOM_INIT_COMMAND" ]; then
    $CUSTOM_INIT_COMMAND
fi

export INITIAL_SERVER="LCPP"
# export INITIAL_SERVER="EXL2"
export S_LCPP_CMD="./server_lcpp.sh"
export S_EXL2_CMD="./server_exl2.sh"
exec python3 ./src/handler.py
