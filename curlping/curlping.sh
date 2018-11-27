#!/bin/bash

CURL_FORMAT=\
'{ "http_code": "%{http_code}", "time_namelookup": "%{time_namelookup}", "time_connect": "%{time_connect}", "time_appconnect": "%{time_appconnect}", "time_pretransfer": "%{time_pretransfer}", "time_redirect": "%{time_redirect}", "time_starttransfer": "%{time_starttransfer}", "time_total": "%{time_total}" }\n'


if [ -z "$1" ]; then
  echo "usage: $0 <http/https resource to hit>"
  exit 1
fi

while true; do 
  curl -s -w "$CURL_FORMAT" -o /dev/null $1
  sleep 1
done
