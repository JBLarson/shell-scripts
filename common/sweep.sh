#!/bin/bash
# Sweep PNG screenshots on Desktop to /Documents/screenshots/{date}

# Get current date components
month=$(date +%m)
day=$(date +%d)
year=$(date +%y)

# Construct folder name
folder_name="${month}_${day}_${year}"

# Define paths
desktop_path="$HOME/Desktop"
screenshots_base="$HOME/Documents/screenshots"
target_folder="${screenshots_base}/${folder_name}"

# Create target folder if it doesn't exist
mkdir -p "$target_folder"

# Move all PNG files and count them
moved_count=0
while IFS= read -r -d '' file; do
    mv "$file" "$target_folder/"
    ((moved_count++))
done < <(find "$desktop_path" -maxdepth 1 -type f -iname "*.png" -print0)

if [ "$moved_count" -eq 0 ]; then
    echo "No PNG files found on Desktop"
else
    echo "Moved $moved_count PNG file(s) to $target_folder"
fi
