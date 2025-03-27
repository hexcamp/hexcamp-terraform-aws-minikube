#! /bin/bash

set -euxo pipefail

# infra.hex.camp
HOSTED_ZONE_ID=Z008292835GVQ24RULSFV


IP=$(tofu output -raw public_ip)

if [ -z "$IP" ]; then
  echo "No IP available."
  exit
fi


export AWS_PROFILE=default

AWS_IP=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID | jq -r '.ResourceRecordSets[] | select(.Name == "ns-minikube10.infra.hex.camp.").ResourceRecords[0].Value')

if [ "$IP" = "$AWS_IP" ]; then
  echo No updated needed.
  exit
fi

# Update

JSON="$(cat <<EOF
    {
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "ns-minikube10.infra.hex.camp",
            "Type": "A",
            "TTL": 300,
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

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "$JSON" | cat

