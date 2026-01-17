#!/usr/bin/sh
echo '             _
            | |    
  __ _   ___| |__  
 / _` | / __| '"'"'_ \ 
| (_| |_\__ \ | | |
 \____(_)___/_| |_|
'
echo
echo "APT Update / Upgrade / Cleanup & Neofetch"
echo
echo "sudo apt-get update"      && sudo apt-get update      && echo
echo "sudo apt-get upgrade -y"  && sudo apt-get upgrade -y  && echo
echo "sudo apt-get autoremove -y" && sudo apt-get autoremove -y && echo
echo "sudo apt-get autoclean"   && sudo apt-get autoclean   && echo
neofetch
