#!/bin/bash

echo "Start nginx"

nginx

echo "Generating auth token"
mkdir -p "/root/.eth2validators"

# Create a new wallet if necessary
if [ ! -f "/root/.eth2validators/walletpassword.txt" ]; then
  echo "Create wallet"
  openssl rand -hex 12 | tr -d "\n" > /root/.eth2validators/walletpassword.txt
  chmod 0600 /root/.eth2validators/walletpassword.txt
  /bin/validator wallet create --wallet-dir=/root/.eth2validators --keymanager-kind=imported --wallet-password-file=/root/.eth2validators/walletpassword.txt --accept-terms-of-use
fi

# Check wallet: list contents
/bin/validator accounts list  --wallet-dir=/root/.eth2validators --wallet-password-file=/root/.eth2validators/walletpassword.txt

# remove old token if it's there
rm -f /root/.eth2validators/auth-token

# generate new token
validator web generate-auth-token --wallet-dir=/root/.eth2validators --accept-terms-of-use

# remove old token if it's there
rm -f /usr/share/nginx/wizard/auth-token.txt

# copy new token to wizard for authentication link
cat /root/.eth2validators/auth-token | tail -1 >/usr/share/nginx/wizard/auth-token.txt
chmod 644 /usr/share/nginx/wizard/auth-token.txt

SETTINGSFILE=/root/settings.json

if [ ! -f "${SETTINGSFILE}" ]; then
  echo "Starting with default settings"
  cat <<EOT >>${SETTINGSFILE}
{
    "network": "mainnet",
    "validators_graffiti": "Avado"
}
EOT
fi

NETWORK=$(cat ${SETTINGSFILE} | jq -r '."network"')

# Workaround for fee recipient in RocketPool/Prysm
PROPOSER_SETTINGS_PATH="/root/.eth2validators/proposer_settings.json"
MEV_BOOST_ENABLED=$(cat ${SETTINGSFILE} | jq -r '."mev_boost" // false')
if [ -f "${PROPOSER_SETTINGS_PATH}" ]; then
  DEFAULT_FEE_ADDRESS=$(cat ${SETTINGSFILE} | jq -r '."validators_proposer_default_fee_recipient"')
  PROPOSER_DEFAULT=$(cat ${PROPOSER_SETTINGS_PATH} | jq -r '.default_config.fee_recipient')

  cat ${PROPOSER_SETTINGS_PATH} | jq '(.default_config.fee_recipient) |= "'${DEFAULT_FEE_ADDRESS}'"' >${PROPOSER_SETTINGS_PATH}.tmp
  mv ${PROPOSER_SETTINGS_PATH}.tmp ${PROPOSER_SETTINGS_PATH}

  cat ${PROPOSER_SETTINGS_PATH} | jq '(.default_config.builder.enabled) |= '${MEV_BOOST_ENABLED} >${PROPOSER_SETTINGS_PATH}.tmp
  mv ${PROPOSER_SETTINGS_PATH}.tmp ${PROPOSER_SETTINGS_PATH}

  PROPOSER_SETTINGS_FILE="${PROPOSER_SETTINGS_PATH}"
fi

echo "Starting validator"

set -u
set -o errexit

GRAFFITI=$(cat ${SETTINGSFILE} | jq '."validators_graffiti" // empty' | tr -d '"')
VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT=$(cat ${SETTINGSFILE} | jq '."validators_proposer_default_fee_recipient" // empty' | tr -d '"')

echo "Configuration:"
echo "Graffiti: \"${GRAFFITI}\""
echo "Fee recipient: \"${VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT}\""
echo "Extra opts: \"${EXTRA_OPTS}\""

exec /bin/validator \
  --${NETWORK} \
  --datadir="/root/.eth2" \
  --rpc-host="0.0.0.0" \
  --grpc-gateway-host="0.0.0.0" \
  --monitoring-host="0.0.0.0" \
  --wallet-dir="/root/.eth2validators" \
  --web \
  --wallet-password-file=/root/.eth2validators/walletpassword.txt \
  --rpc \
  --grpc-gateway-host="0.0.0.0" \
  --grpc-gateway-port=7500 \
  --grpc-gateway-corsdomain="*" \
  --accept-terms-of-use \
  --graffiti="${GRAFFITI}" \
  ${PROPOSER_SETTINGS_FILE:+--proposer-settings-file=${PROPOSER_SETTINGS_FILE}} \
  --beacon-rpc-provider=prysm-beacon-chain-${NETWORK}.my.ava.do:4000 \
  --beacon-rpc-gateway-provider=prysm-beacon-chain-${NETWORK}.my.ava.do:3500 \
  ${VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT:+--suggested-fee-recipient=${VALIDATORS_PROPOSER_DEFAULT_FEE_RECIPIENT}} \
  ${MEV_BOOST_ENABLED:+--enable-builder} \
  ${EXTRA_OPTS}
