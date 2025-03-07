#! /bin/sh

set -euxo pipefail

export AWS_ACCESS_KEY_ID=$LOCALNET_FARM_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$LOCALNET_FARM_SECRET_ACCESS_KEY

MINIKUBE10=$(cd examples/minikube10; tofu output -raw public_ip)
echo minikube10: $MINIKUBE10
MINIKUBE7=$(cd examples/minikube7; tofu output -raw public_ip)
echo minikube7: $MINIKUBE7
MINIKUBE8=$(cd examples/minikube8; tofu output -raw public_ip)
echo minikube8: $MINIKUBE8
MINIKUBE9=$(cd examples/minikube9; tofu output -raw public_ip)
echo minikube9: $MINIKUBE9

jq -n " \
  .minikube10_ip=\"$MINIKUBE10\" | \
  .minikube7_ip=\"$MINIKUBE7\" | \
  .minikube8_ip=\"$MINIKUBE8\" | \
  .minikube9_ip=\"$MINIKUBE9\"" > /tmp/ips.json

# https://stackoverflow.com/questions/7642743/how-to-generate-random-numbers-in-the-busybox-shell
ID=$(</dev/urandom tr -dc A-Za-z0-9-_ | head -c 22 || true)

curl -i $K_SINK \
  -H "Content-Type: application/json" \
  -H "Ce-Id: $ID" \
  -H "Ce-Specversion: 1.0" \
  -H "Ce-Type: camp.hex.ce.tofu-ips" \
  -H "Ce-Source: ryzen9.repair" \
  -d @/tmp/ips.json

