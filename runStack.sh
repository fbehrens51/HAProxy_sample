#!/usr/bin/env bash

set -ex
curr_dir=$PWD

export AWS_DEFAULT_REGION="us-west-1"
##1.5  issue is that it doesn't support resolvers, so it will fail when ELB changes underlying IPs until you restart it
## So, I wouldn't recommend using it
#USER_DATA=$(cat haproxy_cloud_init.yml)
##1.8 is available in epel
USER_DATA=$(cat haproxy18_cloud_init.yml)
##2.x is available in amazon extras or directly from the haproxy site
#USER_DATA=$(cat haproxy2_cloud_init.yml)

jq --arg v "$USER_DATA"  '(.[] | select(.ParameterKey=="UserData") | .ParameterValue) |= $v' cf_params.json >tmp.json

aws cloudformation describe-stacks --stack-name haproxy-tcp >> /dev/null || EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]
then
  aws cloudformation update-stack --stack-name haproxy-tcp --template-body file://${curr_dir}/haproxy_cf.json --parameters file://${curr_dir}/tmp.json
else
  aws cloudformation create-stack --stack-name haproxy-tcp --template-body file://${curr_dir}/haproxy_cf.json --parameters file://${curr_dir}/tmp.json --on-failure DELETE
fi