#!/bin/bash

echo "===== Cloning Docker Images ====="
cd images/
git clone https://github.com/matrix-org/mjolnir
git clone https://github.com/matrix-org/pantalaimon/
git clone https://codeberg.org/deathrow/synapse-worker-docker
git clone https://codeberg.org/deathrow/synapse-docker
git clone https://codeberg.org/deathrow/synapse-captcha

echo "===== Building Docker Images ====="
bash build.sh

echo "===== Building Tools ====="
cd ../tools/

git clone https://github.com/matrix-org/rust-synapse-compress-state
cd rust-synapse-compress-state/synapse-auto-compressor
cargo build
mv ../target/debug/synapse_auto_compressor ../../synapse_auto_compressor

cd ../../

git clone https://github.com/joj0/synadm
cd synadm
sudo python3 setup.py install

cd ../../

echo "===== Pulling Docker Images ====="
docker-compose pull

echo "===== Complete ====="