key-list:
	sui keytool list

faucet:
	ADDR=0xe4bf3390a02c8c435f6f6817e1ad264933df4a07ddbe7f126501423bc5329398 sh ./scripts/faucet.sh

publish:
	sui client publish --gas-budget 100000000 build/suipass

