import os
import runpod
import logging
import shlex
import subprocess
import aiohttp
import atexit
import asyncio
import requests
import time

class LlamaCPPEngine:
    def __init__(self):
        self.server_proc = None
        self.initialize_llama_cpp_server()

    def get_server_cmd(self):
        command_line = os.getenv("LLAMA_CPP_SERVER_CMD")
        if command_line:
            return command_line
        
        port = self.get_server_port()
        base_args = f"/llama-cpp-server --host 127.0.0.1 --port {port}"
        other_args = os.getenv("LLAMA_CPP_SERVER_ARGS", "-m /models/Phi-3-mini-4k-instruct-q4.gguf")
        return f"{base_args} {other_args}"


    def initialize_llama_cpp_server(self):
        command_line = self.get_server_cmd()
        logging.info(f"Starting server with command: {command_line}")

        args = shlex.split(command_line)
        self.server_proc = subprocess.Popen(args)

        if self.server_proc.poll() is not None:
            raise Exception(f"Failed to start server with command: {command_line}")
        
        max_wait = int(os.getenv("LLAMA_CPP_SERVER_START_TIMEOUT", 30))
        while self.get_server_status() != 200:
            logging.info("Waiting for server to start...")
            time.sleep(1)
            max_wait -= 1
            if max_wait <= 0:
                raise Exception("Server failed to start")
        
        logging.info("Server started successfully")
    
    
    def stop_llama_cpp_server(self):
        if self.server_proc is None:
            return
        self.server_proc.terminate()
        self.server_proc.wait()

    def get_server_port(self):
        return os.getenv("LLAMA_CPP_SERVER_PORT", 1515)
    
    def get_server_base_url(self):
        return f"http://localhost:{self.get_server_port()}"

    def get_server_status(self):
        url = self.get_server_base_url() + "/health"
        logging.info(f"Checking server health at {url}")
        timeout_sec = 1

        try:
            response = requests.get(url, timeout=timeout_sec)
        except Exception as e:
            logging.error(f"Error checking server health: {e}")
            return 500

        logging.info(f"Server health response: {response.status_code}: {response.text}")
        return response.status_code

    async def process(self, job):
        job_input = job["input"]
        # job_input.get("openai_route")
        # job_input.get("openai_input")

        url = self.get_server_base_url() + job_input.get("openai_route")
        data = job_input.get("openai_input")
        logging.info(f"Sending request to {url} with data: {data}")

        method = "GET"
        if 'completion' in url:
            method = "POST"

        async with aiohttp.ClientSession() as session:
            async with session.request(method, url, json=data) as response:
                # print(f"Status: {response.status}")
                # print(f"Content-type: {response.headers['content-type']}")
                logging.info(f"Received response: {response}")

                # Asynchronously stream the response
                async for chunk in response.content.iter_any():
                    # print(chunk)
                    # logging.info(f"Received chunk: {chunk}")
                    yield str(chunk)

def change_dir():
    current_dir = os.getcwd()
    logging.info(f"Current directory: {current_dir}")
    cddir = os.getenv("CUSTOM_CWD")
    if cddir:
        os.chdir(cddir)
        logging.info(f"Changed directory to: {cddir}")

change_dir()

engine = LlamaCPPEngine()

def cleanup_process():
    logging.info("Stopping llama cpp server in clean")
    engine.stop_llama_cpp_server()

atexit.register(cleanup_process)


async def handler(job):
    results_generator = engine.process(job)
    async for batch in results_generator:
        yield batch


def run():
    if os.getenv("WARMUP_ONLY"):
        logging.info(f"WARMUP_ONLY mode, exiting.")
        return
        
    runpod.serverless.start(
        {
            "handler": handler,
            "concurrency_modifier": lambda x: int(os.getenv("MAX_CONCURRENCY", 10)),
            "return_aggregate_stream": True,
        }
    )

run()

# async def invoke_handler():
#     print("Invoking handler")
#     job = {
#         "input": {
#             "openai_route": "/v1/completions",
#             "openai_input": {
#                 "model": "gpt-2",
#                 "prompt": "Once upon a time",
#                 # "max_tokens": 50
#                 "stream": True,
#                 "n_predict": 20
#             }
#         }
#     }

#     async for chunk in handler(job):
#         print(chunk)

# loop = asyncio.get_event_loop()
# loop.run_until_complete(invoke_handler())

# python3 /src/handler.py  --rp_serve_api --rp_api_host='0.0.0.0'
# --test_input '{"input": {"openai_route": "/v1/completions", "openai_input": { "prompt": "Once upon a time",  "n_predict": 20, "stream": true} }'

"""
python3 /src/handler.py  --rp_serve_api --rp_api_host='0.0.0.0'

curl -X POST http://localhost:8000/runsync \
    -H "Content-Type: application/json" \
    --data '{"input":{"openai_route": "/v1/completions", "openai_input":{"prompt": "Once upon a time",  "n_predict": 20, "stream":true}}}'
"""