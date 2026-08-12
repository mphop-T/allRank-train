#!/bin/bash

# before start - from the main dir run:
# docker build -t allrank:latest .

DIR=$(dirname $0)
PROJECT_DIR="$(cd $DIR/..; pwd)"

docker run -e PYTHONPATH=/allrank -v $PROJECT_DIR:/allrank allrank:cpu /bin/sh -c 'python allrank/main.py --config-file-name /allrank/scripts/athletes_listnet_men_combined_config.json --run-id test_run --job-dir /allrank/listnet-men-combined-test-data'