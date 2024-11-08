#!/bin/sh

echo && echo "Brew Leaves Dependency Count" && echo

for package in $(brew leaves); do
    deps_count=$(brew deps --installed "$package" | wc -l)
    echo "$package - $deps_count dependencies"
done
