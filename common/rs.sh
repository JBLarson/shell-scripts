#!/usr/bin/env bash
# Calculate total lines added/deleted and files changed across entire git history

added=0
deleted=0
files=0

while read -r a d f; do
  ((added+=a))
  ((deleted+=d))
  ((files++))
done < <(git log --no-merges --pretty=tformat: --numstat)

echo "Files changed: $files"
echo "Lines added:   $added"
echo "Lines deleted: $deleted"


