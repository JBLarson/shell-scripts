#!/usr/bin/bash

# sudo apt install fzf
# kill script - CLI utility for finding / sigkilling problem processes

echo "searching for processes matching: $1"

SELECTED=$(ps -e -o pid,stat,time,args | grep -i "$1" | grep -v grep | grep -v $$ | fzf --header="ARROW=select  ENTER=kill  ESC=abort" --reverse)

if [ -z "$SELECTED" ]; then
    echo "aborted."
    exit 0
fi

PID=$(echo "$SELECTED" | awk '{print $1}')
PROC=$(echo "$SELECTED" | awk '{$1=""; print $0}' | xargs)

echo "selected PID $PID: $proc"
read -p "send SIGTERM? [y/N/k(ill -9)] " CONFIRM

case "$CONFIRM" in
    y|Y) kill "$PID" && echo "SIGTERM sent to $PID" ;;
    k|K) kill -9 "$PID" && echo "SIGKILL sent to $PID" ;;
    *) echo "aborted." ;;
esac
