ORIGINAL_PACKAGE_ADDR="0xfb716597619494de6f2c5b8b82b5947f530dab82f63009e4027e126b8f3d9787"

PACKAGE_ADDR="0xfb716597619494de6f2c5b8b82b5947f530dab82f63009e4027e126b8f3d9787"
UPGRADE_CAP="0x492145c7bc5fd925a966862af320ee3656ff89755278c65dd5bf41ad4d4867f6"
ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"
SUIPASS_ADDR="0x97b873c6ebae75bd98ec5aa41d3b356f349def5f014d7a0599812ee035a55271"
ADMIN_CAP="0x84b876a71a717f075705aeced221c6ae70d8c0714b329b5d747efc4c3b449d5a"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0x7a60394f5d9e698fd86d26e96319ddf41daeaf87cba421e71183e1f5e4d26a19"
GITHUB_PROVIDER_ID="0x71462ce878f28332faec6913b529c8d5b72da4b0bd0b8b26f1aa241cc7940ecb"

GAS=100000000

USER="0x9a2545cd5b2a0c9aa189842841e272133007093c1ff0d4a981d856bc2c22e31a"

.PHONY: test
.PHONY: clean
.PHONY: build
.PHONY: all

test:
	sui move test

build:
	sui move build

key-list:
	sui keytool list

owner:
	@sui client switch --address ${ADDR}

faucet:
	ADDR=${ADDR} sh ./scripts/faucet.sh

publish: test build owner
	@sui client publish --json --gas-budget ${GAS} build/suipass > temp/deploy.json
	@export DATA=temp/deploy.json \
		&& export OUTPUT=.env.deploy \
		&& sh scripts/extract.sh

upgrade: owner build
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
	sh ./scripts/load_provider.sh

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
