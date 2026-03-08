#!/usr/bin/env bash

echo ""
echo "=================================="
echo "  GUNICORN CONTAINER LOG VIEWER"
echo "=================================="
echo "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "=================================="
echo ""

CONTAINER_ID=$(docker ps -a --format '{{.ID}} {{.Command}}' | grep gunicorn | awk '{print $1}')

if [ -z "$CONTAINER_ID" ]; then
    echo "  ERROR: No gunicorn container found."
    echo ""
    exit 1
fi

STATUS=$(docker ps -a --format '{{.ID}} {{.Status}}' | grep "$CONTAINER_ID" | awk '{print $2, $3, $4}')

echo "  Container : $CONTAINER_ID"
echo "  Status    : $STATUS"
echo ""
echo "=================================="
echo "  LOGS"
echo "=================================="
echo ""

docker logs "$CONTAINER_ID"
