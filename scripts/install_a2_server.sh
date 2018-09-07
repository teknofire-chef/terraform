#!/bin/bash

echo $(curl -s http://169.254.169.254/latest/meta-data/public-hostname) | xargs sudo hostnamectl set-hostname

sysctl -w vm.swappiness=1
sysctl -w vm.dirty_expire_centisecs=30000
sysctl -w net.ipv4.ip_local_port_range='35000 65000'
sysctl -w vm.max_map_count=262144
sysctl -w vm.dirty_expire_centisecs=20000

echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag

# install Chef Automate
if [ ! $(which chef-automate) ]; then
  echo "Installing Chef Automate CLI..."
  curl https://packages.chef.io/files/current/automate/latest/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate
  mv chef-automate /usr/sbin

  # run setup
  echo "Running chef-automate deploy"
  chef-automate deploy --accept-terms-and-mlsa
fi

echo "Your Chef Automate2 server is ready!"
