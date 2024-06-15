import asyncio
from handler import Processor, LLMServer

def test():
    processor = Processor(None)
    processor.active_server = LLMServer("lcpp")

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

        generator = processor.process(job)
        async for chunk in generator:
            print(chunk)

    loop = asyncio.get_event_loop()
    loop.run_until_complete(invoke_handler())


if __name__ == "__main__":
    test()
