#! /bin/bash

aws ec2 describe-images       --owners aws-marketplace       --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce       --query 'Images[*].[CreationDate,Name,ImageId]'       --filters "Name=name,Values=CentOS Linux 7*"       --region ca-west-1       --output table  --include-deprecated   | sort -r

