## TODO


Some snippets for testing

```
python3 /src/handler.py  --rp_serve_api --rp_api_host='0.0.0.0'

curl -X POST http://localhost:8000/runsync \
    -H "Content-Type: application/json" \
    --data '{"input":{"openai_route": "/v1/completions", "openai_input":{"prompt": "Once upon a time",  "n_predict": 20, "stream":true}}}'

```