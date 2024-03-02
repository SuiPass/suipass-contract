PACKAGE_ADDR="0x23fa5000e2b86dade4f58fb64bbc68c8996572ac6574310e446d69dd2ca550be"

key-list:
	sui keytool list

faucet:
	ADDR=0xe4bf3390a02c8c435f6f6817e1ad264933df4a07ddbe7f126501423bc5329398 sh ./scripts/faucet.sh

publish:
	sui client publish --gas-budget 100000000 build/suipass

upgrade:
	sui client upgrade --gas-budget 100000000 --upgrade-capability 0x494ec0780a7a0603395b8317ac65d36514868f2ddde05a39f9741c9d3e88a6a8

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

