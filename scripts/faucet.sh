#!/bin/bash
# INPUT:
#   ADDR
curl --location --request POST 'https://faucet.testnet.sui.io/gas' \
	--header 'Content-Type: application/json' \
	--data-raw '{
    "FixedAmountRequest": {
        "recipient": "'"$ADDR"'"
    }
}'
