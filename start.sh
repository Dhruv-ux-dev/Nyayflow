#!/bin/bash
# Start Spring Boot in the background and nginx on $PORT; exit when either stops.
LISTEN_PORT="${PORT:-8080}"
sed "s/__PORT__/${LISTEN_PORT}/" /app/nginx.conf.template > /tmp/nginx.conf
java -jar /app/app.jar &
nginx -e /dev/stderr -c /tmp/nginx.conf &
wait -n
exit $?
