ORIGINAL_PACKAGE_ADDR="0xc06eb9bbfb181618f0a6017a638402e346805034431c3a0873a5d63bcd2d034e"

PACKAGE_ADDR="0xc06eb9bbfb181618f0a6017a638402e346805034431c3a0873a5d63bcd2d034e"
UPGRADE_CAP="0x6f6e3476fcbf9572a8bd24b7a0d9d5d2a00dc183c75e6a5ce3c93c6d578774de"
ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"
SUIPASS_ADDR="0x34c61899bdd365d8b90f374530c4f31c698f34f8fdfd914143d242c2b283f395"
ADMIN_CAP="0x4d0cf2c2b77a23003804355e6796abacf7365682a12c43cf01583c9e01dc2add"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0x7a60394f5d9e698fd86d26e96319ddf41daeaf87cba421e71183e1f5e4d26a19"
GITHUB_PROVIDER_ID="0x71462ce878f28332faec6913b529c8d5b72da4b0bd0b8b26f1aa241cc7940ecb"

GAS=100000000

USER="0x9a2545cd5b2a0c9aa189842841e272133007093c1ff0d4a981d856bc2c22e31a"

pbuild:
	sui move build

key-list:
	sui keytool list

owner:
	@sui client switch --address ${ADDR}

faucet:
	ADDR=${ADDR} sh ./scripts/faucet.sh

publish: owner
	@sui client publish --json --gas-budget ${GAS} build/suipass > temp/deploy.json
	@export DATA=temp/deploy.json \
		&& export OUTPUT=.env.deploy \
		&& sh scripts/extract.sh

upgrade: owner pbuild
	sui client upgrade --gas-budget ${GAS} --json --upgrade-capability ${UPGRADE_CAP} > temp/upgrade.json
	@export DATA=temp/upgrade.json \
		&& export OUTPUT=.env.upgrade \
		&& sh scripts/extract.sh

suipass:
	sui client object --json "${SUIPASS_ADDR}" | jq .

new_user:
	sui client call \
		--function new \
		--module user \
		--package ${PACKAGE_ADDR} \
		--args \
		"name: this is my fucking name..." \
		--gas-budget 100000000 \
		--json

add_provider:
	sui client call \
		--function add_provider \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--json \
		--args \
			${ADMIN_CAP} \
			${SUIPASS_ADDR} \
			${GITHUB_OWNER} \
			"Github" \
			100 \
			50 \
			5 \
			1000 \
		--gas-budget 100000000

submit_request:
	sui client call \
		--function submit_request \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--json \
		--args \
			${SUIPASS_ADDR} \
			${GITHUB_PROVIDER_ID} \
			"authenticationCode?" \
			"0x8419f0716daf5210e668444eaa4cea67a4bbc85b853e37ddb2564270ddec3864" \
		--gas-budget 100000000

resolve_request:
	sui client switch --address ${GITHUB_OWNER}
	sui client call \
		--function resolve_request \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--json \
		--args \
		${GITHUB_CAP} \
		${SUIPASS_ADDR} \
		"0xb2698873d035afc83521c31a4b4e83b60d5c39c090c698a98831cee70a2e70e3"  \
		"evidence ne" \
		2 \
		--gas-budget 100000000
		
