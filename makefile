ORIGINAL_PACKAGE_ADDR="0x98766e85ae3198e64493e7dd5b1a13fe876c5cd57c4f9a10537d3fe8e278e8d8"

PACKAGE_ADDR="0x98766e85ae3198e64493e7dd5b1a13fe876c5cd57c4f9a10537d3fe8e278e8d8"
UPGRADE_CAP="0xf3260b9f63e8ddd46ff34cd69e0ddd879a0c27100782204e0f7581e780919f02"
ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"
SUIPASS_ADDR="0x9247a7d49fc88a0f79ca9713a2c835dacad468a8b530a61c38ec1894b2642d97"
ADMIN_CAP="0x956830a4b41b246d7ef991ec5d85975fd89620a7f9ff3c59cf0c13fd1a578f4a"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0xc95937061ee6df57a1b8a21ef89d875a89fe9ecfc885cdb99c849d9189fc2383"
GITHUB_PROVIDER_ID="0xeafb09e7c672f62d17d4ac4b289f80927bf7e34f93755036286383765b415908"

TWITTER_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
TWITTER_CAP="0x8b3c7f06fc90be5120456c6042f9e69d1d884c1a90a9916a11dd3de903fa3d0e"
TWITTER_PROVIDER_ID="0x4f4c771cd89cc4295d6940fc823b69d308cab5d9323a10cf009c65fa685401e8"

GOOGLE_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GOOGLE_CAP="0xec28999389d99619ebad2d1af096170a797468c7b1162e5687684aa054c9f5d6"
GOOGLE_PROVIDER_ID="0x92e59c2699cbac55eb91a152403f0b0a14d5c64f1ea10d9e5d7c9251d9673add"

LINKEDIN_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
LINKEDIN_CAP="0x2512ea833789bb41438c765aa1981f7d4cdf3912bab85688b351efb2582d47fe"
LINKEDIN_PROVIDER_ID="0xfc7872b9a5f2b7a7a01a7bc0fa1bc2b8c3e05a6f6b3ab9c5bc0bc7e22838ed7d"

VERISOUL_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
VERISOUL_CAP="0x1fbe54ba1f05f93fcc7ce639ac04b6c351012803ccc9ec9e535c0c3c82b54c12"
VERISOUL_PROVIDER_ID="0xa98fb81058bf366ad953f593313fe438a7c82c3a1929cec31397e576f2498ac8"

SUI_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
SUI_CAP="0xd0ff666d0abdccfb87456375076ade0c89c356c59054e50adfc6ff960c5f01e5"
SUI_PROVIDER_ID="0x9e4700917ca3f6609474df1913f1a5871519357ddfcc39928d7c8c2de12c03cc"

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

provider:
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

data:
	sui client object --json 0x9247a7d49fc88a0f79ca9713a2c835dacad468a8b530a61c38ec1894b2642d97 > suipass-capture.json
	sui client objects --json 0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182 > provider-owner-capture.json
	jq '[.[] | {id: .data.objectId, content: .data.content}]' provider-owner-capture.json > provider-owner-filtered.json
