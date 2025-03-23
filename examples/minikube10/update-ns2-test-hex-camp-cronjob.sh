#! /bin/sh

set -euxo pipefail

# hex.camp
HOSTED_ZONE_ID=Z0776169RPXDLRHZOI9Q

export AWS_ACCESS_KEY_ID=$LOCALNET_FARM_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$LOCALNET_FARM_SECRET_ACCESS_KEY

IP=$(tofu output -raw public_ip)

if [ -z "$IP" ]; then
  echo "No IP available."
  exit
fi


# Update

export AWS_ACCESS_KEY_ID=$JIMPICK_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$JIMPICK_SECRET_ACCESS_KEY

AWS_IP=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID | \
        jq -r '.ResourceRecordSets[] | select(.Name == "ns2.test.hex.camp.").ResourceRecords[0].Value')

if [ "$IP" = "$AWS_IP" ]; then
  echo No updated needed.
  exit
fi

JSON="$(cat <<EOF
    {
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "ns2.test.hex.camp",
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

