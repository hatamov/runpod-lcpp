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
    logging.info("running cleanup_process...")
    for src in running_servers:
        src.stop()

atexit.register(cleanup_process)

class LLMServer:
    def __init__(self, name):
        self.name = name
        self.server_proc = None
        self.ready = False

    def start(self):
        cmd = os.environ.get(f"S_{self.name.upper()}_CMD", "echo 'No command provided'")
        logging.info(f"Starting server {self.name} with command: {cmd}")

        args = shlex.split(cmd)
        self.server_proc = subprocess.Popen(args)

        if self.server_proc.poll() is not None:
            raise Exception(f"Failed to start server")
        
        running_servers.append(self)

    def wait_until_ready(self, timeout=None):
        if self.ready:
            return True

        logging.info(f"Waiting for server {self.name} to be ready")

        if timeout is None:
            timeout = int(os.environ.get("S_WAIT_TIMEOUT", 120))

        start_time = time.time()
        last_log_time = start_time
        last_error = None
        while time.time() - start_time < timeout:
            try:
                response = self.call_v1_models()
                response.raise_for_status()  # Raises an HTTPError if the HTTP request returned an unsuccessful status code
            except requests.exceptions.ConnectionError as e:
                last_error = e
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

            if time.time() - last_log_time >= 5:
                elapsed = time.time() - start_time
                logging.info(f"wait_until_ready: Not ready after {elapsed:.1f} seconds. Last error: {last_error}")
                last_log_time = time.time()

            time.sleep(1)

        elapsed = time.time() - start_time
        logging.error(f"Server failed to start server {self.name} after {elapsed:.1f} seconds. Last error: {last_error}")
        return False

    def stop(self):
        logging.info(f"Stopping server {self.name}")
        if self.server_proc:
            self.server_proc.terminate()
            self.server_proc.wait()
            running_servers.remove(self)

    def get_port(self):
        port = os.getenv(f"S_{self.name.upper()}_PORT")
        if port is None:
            raise Exception(f"Port not found for server {self.name}")
        return port
    
    def get_base_url(self):
        return f"http://localhost:{self.get_port()}"

    def call_v1_models(self, timeout=1):
        url = self.get_base_url() + "/v1/models"
        # logging.info(f"Calling {url}")
        return requests.get(url, timeout=timeout)


class Processor:

    def __init__(self, server):
        self.active_server = server

    def start_new_server(self):
        name = os.environ.get("INITIAL_SERVER", "lcpp")
        logging.info(f"Starting new server {name}")
        if self.active_server is not None:
            self.active_server.stop()

        self.active_server = LLMServer(name)
        self.active_server.start()
    
    def ensure_server(self):
        if self.active_server:
            if self.active_server.ready:
                return True
            
            return self.active_server.wait_until_ready()

        self.start_new_server()
        return self.active_server.wait_until_ready()

    
    def normalize_input(self, job_input):
        if not job_input.get("openai_route"):
            job_input["openai_route"] = "/v1/completions"
            job_input["openai_input"] = {
                "prompt": job_input.get("prompt", "Once upon a time"),
                "n_predict": 20,
                "stream": True,
            }

        routes_map = {
            # llama.cpp -> openai
            "/completion": "/v1/completions",
            # tabbyAPI -> openai
            "/v1/model/list": "/v1/models",
        }

        if job_input["openai_route"] in routes_map:
            job_input["openai_route"] = routes_map[job_input["openai_route"]]
        
        return job_input

    def run_admin_command(self, job_input):
        admin_cmd = job_input.get("admin")
        if admin_cmd == "restart":
            logging.info("Triggering full restart")
            os.system("sh -c 'sleep 1 && date > ./.restart_trigger' &")
            return "Triggered full restart."

        return None

    async def process(self, job):
        logging.info(f"Received job: {job}")
        job_input = job["input"]

        cmd_result = self.run_admin_command(job_input)
        if cmd_result:
            yield cmd_result
            return

        self.normalize_input(job_input)
        if not self.ensure_server():
            yield "Server failed to start."
            return

        url = self.active_server.get_base_url() + job_input.get("openai_route")
        data = job_input.get("openai_input")
        logging.info(f"Sending request to {url} with data: {data}")

        method = "POST" if '/completion' in url else "GET"
        is_stream = data.get("stream")

        async with aiohttp.ClientSession() as session:
            async with session.request(method, url, json=data) as response:
                logging.info(f"Received response: {response.status} {response}")

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


def run():
    logging.info("Starting serverless.runpod.serverless.start")

    processor = Processor(None)

    # async def handler(job):
    #     results_generator = processor.process(job)
    #     async for batch in results_generator:
    #         yield batch

    if os.getenv("START_SEVER_ON_BOOT", "0") == "1":
        processor.start_new_server()

    runpod.serverless.start(
        {
            "handler": processor.process,
            "concurrency_modifier": lambda x: int(os.getenv("MAX_CONCURRENCY", 10)),
            "return_aggregate_stream": True,
        }
    )

if __name__ == "__main__":
    run()
