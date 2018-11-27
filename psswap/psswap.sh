#!/bin/bash

# Source from https://stackoverflow.com/questions/30481314/how-can-i-know-which-process-is-using-swap
(echo "COMM PID SWAP"; for file in /proc/*/status ; do awk '/^Pid|VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | grep kB | grep -wv "0 kB" | sort -k 3 -n -r) | column -t
