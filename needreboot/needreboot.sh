#!/bin/bash
if [ -f /var/run/reboot-required ]; then
  exit 0
else
  exit 1
fi
