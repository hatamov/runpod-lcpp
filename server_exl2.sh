#!/bin/bash
set -ex

./download.sh

cd /tabbyAPI
source /venv-exl2/bin/activate
python3 ./start.py --help
python3 ./main.py --config /repo/exl2-config.yml --port $S_EXL2_PORT --model-name "$EXL2_MODEL_NAME" 
