#!/bin/bash

# Usage: ./install_chef_backend.sh BACKEND_VERSION BACKEND_FQDN <PRIMARY_BE_FQDN>
# BACKEND_VERSION - specify "latest" to install the most recent version or a valid version to install
# BACKEND_FQDN - FQDN for the machine that is this machine
# PRIMARY_BE-FQDN - optional, this is the hostname for the primary backend server.  If not provided then it's assumed
#                   this will be the primary backend

set -x

package_version=$1
chef_backend_fqdn=$2
# this is optional, if not provided then we configure this node as the primary
chef_backend_primary_fqdn=$3

if [ -n "${package_version}"]; then
  package_version="latest"
fi

# configure system to use AWS public hostname
echo $(curl -s http://169.254.169.254/latest/meta-data/public-hostname) | xargs sudo hostnamectl set-hostname

# create staging directories
if [ ! -d /drop ]; then
  mkdir /drop
fi

# install Chef server
if [ ! $(which chef-backend-ctl) ]; then
  echo "Installing Chef backend..."
  curl -LO https://omnitruck.chef.io/install.sh && sudo bash ./install.sh -P chef-backend -v $package_version

  echo "publish_address '$chef_backend_fqdn'" >> /etc/chef-backend/chef-backend.rb

  if [ -z "$chef_backend_primary_fqdn" ]; then
    # no primary fqdn so we must be it
    chef-backend-ctl create-cluster --accept-license --yes --quiet
    # copy secrets off to the side so we can fetch them from the other backend nodes
    # TODO: clean this file up after all the backends have been configured
    cp /etc/chef-backend/chef-backend-secrets.json /drop
    chmod a+r /drop/chef-backend-secrets.json
  else
    chef-backend-ctl join-cluster $chef_backend_primary_fqdn -s /tmp/chef-backend-secrets.json --accept-license --yes --quiet
    rm /tmp/chef-backend-secrets.json
  fi
else
  echo "chef-backend-ctl found, assuming the cluster is already configured"
  echo "Goodbye!"
fi
