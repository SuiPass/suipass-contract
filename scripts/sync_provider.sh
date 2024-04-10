#!/bin/bash

source .env

echo "Load data from provider.json"

cat scripts/provider.json | jq -c '.[]' | while read -r provider; do
	cap=$(echo $provider | jq -r '.cap')
	providerName=$(echo $provider | jq -r '.name')
	metadata=$(echo $provider | jq -r '.metadata' | base64)
	submitFee=$(echo $provider | jq -r '.submitFee')
	updateFee=$(echo $provider | jq -r '.updateFee')
	totalLevels=$(echo $provider | jq -r '.totalLevels')
	score=$(echo $provider | jq -r '.score')
	owner=$(echo $provider | jq -r '.owner')

	sui client call \
		--function update_provider \
		--module suipass \
		--package ${PACKAGE_ADDR} \
		--json \
		--args \
		${!cap} \
		${SUIPASS_ADDR} \
		'["'${metadata}'"]' \
		'['${submitFee}']' \
		'['${updateFee}']' \
		'['${score}']' \
		--gas-budget 100000000

	# sui client call \
	# 	--function update_provider_score \
	# 	--module suipass \
	# 	--package ${PACKAGE_ADDR} \
	# 	--json \
	# 	--args \
	# 	${ADMIN_CAP} \
	# 	${SUIPASS_ADDR} \
	# 	id \
	# 	'['${score}']' \
	# 	--gas-budget 100000000
done
