#!/usr/bin/sh
# Clear Linux page cache, dentries, and inodes to free RAM

free -h

sudo sync; sudo sysctl -w vm.drop_caches=1
sudo sync; sudo sysctl -w vm.drop_caches=2
sudo sync; sudo sysctl -w vm.drop_caches=3

free -h
