export EXL2_CONFIG="
# https://github.com/theroyallab/tabbyAPI/blob/main/config_sample.yml
network:
  host: 127.0.0.1
  port: 8002
  disable_auth: True

logging:
  prompt: False
  generation_params: False

model:
  model_dir: $MODELS_DIR
  model_name: $EXL2_MODEL_NAME
  cache_mode: Q8
"

echo -e "$EXL2_CONFIG" > ./exl2-config.yml
echo -e "$EXL2_CONFIG" > /tabbyAPI/config.yml