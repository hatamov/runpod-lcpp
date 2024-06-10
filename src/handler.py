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
import json


class LlamaCPPEngine:
    def __init__(self, start_server=True):
        self.start_server = start_server
        self.server_proc = None
        self.initialize_llama_cpp_server()

    def get_server_cmd(self):
        command_line = os.getenv("LCPP_CMD")
        if command_line:
            return command_line
        
        port = self.get_server_port()
        base_args = f"/llama-cpp-server --host 127.0.0.1 --port {port}"
        other_args = os.getenv("LCPP_ARGS", "-m /models/Phi-3-mini-4k-instruct-q4.gguf")
        return f"{base_args} {other_args}"


    def initialize_llama_cpp_server(self):
        if not self.start_server:
            return

        command_line = self.get_server_cmd()
        logging.info(f"Starting server with command: {command_line}")

        args = shlex.split(command_line)
        self.server_proc = subprocess.Popen(args)

        if self.server_proc.poll() is not None:
            raise Exception(f"Failed to start server")

        self.wait_until_server_ready()

    
    def wait_until_server_ready(self):
        max_wait = int(os.getenv("LCPP_INIT_TIMEOUT", 120))
        logging.info("Waiting for server to start...")

        elapsed = 0
        check_interval = 0.5
        while self.get_server_status() != 200:
            time.sleep(check_interval)
            elapsed += check_interval

            if elapsed % 5 == 0:
                logging.info(f"Server not ready after {elapsed} seconds")

            if elapsed >= max_wait:
                raise Exception("Server failed to start")
        
        logging.info("Server is ready.")
    
    
    def stop_llama_cpp_server(self):
        if self.server_proc is None:
            return
        self.server_proc.terminate()
        self.server_proc.wait()

    def get_server_port(self):
        return os.getenv("LCPP_PORT", 1515)
    
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

        url = self.get_server_base_url() + job_input.get("openai_route")
        data = job_input.get("openai_input")
        logging.info(f"Sending request to {url} with data: {data}")

        method = "GET"
        if 'completion' in url:
            method = "POST"

        is_stream = data.get("stream")

        async with aiohttp.ClientSession() as session:
            async with session.request(method, url, json=data) as response:
                logging.info(f"Received response: {response}, {response.status}")
                logging.info(f"Headers: {response.headers}")

                if response.status != 200:
                    yield await parse_as_json(response)
                    return

                if is_stream:
                    async for chunk, _ in response.content.iter_chunks():
                        yield chunk.decode("utf-8")
                else:
                    resp_json = await response.json()
                    yield resp_json


async def parse_as_json(response):
    try:
        return await response.json()
    except Exception as e:
        logging.error(f"Error getting response as json: {e}")
    
    try:
        return await response.text()
    except Exception as e:
        logging.error(f"Error getting response as text: {e}")

    return f"Error parsing response object: {response}"

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
    engine.start_server = True
    runpod.serverless.start(
        {
            "handler": handler,
            "concurrency_modifier": lambda x: int(os.getenv("MAX_CONCURRENCY", 10)),
            "return_aggregate_stream": True,
        }
    )


def test():
    engine.start_server = False

    async def invoke_handler():
        print("Invoking handler")
        job = {
            "input": {
                "openai_route": "/v1/completions",
                "openai_input": {
                    "model": "gpt-2",
                    "prompt": "Once upon a time",
                    # "max_tokens": 50
                    "stream": True,
                    "n_predict": 20
                }
            }
        }

        async for chunk in handler(job):
            print(chunk)

    loop = asyncio.get_event_loop()
    loop.run_until_complete(invoke_handler())


# test()
run()
