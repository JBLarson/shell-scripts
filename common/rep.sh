#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

# Set the filename to the argument
FILENAME=$1

# Path to the public directory
PUBLIC_DIR="/home/ubuntu/app/public" # Replace with the actual path to your publ
ic directory

# Remove the existing file and open nano to create a new one
rm "$PUBLIC_DIR/$FILENAME.html" && nano "$PUBLIC_DIR/$FILENAME.html"
