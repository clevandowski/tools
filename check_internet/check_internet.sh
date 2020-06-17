#!/bin/bash

if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
  echo "$(date +[%Y-%m-%d\ %H:%M:%S]) Internet access is up"
fi
while true; do
  while ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; do
    sleep 1
  done
  echo "$(date +[%Y-%m-%d\ %H:%M:%S]) Internet access is down"
  while ! ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; do
    sleep 1
  done
  echo "$(date +[%Y-%m-%d\ %H:%M:%S]) Internet access is up"
done
