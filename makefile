ORIGINAL_PACKAGE_ADDR="0xe17ae2684e56530316fff23319f43523f447a4772d740ec4629897228df20f55"

PACKAGE_ADDR="0xe917e4af4c5ccb402379770ebbf29d9da10ec178b7eae2aa8eca1a3fba89bbb1"
UPGRADE_CAP="0x87753ca7dde1e8a76eb4237ab107287149955cad9040005a1b542c3d06105864"

ADDR="0x57f105ec99c91f40b2a80b2bca774d81e197cb7032c97f0518ada7121f8f4b69"

SUIPASS_ADDR="0x07dde60f0d3b11c852b061f6d1197757e6e1c98cb15a22a7a955922085f177c2"
ADMIN_CAP="0x05ecc4e5e71cd6abf0c12d5aa5da3e24d16dbbad487164d558c07db375ee0dcd"

GITHUB_OWNER="0xed6f09f1f6bdc991edc10d3c82418aefc53cf6824ca23a44df4caea48a70b182"
GITHUB_CAP="0xf2c02c33a6cd8990b0be818a9bc2a2378e17e5ce6ac88a849ff7e1777ffcf7ad"

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

add_provider:
	sui client call \
		--function add_provider \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--args \
			${ADMIN_CAP} \
			${SUIPASS_ADDR} \
			${GITHUB_OWNER} \
			"Github" \
			10 \
			5 \
			5 \
			1000 \
		--gas-budget 100000000

resolve_request:
	sui client call \
		--function resolve_request \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--args \
		${GITHUB_CAP} \
		${SUIPASS_ADDR} \
		"0xe3ea11c64666cab98eb233433e2c2332bba0d3e21473c539ebc247613c8d281f" \
		"evidence ne" \
		2 \
		--gas-budget 100000000
		
