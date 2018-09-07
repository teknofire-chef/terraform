#!/bin/bash
usage="Usage: $(basename "$0") ADMIN_EMAIL ADMIN_PASSWORD [VERSION]"

admin_email=$1
admin_password=$2
package_version=$3
if [ -n "${package_version}" ]; then
  package_version="latest"
fi

if [[ $# -lt 2 ]]; then
  echo "$usage"
  echo "Missing command argument"
  exit 1
fi

echo $(curl -s http://169.254.169.254/latest/meta-data/public-hostname) | xargs sudo hostnamectl set-hostname

# create staging directories
if [ ! -d /drop ]; then
  mkdir /drop
fi

# install Chef server
if [ ! $(which chef-server-ctl) ]; then
  echo "Installing Chef server..."
  curl -LO https://omnitruck.chef.io/install.sh && sudo bash ./install.sh -P chef-server -v $package_version

  echo "opscode_erchef['max_request_size'] = 2000000" >> /etc/opscode/chef-server.rb
  chef-server-ctl reconfigure

  echo "Waiting for services..."
  until (curl -D - http://localhost:8000/_status) | grep "200 OK"; do sleep 15s; done
  while (curl http://localhost:8000/_status) | grep "fail"; do sleep 15s; done
fi


# create admin user and organization
if [ ! $(sudo chef-server-ctl user-list | grep chefadmin) ]; then
  echo "Creating chef admin user and tekno organization..."
  chef-server-ctl user-create chefadmin chef admin $admin_email $admin_password --filename /drop/chefadmin.pem
  chef-server-ctl org-create tekno "TeknoFire" --association_user chefadmin --filename default-validator.pem
fi

# configure manage jobs
#if [ ! $(which chef-manage-ctl) ]; then
#  echo "Installing push jobs server..."
#  chef-server-ctl install chef-manage
#  chef-manage-ctl reconfigure --accept-license
#fi

# moving this to the end to reduce the amount of time this takes to install everything
chef-server-ctl reconfigure

echo "Your Chef server is ready!"
