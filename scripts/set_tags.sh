#!/bin/bash

# Install additional requirements
sudo apt-get update && sudo apt-get install -y python-pip
sudo pip install awscli

# Get spot instance request tags to tags.json file
aws --region $1 ec2 describe-spot-instance-requests --spot-instance-request-ids $2 --query 'SpotInstanceRequests[0].Tags' > tags.json
RESULT=$?

if [ $RESULT == 0 ]; then
  # Set instance tags from tags.json file
  aws --region $1 ec2 create-tags --resources $3 --tags file://tags.json && rm -rf tags.json
else
  echo "Failed to get spot request tags!"
  exit $RESULT
fi
