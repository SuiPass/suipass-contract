ORIGINAL_PACKAGE_ADDR="0xf50f3289e2386f2b4e4a8c5472ae65a83cb9f64c68452daaa1f28177b468b1c5"

PACKAGE_ADDR="0xf50f3289e2386f2b4e4a8c5472ae65a83cb9f64c68452daaa1f28177b468b1c5"
UPGRADE_CAP="0xb5e8ea8d14e3bd08213fcad294ed4508052e87dc0d835456c352d615caa41473"
ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"
SUIPASS_ADDR="0xa80f2b50d75a385d55d04251a9ad28a7d430de7c88fca94fa5284295609f68fe"
ADMIN_CAP="0xf74dd0ce2badf73d8d012a5e40d0610b4d8b2bba4050772ab7de911087a2f1c8"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0xd4b784b780235248abde35680a426b8c69930b8bd0dcab17c41b4d8100fab726"
GITHUB_PROVIDER_ID="0xe0e42d8acc5c0ac632c7d2ed6fdf93bbfc40ce0c5f45291507b43b1fb44c22ef"

TWITTER_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
TWITTER_CAP="0xbc336a1a0f33229c077088bdbd8fe81a4a82bb576c3ff71708a4587fee701e48"
TWITTER_PROVIDER_ID="0x23fe1f47d72bc8e5af3924211f05dec36c73d796326cf1ed35e9b5c49a7cba4e"

GOOGLE_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GOOGLE_CAP="0x024cede8dc754abf79d58fab3083f0ef265a5a60581d699beafa78e2d3e3cd50"
GOOGLE_PROVIDER_ID="0x23cadd8a85c7df44b25f6b88a8804c80882d255b0af7e419f8f70d8daad5d182"

SUI_PROVIDER_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
SUI_PROVIDER_CAP="0xb530427a276e4e6fab5f2d5fbdcf6329a032d37f2ee0f4fc4a759b6bdbb566a1"
SUI_PROVIDER_PROVIDER_ID="0x92c9c73661a66394cdf076200e06d39f0a1e3067736c268683616f45c77072b1"

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

publish: build owner
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
	sh ./scripts/sync_provider.sh

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

create_enterprise:
	sui client call \
		--function create_enterprise \
		--module enterprise \
		--package ${PACKAGE_ADDR} \
		--json \
		--args \
		${ADMIN_CAP} \
		${SUIPASS_ADDR} \
		"0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182" \
		"Tinguyen" \
		"{"hello": "hello01"}" \
		'['${GITHUB_PROVIDER_ID}', '${TWITTER_PROVIDER_ID}']' \
		--gas-budget 100000000
