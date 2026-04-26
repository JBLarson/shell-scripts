# o.sh
#!/bin/bash

BLUE='\033[38;5;39m'
RESET='\033[0m'

MODEL="mistral:7b-instruct"
MODEL_LABEL="mistral:7b"

while [[ "$1" == --* ]]; do
  case "$1" in
    --qwen)  MODEL="qwen3.5:4b";                  MODEL_LABEL="qwen3.5:4b";    shift ;;
    --llama) MODEL="llama3.1:8b-instruct-q4_K_M"; MODEL_LABEL="llama3.1:8b";  shift ;;
    *)
      echo "Unknown flag: $1"
      echo "Usage: ask [--qwen|--llama] <question>"
      exit 1
      ;;
  esac
done

QUESTION="$*"
DATETIME=$(date "+%Y-%m-%d %H:%M:%S")

echo ""
echo -e "${BLUE}┌─ Ollama ────────────────────────────────────────────┐${RESET}"
echo -e "${BLUE}│${RESET} ${DATETIME}  ·  ${MODEL_LABEL} "
echo -e "${BLUE}└─────────────────────────────────────────────────────┘${RESET}"
echo -e "${BLUE}Prompt: ${QUESTION}"
echo ""

ollama run "$MODEL" "$QUESTION"
