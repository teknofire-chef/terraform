#!/bin/bash
usage="Usage: $(basename "$0") ADMIN_PASSWORD [VERSION]"

admin_password=$1
package_version=$2
if [ -n "${package_version}" ]; then
  package_version="latest"
fi

if [[ $# -lt 1 ]]; then
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
if [ ! $(sudo chef-server-ctl user-list | grep teknofire) ]; then
  echo "Creating chef admin user and tekno organization..."
  chef-server-ctl user-create teknofire will fisher will@teknofire.net $admin_password --filename /drop/teknofire.pem
  chef-server-ctl org-create tekno "Tekno, Inc." --association_user teknofire --filename default-validator.pem
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
