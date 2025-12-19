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
        jq -r '.ResourceRecordSets[] | select(.Name == "ns1.test.hex.camp.").ResourceRecords[0].Value')

if [ "$IP" = "$AWS_IP" ]; then
  echo No updated needed.
  exit
fi

update () {
  NAME="$1"
  JSON="$(cat <<EOF
    {
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "$NAME.hex.camp",
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
}

# Update ns1.test.hex.camp
update ns1.test

# Update ns-minikube9
update ns-minikube9.test

# Update ns-vichex-{1,2,3,4}.hex.camp
update ns-vichex-1
#update ns-vichex-2
#update ns-vichex-3
update ns-vichex-4

# Update ns-vanhex-{1,2,3,4}.hex.camp
#update ns-vanhex-1
#update ns-vanhex-2
#update ns-vanhex-3
#update ns-vanhex-4

# Update ns-seahex-{1,2,3,4}.hex.camp
#update ns-seahex-1
#update ns-seahex-2
#update ns-seahex-3
#update ns-seahex-4

# Update ns-islandhex-{1,2,3,4}.hex.camp
#update ns-islandhex-1
#update ns-islandhex-2
#update ns-islandhex-3
#update ns-islandhex-4

# Update ns-peerhex-{1,2,3,4}.hex.camp
#update ns-peerhex-1
#update ns-peerhex-2
#update ns-peerhex-3
#update ns-peerhex-4


