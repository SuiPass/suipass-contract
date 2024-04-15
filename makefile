ORIGINAL_PACKAGE_ADDR="0x19f445bb486a00a548f990a015f202ae5bf8cd85affdae94b073ed842c9e7cb4"

PACKAGE_ADDR="0x19f445bb486a00a548f990a015f202ae5bf8cd85affdae94b073ed842c9e7cb4"
UPGRADE_CAP="0x5244fcf9e1b741760e848922d9af9267484a654f7012ae82b8dc940579213874"
ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"
SUIPASS_ADDR="0xf50a1569efc95ebbb837110d8104fce064639e783694cdd9a20ef805e12380de"
ADMIN_CAP="0x197017c881cffe46984a34cb5ceab7322e2123d9cec74aac03a06717d75d1550"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0x41ce7cceffdad57f9dd390052197a75a679621457380a0f4fc2fab3321e04cd9"
GITHUB_PROVIDER_ID="0x50581dae10313e3460821fe0d9f4a3929c25a82a88974e6ec28af8b901683b3a"

TWITTER_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
TWITTER_CAP="0x9a878e98fc58a8bc4df584c50c645736363dec9f56ff4b701cdc8fc498d978cf"
TWITTER_PROVIDER_ID="0xe9f29c68c836590e76b8219ef1d1722b806f1c5beeb25954c8053ab1e6974a6a"

GOOGLE_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GOOGLE_CAP="0x9aec9300713e62464e19eba933e84335507e6f0c9501fc3d7b772a01fe3287f9"
GOOGLE_PROVIDER_ID="0x9cb483e777bd2e7f27a4cc16bca39448c7bda743c53794a8116d6141e8e090eb"

SUI_PROVIDER_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
SUI_PROVIDER_CAP="0xd5420fce5c107690c27a0f7456a5bf8454a31c7f372d08ca233a324274836763"
SUI_PROVIDER_PROVIDER_ID="0x168b1502b047d7e77f83da38e99b1a4081feedce79cc27d4e9c19a15ebf9a6ea"

# LINKEDIN_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
# LINKEDIN_CAP="0x2512ea833789bb41438c765aa1981f7d4cdf3912bab85688b351efb2582d47fe"
# LINKEDIN_PROVIDER_ID="0xfc7872b9a5f2b7a7a01a7bc0fa1bc2b8c3e05a6f6b3ab9c5bc0bc7e22838ed7d"
#
# VERISOUL_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
# VERISOUL_CAP="0x1fbe54ba1f05f93fcc7ce639ac04b6c351012803ccc9ec9e535c0c3c82b54c12"
# VERISOUL_PROVIDER_ID="0xa98fb81058bf366ad953f593313fe438a7c82c3a1929cec31397e576f2498ac8"


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
		&& sh scripts/extract.sh \
		&& sh scripts/load_provider.sh

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

sync-provider:
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
	sui client object --json ${SUIPASS_ADDR} > suipass-capture.json
	sui client objects --json ${GITHUB_OWNER} > provider-owner-capture.json
	jq '[.[] | {id: .data.objectId, content: .data.content}]' provider-owner-capture.json > provider-owner-filtered.json

update_metadata:
	VAL='{"desc": "Verify SUI activity.", "logoUrl": "https://firebasestorage.googleapis.com/v0/b/suipass.appspot.com/o/sui-logo.svg?alt=media&token=29ad950f-70dd-4d96-a041-f240a9c0fa82",  "levels": [ { "desc": "The balance is higher than 1 SUI", "level": 1 }, { "desc": "Created at least 90 days ago and the balance is higher than 5 SUI", "level": 2 }, { "desc": "Created at least 365 days ago and the balance is higher than 10 SUI", "level": 3 } ] }'
	echo $(VAL)

	sui client call \
		--function update_provider \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--json \
		--args \
		${SUI_PROVIDER_CAP} \
		${SUIPASS_ADDR} \
		'["eyJkZXNjIjogIlZlcmlmeSBTVUkgYWN0aXZpdHkuIiwgImxvZ29VcmwiOiAiaHR0cHM6Ly9maXJlYmFzZXN0b3JhZ2UuZ29vZ2xlYXBpcy5jb20vdjAvYi9zdWlwYXNzLmFwcHNwb3QuY29tL28vc3VpLWxvZ28uc3ZnP2FsdD1tZWRpYSZ0b2tlbj0yOWFkOTUwZi03MGRkLTRkOTYtYTA0MS1mMjQwYTljMGZhODIiLCAgImxldmVscyI6IFsgeyAiZGVzYyI6ICJUaGUgYmFsYW5jZSBpcyBoaWdoZXIgdGhhbiAxIFNVSSIsICJsZXZlbCI6IDEgfSwgeyAiZGVzYyI6ICJDcmVhdGVkIGF0IGxlYXN0IDkwIGRheXMgYWdvIGFuZCB0aGUgYmFsYW5jZSBpcyBoaWdoZXIgdGhhbiA1IFNVSSIsICJsZXZlbCI6IDIgfSwgeyAiZGVzYyI6ICJDcmVhdGVkIGF0IGxlYXN0IDM2NSBkYXlzIGFnbyBhbmQgdGhlIGJhbGFuY2UgaXMgaGlnaGVyIHRoYW4gMTAgU1VJIiwgImxldmVsIjogMyB9IF0gfQo="]' \
		'[]' \
		'[]' \
		'[]' \
		--gas-budget 100000000
