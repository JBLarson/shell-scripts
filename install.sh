#!/usr/bin/env bash
# Install shell scripts by symlinking common and platform-specific scripts to ~/bin

# detect OS
case "$(uname)" in
  Darwin)   platform=mac   ;;
  Linux*)   platform=linux ;;
  *) echo "Unsupported OS: $(uname)" >&2; exit 1 ;;
esac

# ensure ~/bin exists and is on your PATH
mkdir -p ~/bin

# link common scripts
for f in common/*.sh; do
  ln -sf "$PWD/$f" ~/bin/"${f##*/}"
done

# link platform-specific scripts
for f in "$platform"/*.sh; do
  ln -sf "$PWD/$f" ~/bin/"${f##*/}"
done

echo "Installed common + $platform scripts into ~/bin"

