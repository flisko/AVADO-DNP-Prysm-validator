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

# Must used escaped \"$VAR\" to accept spaces: --graffiti=\"$GRAFFITI\"
COMMAND="/bin/validator \
  --mainnet \
  --datadir=/root/.eth2 \
  --rpc-host 0.0.0.0 \
  --grpc-gateway-host 0.0.0.0 \
  --monitoring-host 0.0.0.0 \
  --wallet-dir=/root/.eth2validators \
  --wallet-password-file=/root/.eth2wallets/wallet-password.txt \
  --write-wallet-password-on-web-onboarding \
  --web \
  --grpc-gateway-host=0.0.0.0 \
  --grpc-gateway-port=80 \
  --grpc-gateway-corsdomain=* \
  --accept-terms-of-use \
  ${EXTRA_OPTS}"


echo "Starting ${COMMAND}"

${COMMAND}
