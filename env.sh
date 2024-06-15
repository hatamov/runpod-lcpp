export S_LCPP_CMD="./server_lcpp.sh"
export S_LCPP_PORT=8001

export S_EXL2_CMD="./server_exl2.sh"
export S_EXL2_PORT=8002

export S_VLLM_CMD="./server_vllm.sh"
export S_VLLM_PORT=8003

export VOLUME_PATH="/runpod-volume"
export MODELS_DIR="$VOLUME_PATH/models"

# GUFF
export DL_REPO_ID="microsoft/Phi-3-mini-4k-instruct-gguf"
export DL_REVISION=""
export DL_ALLOW_PATTERNS="Phi-3-mini-4k-instruct-q4.gguf"

# EXL2
export DL_REPO_ID="bartowski/Phi-3-mini-4k-instruct-exl2"
export DL_REVISION="refs/heads/4_25"
export DL_ALLOW_PATTERNS=""

# GPTQ
export DL_REPO_ID="kaitchup/Phi-3-mini-4k-instruct-gptq-4bit"
export DL_REVISION=""
export DL_ALLOW_PATTERNS=""

export SHOULD_DOWNLOAD=0
export HF_HUB_ENABLE_HF_TRANSFER=0

# Initial server "lcpp", "vllm" or "exl2"
export INITIAL_SERVER="lcpp"
export START_SEVER_ON_BOOT=0

export LLCP_MODEL_PATH="/runpod-volume/models/microsoft--Phi-3-mini-4k-instruct-gguf/Phi-3-mini-4k-instruct-q4.gguf"
export VLLM_MODEL_PATH="/runpod-volume/models/kaitchup--Phi-3-mini-4k-instruct-gptq-4bit"
export EXL2_MODEL_NAME="bartowski--Phi-3-mini-4k-instruct-exl2"
