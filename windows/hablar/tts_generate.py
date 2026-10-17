import asyncio
import base64
import os

import edge_tts


async def main() -> None:
    text = base64.b64decode(os.environ["HABLAR_TEXT_B64"]).decode("utf-8")
    output = os.environ["HABLAR_OUTPUT"]
    voice = os.environ.get("HABLAR_VOICE", "es-AR-ElenaNeural")
    await edge_tts.Communicate(text, voice).save(output)


asyncio.run(main())
