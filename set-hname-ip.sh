#!/bin/bash
#set -x
#Usage: $ set-hname-ip.sh new-hostname new-static-ipaddress
#eg:    $ set-hname-ip.sh master-node  192.168.4.110
#
#This script is targeted at Ubuntu that's using netplan network management.

#Set hostname
sudo hostnamectl set-hostname $1

#Disable cloud-init network
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

#Change IP setup to a static IP address
my_ipsetup=$(cat <<EOF
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
      - $2/24
      routes:
      - to: default
        via: 192.168.4.1
      nameservers:
       addresses: [192.168.4.1,8.8.8.8,8.8.4.4]
EOF
)

#Write the YAML content to the /etc/netplan/50-cloud-init.yaml file
echo "$my_ipsetup" | sudo tee /etc/netplan/50-cloud-init.yaml

#Write entries to /etc/hosts
echo "192.168.4.110 controller master-node" | sudo tee -a /etc/hosts
echo "192.168.4.111 worker1 worker01" | sudo tee -a /etc/hosts
echo "192.168.4.112 worker2 worker02" | sudo tee -a /etc/hosts

#Finish up
sleep 10
sudo reboot now
