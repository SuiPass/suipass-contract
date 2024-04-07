#!/bin/bash

# Assuming the JSON content is stored in 'data.json'
json_file=$DATA
output_file=$OUTPUT

# Extract values using jq
PACKAGE_ADDR=$(jq -r '.objectChanges[] | select(.packageId != null) | .packageId' "$json_file")
UPGRADE_CAP=$(jq -r '.objectChanges[] | select(.objectType == "0x2::package::UpgradeCap") | .objectId' "$json_file")
ADDR=$(jq -r '.objectChanges[] | select(.owner.AddressOwner != null) | .owner.AddressOwner' "$json_file" | uniq)
SUIPASS_ADDR=$(jq -r '.objectChanges[] | select((.objectType != null) and ((.objectType | type) == "string") and (.objectType | endswith("::SuiPass"))) | .objectId' "$json_file")
ADMIN_CAP=$(jq -r '.objectChanges[] | select((.objectType != null) and ((.objectType | type) == "string") and (.objectType | endswith("::AdminCap"))) | .objectId' "$json_file")

# Ensure the variables are not empty before echoing them
if [ -n "$PACKAGE_ADDR" ]; then echo "PACKAGE_ADDR=\"$PACKAGE_ADDR\"" >"$OUTPUT"; fi
if [ -n "$UPGRADE_CAP" ]; then echo "UPGRADE_CAP=\"$UPGRADE_CAP\"" >>"$OUTPUT"; fi
if [ -n "$ADDR" ]; then echo "ADDR=\"$ADDR\"" >>"$OUTPUT"; fi
if [ -n "$SUIPASS_ADDR" ]; then echo "SUIPASS_ADDR=\"$SUIPASS_ADDR\"" >>"$OUTPUT"; fi
if [ -n "$ADMIN_CAP" ]; then echo "ADMIN_CAP=\"$ADMIN_CAP\"" >>"$OUTPUT"; fi

# Display the extracted values
cat "$OUTPUT"
