#!/bin/sh

echo "Start nginx"

nginx

echo "Generating auth token"
mkdir -p "/root/.eth2validators"

# remove old token if it's there
rm -f /root/.eth2validators/auth-token

# generate new token
validator web generate-auth-token --wallet-dir=/root/.eth2validators --accept-terms-of-use

# remove old token if it's there
rm -f /usr/share/nginx/wizard/auth-token.txt

# copy new token to wizard for authentication link
cat /root/.eth2validators/auth-token | tail -1 > /usr/share/nginx/wizard/auth-token.txt
chmod 644 /usr/share/nginx/wizard/auth-token.txt

echo "Starting validator"

set -u
set -o errexit

SETTINGSFILE=/root/settings.json
GRAFFITI=$(cat ${SETTINGSFILE} | jq '."validators_graffiti" // empty' | tr -d '"')
VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT=$(cat ${SETTINGSFILE} | jq '."validators_proposer_default_fee_recipient" // empty' | tr -d '"')

echo "Configuration:"
echo "Graffiti: \"${GRAFFITI}\""
echo "Fee recipient: \"${VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT}\""
echo "Extra opts: \"${EXTRA_OPTS}\""

/bin/validator \
  --mainnet \
  --datadir="/root/.eth2" \
  --rpc-host="0.0.0.0" \
  --grpc-gateway-host="0.0.0.0" \
  --monitoring-host="0.0.0.0" \
  --wallet-dir="/root/.eth2validators" \
  --wallet-password-file="/root/.eth2wallets/wallet-password.txt" \
  --write-wallet-password-on-web-onboarding \
  --web \
  --rpc \
  --grpc-gateway-host="0.0.0.0" \
  --grpc-gateway-port=7500 \
  --grpc-gateway-corsdomain="*" \
  --accept-terms-of-use \
  --graffiti="${GRAFFITI}" \
  --beacon-rpc-provider=my.prysm-beacon-chain-mainnet.avado.dnp.dappnode.eth:4000 \
  --beacon-rpc-gateway-provider=my.prysm-beacon-chain-mainnet.avado.dnp.dappnode.eth:3500 \
  ${VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT:+--suggested-fee-recipient=${VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT}} \
  ${EXTRA_OPTS}
