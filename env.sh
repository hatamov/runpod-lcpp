export S_LCPP_CMD="./server_lcpp.sh"
export S_LCPP_PORT=8001

export S_EXL2_CMD="./server_exl2.sh"
export S_EXL2_PORT=8002

export S_VLLM_CMD="./server_vllm.sh"
export S_VLLM_PORT=8003

export VOLUME_PATH="/runpod-volume"
export MODELS_DIR="$VOLUME_PATH/models"

export HF_HUB_ENABLE_HF_TRANSFER=0

export LD_LIBRARY_PATH="/usr/local/cuda-12.1/compat:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib"

export SKIP_DOWNLOAD=1

export MODEL_FILE="main.guff"
# export INITIAL_SERVER="vllm"
export INITIAL_SERVER="lcpp"
