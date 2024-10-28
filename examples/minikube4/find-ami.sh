#! /bin/bash

aws ec2 describe-images --owners aws-marketplace --include-deprecated --filters 'Name=name,Values="CentOS*"' 'Name=architecture,Values=x86_64' --region ca-west-1
