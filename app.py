import asyncio
import io
import tomllib
from flask import Flask, request, jsonify, send_from_directory
import edge_tts

app = Flask(__name__, static_folder="static")
DATA_FILE = "data.toml"


def load_data():
    try:
        with open(DATA_FILE, "rb") as f:
            return tomllib.load(f)
    except FileNotFoundError:
        return {"概念": []}


def _toml_key(k):
    if all(c.isascii() and (c.isalnum() or c in "-_") for c in k):
        return k
    return f'"{k}"'


def save_data(data):
    lines = []
    for w in data.get("概念", []):
        lines.append('[["概念"]]')
        for k, v in w.items():
            lines.append(f'{_toml_key(k)} = "{v}"')
        lines.append("")
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


@app.route("/")
def index():
    return send_from_directory("static", "index.html")


@app.route("/api/words", methods=["GET"])
def get_words():
    data = load_data()
    return jsonify(list(data.get("概念", [])))


@app.route("/api/words", methods=["POST"])
def add_word():
    word = request.json
    data = load_data()
    data.setdefault("概念", []).append(word)
    save_data(data)
    return jsonify({"ok": True})


@app.route("/api/words/<int:idx>", methods=["PUT"])
def update_word(idx):
    word = request.json
    data = load_data()
    data["概念"][idx] = word
    save_data(data)
    return jsonify({"ok": True})


@app.route("/api/words/<int:idx>", methods=["DELETE"])
def delete_word(idx):
    data = load_data()
    del data["概念"][idx]
    save_data(data)
    return jsonify({"ok": True})


@app.route("/api/voices")
def get_voices():
    lang = request.args.get("lang", "")

    async def fetch():
        voices = await edge_tts.list_voices()
        if lang:
            voices = [v for v in voices if v["Locale"].startswith(lang)]
        return voices

    voices = asyncio.run(fetch())
    return jsonify(voices)


@app.route("/api/speak", methods=["POST"])
def speak():
    body = request.json
    text = body["text"]
    voice = body["voice"]

    async def generate():
        communicate = edge_tts.Communicate(text, voice)
        buf = io.BytesIO()
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                buf.write(chunk["data"])
        return buf.getvalue()

    audio = asyncio.run(generate())
    return audio, 200, {"Content-Type": "audio/mpeg"}


if __name__ == "__main__":
    app.run(debug=True, port=5000)
