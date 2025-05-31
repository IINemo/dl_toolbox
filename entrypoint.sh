#!/bin/bash

if [ ! -z "$HASHED_PASSWORD" ]
then
    sed -i "s/# c.ServerApp.password = ''/c.ServerApp.password = '$HASHED_PASSWORD'/g" /home/jovyan/jupyter/jupyter_server_config.py
fi

if [ ! -z "$SSL" ]
then
    sed -i \
        -e "s/# c.ServerApp.certfile/c.ServerApp.certfile/g" \
        -e "s/# c.ServerApp.keyfile/c.ServerApp.keyfile/g" \
        /home/jovyan/jupyter/jupyter_server_config.py
fi

if [ ! -z "$DLBOX_USERNAME" ]
then
    useradd -u 1000 -m "$DLBOX_USERNAME" -s bash
fi

export PYTHONPATH="$PYTHONPATH:/notebook"

$@
