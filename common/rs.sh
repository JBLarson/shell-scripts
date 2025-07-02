#!/usr/bin/env bash
# save as repo-stats.sh, chmod +x repo-stats.sh
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


