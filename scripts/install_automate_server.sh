#!/bin/bash

chef_server_fqdn=$1
delivery_password=$2
package_version=$3

echo $(curl -s http://169.254.169.254/latest/meta-data/public-hostname) | xargs sudo hostnamectl set-hostname

sysctl -w vm.swappiness=1
sysctl -w vm.dirty_expire_centisecs=30000
sysctl -w net.ipv4.ip_local_port_range='35000 65000'
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag

# install Chef Automate
if [ ! $(which automate-ctl) ]; then
  echo "Installing Chef Automate..."
  curl -LO https://omnitruck.chef.io/install.sh && sudo bash ./install.sh -P automate -v $package_version

  # run preflight check
  # automate-ctl preflight-check

  # run setup
  automate-ctl setup --license /tmp/automate.license --key /tmp/delivery.pem --server-url https://$chef_server_fqdn/organizations/support --fqdn $(hostname) --enterprise default --configure --no-build-node

  # configure aws s3backups
  echo "backup['bucket']                    = 'wfisher-automate-backup'" >> /etc/delivery/delivery.rb
  echo "backup['region']                    = 'us-west-2'" >> /etc/delivery/delivery.rb
  echo "backup['type']                      = 's3'" >> /etc/delivery/delivery.rb
  echo "backup['elasticsearch']['bucket']   = 'wfisher-automate-backup'" >> /etc/delivery/delivery.rb
  echo "backup['elasticsearch']['region']   = 'us-west-2'" >> /etc/delivery/delivery.rb
  echo "backup['elasticsearch']['type']     = 's3'" >> /etc/delivery/delivery.rb
  echo "reaper['enable']                    = true" >> /etc/delivery/delivery.rb
  echo "reaper['mode']                      = 'delete'" >> /etc/delivery/delivery.rb
  echo "reaper['retention_period_in_days']  = 4" >> /etc/delivery/delivery.rb
  automate-ctl reconfigure

  # wait for all services to come online
  echo "Waiting for services..."
  until (curl --insecure -D - https://localhost/api/_status) | grep "200 OK"; do automate-ctl restart && sleep 1m; done
  while (curl --insecure https://localhost/api/_status) | grep "fail"; do sleep 15s; done

  # create an initial user
  echo "Creating delivery user..."
  automate-ctl create-user default delivery --password $delivery_password --roles "admin"
fi

echo "Your Chef Automate server is ready!"
