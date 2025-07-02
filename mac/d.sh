#!/bin/sh

echo "\n----------------------------------------------"
echo "Starting compsci container and attaching to it"
echo "----------------------------------------------\n"

docker start compsci && docker attach compsci
