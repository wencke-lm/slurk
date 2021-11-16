#!/usr/bin/env bash
set -eu

# Starts slurk on the local machine.
# Environment variables:
#   SLURK_SECRET_KEY: Secret key used for flask for cookies, defaults to `$RANDOM`
#   SLURK_DATABASE_URI: URI for the database, defaults to `sqlite:///:memory:`; mutually exclusive with `SLURK_DOCKER`
#   SLURK_PORT: Port to listen on, defaults to 5000
#   SLURK_DOCKER: Docker container name to be used. When not provided, docker is not used
#   SLURK_DISABLE_ETAG: Disables the ETag for the rest API, defaults to `False`
#   SLURK_DOCKER_TAG: Docker tag to be used, defaults to `latest`
#   SLURK_ENV: Environment for flask, either `development` or `production`, defaults to `development`
#   SLURK_GOLMI_URL:
#   SLURK_GOLMI_PORT:

export SLURK_SECRET_KEY=${SLURK_SECRET_KEY:-$RANDOM}
export FLASK_ENV=${SLURK_ENV:-development}
PORT=${SLURK_PORT:-5000}

if [ -z ${SLURK_DOCKER+x} ]; then
    gunicorn -b :$PORT -k geventwebsocket.gunicorn.workers.GeventWebSocketWorker 'slurk:create_app()'
else
    if ! command -v docker &> /dev/null; then
        echo '`docker` could not be found' 1>&2
        exit 2
    fi

    if [ "$(docker ps -qa -f name=$SLURK_DOCKER)" ]; then
        if [ "$(docker ps -qa -f status=running -f name=$SLURK_DOCKER)" ]; then
            docker kill $SLURK_DOCKER 2> /dev/null | true
        fi

        docker rm $SLURK_DOCKER 2> /dev/null | true
    fi

    docker run -d \
        --name=$SLURK_DOCKER \
        -p $PORT:80 \
        -e SLURK_SECRET_KEY=$SLURK_SECRET_KEY \
        -e SLURK_DISABLE_ETAG=${SLURK_DISABLE_ETAG:-False} \
        -e FLASK_ENV=$FLASK_ENV \
	-e SLURK_GOLMI_URL=${SLURK_GOLMI_URL:-127.0.0.1} \
	-e SLURK_GOLMI_PORT=${SLURK_GOLMI_PORT:-5000} \
        slurk/server:${SLURK_DOCKER_TAG:-latest}
fi
