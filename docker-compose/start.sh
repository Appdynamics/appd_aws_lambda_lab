#!/usr/bin/env bash

echo "Starting application..."
UNIQUE_HOST_ID=$(aws ec2 describe-instances --instance-ids $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --output text | grep PRIVATEIPADDRESSES | cut -f3)
APPDYNAMICS_AGENT_UNIQUE_HOST_ID=${UNIQUE_HOST_ID} docker-compose up -d