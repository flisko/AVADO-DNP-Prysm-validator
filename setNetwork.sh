#!/bin/bash

NETWORK=$1

case ${NETWORK} in
  "prater"|"mainnet")
    ;;
  *)
    echo "Invalid network"
    exit
    ;;
esac

for file in \
    build/docker-compose.yml \
    dappnode_package.json \
    build/avatar.png \
    build/wizard/src/consts.js

do
    BASENAME=${file%.*}
    EXT=${file##*.}
    # echo $BASENAME
    # echo $EXT
    rm -f $file
    ln ${BASENAME}-${NETWORK}.${EXT} $file
done