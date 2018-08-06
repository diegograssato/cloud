#------------------------------------------------------------------------------#
#                   OFFICIAL DEBIAN REPOS                    
#------------------------------------------------------------------------------#

###### Debian Main Repos
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free

deb http://deb.debian.org/debian/ stable-updates main contrib non-free
deb-src http://deb.debian.org/debian/ stable-updates main contrib non-free

deb http://deb.debian.org/debian-security stable/updates main
deb-src http://deb.debian.org/debian-security stable/updates main

deb http://ftp.debian.org/debian stretch-backports main
deb-src http://ftp.debian.org/debian stretch-backports main

sudo apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

 sudo apt-key fingerprint 0EBFCD88

 
 sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
 sudo apt-get install docker-ce mysql-server
docker run hello-world

mysql -u root -p
CREATE DATABASE IF NOT EXISTS cattle COLLATE = 'utf8_general_ci' CHARACTER SET = 'utf8';
 GRANT ALL ON cattle.* TO 'cattle'@'%' IDENTIFIED BY 'cattle';
GRANT ALL ON cattle.* TO 'cattle'@'localhost' IDENTIFIED BY 'cattle';
GRANT ALL ON cattle.* TO 'cattle'@'127.0.0.1' IDENTIFIED BY 'cattle';

docker run -d --restart=always -p 8080:8080  -e CATTLE_DB_CATTLE_MYSQL_HOST=10.0.70.1 -e CATTLE_DB_CATTLE_MYSQL_PORT=3306 -e CATTLE_DB_CATTLE_MYSQL_NAME=cattle -e CATTLE_DB_CATTLE_USERNAME=cattle -e CATTLE_DB_CATTLE_PASSWORD=cattle  rancher/server:latest

sudo docker run --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.9 http://10.0.70.1:8080/v1/scripts/7E10370958049AAE3E0F:1514678400000:03yfr5XgATNKnlx5roYvCnnM


auto enp0s3
iface enp0s3 inet static
address 190.168.0.169
netmask 255.255.255.0
gateway 190.168.0.1
mtu 1400


