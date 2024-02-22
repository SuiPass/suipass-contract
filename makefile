key-list:
	sui keytool list

faucet:
	ADDR=0xe4bf3390a02c8c435f6f6817e1ad264933df4a07ddbe7f126501423bc5329398 sh ./scripts/faucet.sh

publish:
	sui client publish --gas-budget 100000000 build/suipass

call:
	sui client call \
		--function addProvider \
		--module suipass \
		--package 0x9759044312f30c15d0d7d56564f3a8b5daeeecd8fba2c2dfa34b356d1c8cb3d4 \
		--args 0xb5ec6b86102cf55ecf37f7039cc226f64d89b09e94da38112e352a52bad95a9e 0x0a120e0a622dfdcb24f54adc112ae498075077379d7f6ae9c8dbb19e3ad7e34b 10 \
		--gas-budget 100000000

