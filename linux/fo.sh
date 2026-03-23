#!/usr/bin/env bash

# flush Ollama

LOADED=$(curl -s http://localhost:11434/api/ps)
MODEL=$(echo "$LOADED" | python3 -c "import sys,json; models=json.load(sys.stdin).get('models',[]); print(models[0]['name'] if models else '')")

if [ -z "$MODEL" ]; then
  echo "No model currently loaded in VRAM"
  exit 0
fi

echo "Flushing model from VRAM: $MODEL"
curl -s http://localhost:11434/api/generate -d "{\"model\": \"$MODEL\", \"keep_alive\": 0}" > /dev/null
echo "Done"
