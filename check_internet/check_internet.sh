#!/bin/bash

if nc -z -w3 8.8.8.8 53 >/dev/null 2>&1; then
  echo "$(date +[%Y-%m-%d\ %H:%M:%S]) Internet access is up"
fi
while true; do
  while nc -z -w3 8.8.8.8 53 >/dev/null 2>&1; do
    sleep 1
  done
  echo "$(date +[%Y-%m-%d\ %H:%M:%S]) Internet access is down"
  while !  nc -z -w3 8.8.8.8 53 >/dev/null 2>&1; do
    sleep 1
  done
  echo "$(date +[%Y-%m-%d\ %H:%M:%S]) Internet access is up"
done
