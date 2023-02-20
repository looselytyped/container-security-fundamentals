#!/bin/sh
set -e

# entrypoint.sh
if [ "$1" = 'default' ]; then
  # do default thing here
  exec java -jar /app/app.jar
else
  # if the user supplied say /bin/bash
  exec "$@"
fi

