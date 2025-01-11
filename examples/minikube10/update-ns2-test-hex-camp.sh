#! /bin/bash

set -euxo pipefail

# hex.camp
HOSTED_ZONE_ID=Z0776169RPXDLRHZOI9Q

IP=$(tofu output -raw public_ip)


# Update

JSON="$(cat <<EOF
    {
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "ns2.test.hex.camp",
            "Type": "A",
            "TTL": 30,
            "ResourceRecords": [
              {
                "Value": "$IP"
              }
            ]
          }
        }
      ]
    }
EOF
)"

echo $JSON

export AWS_PROFILE=default

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "$JSON" | cat

