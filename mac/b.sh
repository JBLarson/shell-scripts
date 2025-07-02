#!/bin/sh

echo """ _          _     
| |__   ___| |__  
| '_ \ / __| '_ \ 
| |_) |\__ \ | | |
|_.__(_)___/_| |_|\n"""

echo && echo """Homebrew Update / Upgrade / Cleanup & Neofetch\n"""


echo "brew update" && brew update && echo
echo "brew upgrade" && brew upgrade && echo
echo "brew cleanup" && brew cleanup && echo
neofetch
