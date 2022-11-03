#!/bin/bash

docker build ./synapse-captcha/
docker build ./mjolnir/
docker build ./pantalaimon/
docker build ./synapse-docker/
docker build ./synapse-worker-docker/
docker build ./matrix-dimension/