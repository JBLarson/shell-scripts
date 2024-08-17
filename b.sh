#!/bin/sh

echo """ _          _     
| |__   ___| |__  
| '_ \ / __| '_ \ 
| |_) |\__ \ | | |
|_.__(_)___/_| |_|\n"""
echo && echo """Homebrew Update / Upgrade / Cleanup / Doctor\n"""


brew update && echo && brew upgrade && echo brew cleanup && echo && brew doctor
echo
