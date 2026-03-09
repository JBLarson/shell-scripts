#!/usr/bin/env bash

echo ""
echo "=================================="
echo "  GUNICORN CONTAINER LOG VIEWER"
echo "=================================="
echo "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "=================================="
echo ""

# FIXED: Removed '-a' to only catch running containers, and added 'head -n 1'
CONTAINER_ID=$(docker ps --format '{{.ID}} {{.Command}}' | grep gunicorn | awk '{print $1}' | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
    echo "  ERROR: No running gunicorn container found."
    echo ""
    exit 1
fi

STATUS=$(docker ps --format '{{.ID}} {{.Status}}' | grep "$CONTAINER_ID" | awk '{print $2, $3, $4}')

echo "  Container : $CONTAINER_ID"
echo "  Status    : $STATUS"
echo ""
echo "=================================="
echo "  LOGS"
echo "=================================="
echo ""

docker logs "$CONTAINER_ID"
