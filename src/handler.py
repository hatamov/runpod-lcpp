import os
import sys
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

running_servers = []
def cleanup_process():
    logging.info("Stopping llama cpp server in clean")
    for src in running_servers:
        src.stop()

atexit.register(cleanup_process)

class LLMServer:
    def __init__(self, name):
        self.name = name
        self.server_proc = None
        self.ready = False

    def start(self):
        cmd = os.environ.get(f"S_{self.name}_CMD", "echo 'No command provided'")
        logging.info(f"Starting server {self.name} with command: {cmd}")

        args = shlex.split(cmd)
        self.server_proc = subprocess.Popen(args)

        if self.server_proc.poll() is not None:
            raise Exception(f"Failed to start server")
        
        running_servers.append(self)

    def wait_until_ready(self, timeout=None):
        logging.info("Waiting for server {self.name} to be ready")

        if timeout is None:
            timeout = int(os.environ("S_WAIT_TIMEOUT", 120))

        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = self.call_v1_models()
                response.raise_for_status()  # Raises an HTTPError if the HTTP request returned an unsuccessful status code
            except requests.exceptions.ConnectionError:
                pass
            except requests.exceptions.HTTPError as http_err:
                logging.info(f"wait_until_ready: HTTP error occurred: {http_err}")
                return False
            except Exception as err:
                logging.info(f"wait_until_ready: An error occurred: {err}")
                return False
            else:
                logging.info("wait_until_ready: Server is ready")
                self.ready = True
                return True
            
            if time.time() % 5 == 0:
                logging.info(f"wait_until_ready: Not after {time.time() - start_time} seconds")

            time.sleep(1)

        logging.error(f"Server failed to start server {self.name} after {timeout} seconds")
        return False

    def stop(self):
        logging.info(f"Stopping server {self.name}")
        if self.server_proc:
            self.server_proc.terminate()
            self.server_proc.wait()
            running_servers.remove(self)

    def get_port(self):
        return os.getenv("S_{self.name}_PORT", 1515)
    
    def get_base_url(self):
        return f"http://localhost:{self.get_port()}"

    def call_v1_models(self, timeout=0.5):
        url = self.get_base_url() + "/v1/models"
        logging.info(f"Calling {url}")
        return requests.get(url, timeout=timeout)


class Processor:

    def __init__(self, server):
        self.active_server = server

    def check_admin_commands(self, job_input):
        prompt = job_input.get("prompt", "")
        if prompt == "!rf":
            logging.info("Received full restart command")
            self.trigger_full_restart()
            return True, "Triggered full restart."
        
        if job_input.get("update_env"):
            logging.info("Received env update command")
            updated_env_dict = job_input.get("env")
            os.environ.update(updated_env_dict)
            return True, f"Updated env."

        new_server_name = job_input.get("new_server")
        if new_server_name:
            wait = job_input.get("wait", False)

            logging.info(f"Received new server command {new_server_name=}, {wait=}")
            self.start_new_server(name=new_server_name, wait=wait)
            return True, "Started new server."

        return False, ""

    def trigger_full_restart(self):
        logging.info("Triggering full restart")
        with open("./.watch_reloader", "w") as f:
            f.write(str(time.time()))
    
    def start_new_server(self, name, wait=True):
        if self.active_server is not None:
            self.active_server.stop()

        self.active_server = LLMServer(name)
        self.active_server.start()

        if wait:
            self.active_server.wait_until_ready()

    
    def ensure_server(self):
        if not self.active_server:
            self.start_new_server(get_initial_server_name(), wait=False)
        
        if not self.active_server.ready:
            self.active_server.wait_until_ready()


    async def process(self, job):
        job_input = job["input"]

        is_detected, msg = self.check_admin_commands(job_input)
        if is_detected:
            yield msg
            return
        
        self.ensure_server()

        url = self.active_server.get_base_url() + job_input.get("openai_route")
        data = job_input.get("openai_input")
        logging.info(f"Sending request to {url} with data: {data}")

        
        method = "POST" if '/completion' in url else "GET"
        is_stream = data.get("stream")

        async with aiohttp.ClientSession() as session:
            async with session.request(method, url, json=data) as response:
                logging.info(f"Received response: {response}, {response.status}")
                logging.info(f"Headers: {response.headers}")

                if response.status != 200:
                    yield await parse_as_json(response)
                    return

                if is_stream:
                    logging.info(f"streaming response...")
                    async for chunk in response.content.iter_any():
                        yield chunk.decode("utf-8")
                else:
                    yield await parse_as_json(response)


async def parse_as_json(response):
    try:
        result = await response.text()
        # logging.info(f"result type1: { type(result) }")
        result = json.loads(result)
        # logging.info(f"result type2: { type(result) }")
        return result
    except Exception as e:
        logging.error(f"Error parsing response: {e}")
        return result

def get_initial_server_name():
    return os.environ.get("INITIAL_SERVER", "LCPP")

processor = Processor(None)

async def handler(job):
    results_generator = processor.process(job)
    async for batch in results_generator:
        yield batch


def run():
    if os.getenv("INITIAL_START", "0") == "1":
        processor.start_new_server(
            name=get_initial_server_name(),
            wait=os.getenv("INITIAL_WAIT", "0") == "1"
        )

    runpod.serverless.start(
        {
            "handler": handler,
            "concurrency_modifier": lambda x: int(os.getenv("MAX_CONCURRENCY", 10)),
            "return_aggregate_stream": True,
        }
    )


def test():
    processor.active_server = LLMServer("LCPP")

    async def invoke_handler():
        print("Invoking handler")
        job = {
            "input": {
                "openai_route": "/v1/models",
                "openai_input": {
                    "model": "gpt-2",
                    "prompt": "Once upon a time",
                    # "max_tokens": 50
                    # "stream": True,
                    "n_predict": 20
                }
            }
        }

        async for chunk in handler(job):
            print(chunk)

    loop = asyncio.get_event_loop()
    loop.run_until_complete(invoke_handler())


if len(sys.argv) == 2 and sys.argv[1] == "test":
    test()
else:
    run()
