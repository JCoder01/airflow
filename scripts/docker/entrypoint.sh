#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

TRY_LOOP="20"

: "${REDIS_HOST:="redis"}"
: "${REDIS_PORT:="6379"}"
: "${REDIS_PASSWORD:=""}"

wait_for_port() {
  local name="$1" host="$2" port="$3"
  local j=0
  while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
    j=$((j+1))
    if [ $j -ge $TRY_LOOP ]; then
      echo >&2 "$(date) - $host:$port still not reachable, giving up"
      exit 1
    fi
    echo "$(date) - waiting for $name... $j/$TRY_LOOP"
    sleep 5
  done
}

REDIS_PREFIX=
export PYTHONPATH=$LIB_ROOT:$PYTHONPATH
export AIRFLOW__CELERY__BROKER_URL="redis://$REDIS_HOST:$REDIS_PORT/1"
wait_for_port "Redis" "$REDIS_HOST" "$REDIS_PORT"
# mount s3fs

# s3fs -o iam_role='ec2dataaccess' -o umask=022 -f aam-macs /usr/local/airflow/airflow/remote_logs

case "$1" in
  webserver)
    sleep 10
    exec airflow webserver
    ;;
  worker|scheduler)
    # To give the webserver time to run initdb.
    sleep 10
    exec airflow "$@"
    ;;
  flower)
    sleep 10
exec airflow "$@"
    ;;
  version)
    exec airflow "$@"
    ;;
  *)
    # The command is something like bash, not an airflow subcommand. Just run it in the right environment.
    exec "$@"
    ;;
esac
