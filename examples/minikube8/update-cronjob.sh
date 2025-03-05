#! /bin/sh

export AWS_ACCESS_KEY_ID=$LOCALNET_FARM_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$LOCALNET_FARM_SECRET_ACCESS_KEY
mkdir -p /root/.ssh
echo $SSH_RSA_PUB > /root/.ssh/id_rsa.pub

if [ ! -d .terraform ]; then
  tofu init
fi

tofu apply -auto-approve
