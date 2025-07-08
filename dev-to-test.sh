#!/bin/bash

mkdir -p /tmp/transfer_dev_to_test

sudo docker cp tarefa-app-dev:/app/src /tmp/transfer_dev_to_test/
sudo docker cp tarefa-app-dev:/app/pom.xml /tmp/transfer_dev_to_test/

cp -r /tmp/transfer_dev_to_test/src ./
cp /tmp/transfer_dev_to_test/pom.xml ./

sudo docker-compose build --no-cache app-test

sudo rm -rf /tmp/transfer_dev_to_test