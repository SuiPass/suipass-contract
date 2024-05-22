ORIGINAL_PACKAGE_ADDR="0xf94ffbd74fea44822455105f1b1a9430a1bee182e13b9ab223e3ddb84fb385f4"

PACKAGE_ADDR="0xf94ffbd74fea44822455105f1b1a9430a1bee182e13b9ab223e3ddb84fb385f4"
UPGRADE_CAP="0x38c70a6db13338fc191f07959e04abf158795a9b4debcc41ede4c21739e664a5"
ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"
SUIPASS_ADDR="0x24bee1879eff747dd1f27d548ef51d95c869c5467997e8b3f0877ed29cd99f5c"
ADMIN_CAP="0x60585ffb115a7cf79b092a8be90b08f3ee00713ebe763c060cac997b8f8b5c3a"

VERISOUL_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
VERISOUL_CAP="0x31762966be368eab2a92ab141524f6753f8b828ac512730424a86c4548a02f5d"
VERISOUL_PROVIDER_ID="0xfb72d6b3d78fa27bf4c05aac3314d8e9fd5ec5f798a982169c6c4533572db1b1"

SUI_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
SUI_CAP="0x6f393f601ae8d4df91d0c05279e673acb5daf9b26812dae63e0bf49f94bcc0dd"
SUI_PROVIDER_ID="0x4c2a4fcc32bceb371754fc4abcf4534247b0398475a7d662d0de56d87bad4d7d"

GOOGLE_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GOOGLE_CAP="0x2710b1c952d0a431c11c9115e994b57591d3bb8fb485253f62353b9b49dfd727"
GOOGLE_PROVIDER_ID="0xeb90d80ab05daedeaaafd44ae61ee7a093edcbf61d5359b3d916c2f32416285f"

TWITTER_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
TWITTER_CAP="0x323f7dc3e31d6f55a39dd492a53cc764c57b85efe7b5768faee24ec0869c623a"
TWITTER_PROVIDER_ID="0xee3f0636368cc431ca177d1e4e6119a80b0ea1ecd0102a30ecaa04b5f66d3b90"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0xb65efd93cb4c5d6e57606b51bccd02bd1b139323c98a099c3c1c6c7e0686fe05"
GITHUB_PROVIDER_ID="0xc4ee95428c5f3c91c358d1c7b6c1decaecd1b7f7476d2abe7fa2c417f8d02d3a"

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
		200 \
		--gas-budget 100000000
