#!/bin/bash

mkdir -p /tmp/transfer_test_to_prod

sudo docker cp tarefa-app-test:/app/src /tmp/transfer_test_to_prod/
sudo docker cp tarefa-app-test:/app/pom.xml /tmp/transfer_test_to_prod/

cp -r /tmp/transfer_test_to_prod/src ./
cp /tmp/transfer_test_to_prod/pom.xml ./

sudo docker-compose build --no-cache app-prod

sudo rm -rf /tmp/transfer_test_to_prod