#!/bin/bash
set -ex
source ./env.sh

HFR="${HFR:-Zoyd/failspy_Phi-3-mini-4k-geminified-2_5bpw_exl2}"
HFF="${HFF:-}"
HFR_LOCAL_PATH="$MODELS_DIR/${HFR_LOCAL_PATH:-$HFR}"
./snapshot_download.py --repo_id "$HFR" --local_dir "$HFR_LOCAL_PATH" --allow_patterns "$HFF"

cd /tabbyAPI
source ./venv/bin/activate
python3 ./start.py --help
python3 ./main.py --config /repo/config-exl2.yml --port $S_EXL2_PORT --model-name "$MODEL" 
