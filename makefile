ORIGINAL_PACKAGE_ADDR="0x2ee0ff8227725610eb9af72c8df358709277c4457c59b3ac67187ab549aa0d92"

PACKAGE_ADDR="0x674e1ce02979374bcad200e28c224bd06e502dc98c91d50c87493d8d411e1b9f"
UPGRADE_CAP="0x2a51ac8b492e39b5c5580b92c8da1203add4063c6b5ae7bc175d2c4b52dd08f9"

ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"

SUIPASS_ADDR="0x8cd77f3bd5149d50c1e0655ad18c07c546a723cf86ca3eec5a250891a708744e"
ADMIN_CAP="0x639da3f5220ce4adeeae1eecf6a3040c6e7a9e2c9bd9d6d85455c4a73dcbe7fe"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0xa21439f94d1408de38b68b899d4662adc213461fe166c5767c1d6d6e90824aa8"
GITHUB_PROVIDER_ID="0xff33d62dbb85e6dd131b994cb228bad33f092ecde51f346fe1d8c8ffa76f8015"

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
		
