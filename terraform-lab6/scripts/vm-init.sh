#! /bin/bash
sudo apt-get update
sudo snap install docker

sudo docker pull olehola/iit-lab4-5
sudo docker pull containrrr/watchtower

sudo docker run --rm -d --name lab6 -p 80:80 olehola/iit-lab4-5

sudo docker run --rm -d \
--name watchtower \
-v /var/run/docker.sock:/var/run/docker.sock \
containrrr/watchtower \
--interval 10