PACKAGE_ADDR="0x893a695f0c09af2b50d60b701140baa1e2d5ae6796eb12c9134cf1f024f1982c"
UPGRADE_CAP="0x8279f2d4e6b48837569a81fdfdd9480a0c451060ba2168e07bdd86a388d87b8a"

ADDR="0xe4bf3390a02c8c435f6f6817e1ad264933df4a07ddbe7f126501423bc5329398"

GAS=100000000

pbuild:
	sui move build

key-list:
	sui keytool list

faucet:
	ADDR=${ADDR} sh ./scripts/faucet.sh

publish:
	sui client publish --gas-budget ${GAS} build/suipass

upgrade:
	sui client upgrade --gas-budget ${GAS} --upgrade-capability ${UPGRADE_CAP}

add_provider:
	sui client call \
		--function add_provider \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--args \
			0xb5ec6b86102cf55ecf37f7039cc226f64d89b09e94da38112e352a52bad95a9e \
			0x0a120e0a622dfdcb24f54adc112ae498075077379d7f6ae9c8dbb19e3ad7e34b \
			10 \
		--gas-budget 100000000

