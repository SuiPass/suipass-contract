ORIGINAL_PACKAGE_ADDR="0x3b037649eeb48e8e2e41622f7740ee5cfb8335d8fc8fa83324a6e3030f89835a"

PACKAGE_ADDR="0x3b037649eeb48e8e2e41622f7740ee5cfb8335d8fc8fa83324a6e3030f89835a"
UPGRADE_CAP="0x91119cc4f7c567d096eebe8cb0eddddac9417ddde462ea44f6f0f88fa547e5d6"

ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"

SUIPASS_ADDR="0x93ce031cf8366a7df69943496057a0d27d8a9d3e050efb2706623f93ac8cc2f8"
ADMIN_CAP="0x1b62fc816d443dd92be949baff69b15338cb94554ddf90c8b22d37c28947cdf6"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0x3337bbeef512de4c202f472d07ccffc88c4f91f6c94a46f18115c50ac41d9b3a"

GAS=100000000

pbuild:
	sui move build

key-list:
	sui keytool list

owner:
	sui client switch --address ${ADDR}

faucet:
	ADDR=${ADDR} sh ./scripts/faucet.sh

publish: owner
	sui client publish --json --gas-budget ${GAS} build/suipass

upgrade: owner pbuild
	sui client upgrade --gas-budget ${GAS} --json --upgrade-capability ${UPGRADE_CAP}

suipass:
	sui client object --json "${SUIPASS_ADDR}" | jq .

new_user:
	sui client call \
		--function new \
		--module user \
		--package ${PACKAGE_ADDR} \
		--args \
		"name: this is my fucking name..." \
		--gas-budget 100000000

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

resolve_request:
	sui client switch --address ${GITHUB_OWNER}
	sui client call \
		--function resolve_request \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--args \
		${GITHUB_CAP} \
		${SUIPASS_ADDR} \
		"0xcae0abb9726272bccf2d3aa5685bf66c0b7ba65f576e9ebb019f3fef732ae6b1" \
		"evidence ne" \
		2 \
		--gas-budget 100000000
		
