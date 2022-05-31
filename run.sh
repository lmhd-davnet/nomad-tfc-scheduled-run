#!/usr/bin/env bash

# exit on fail
set -e
set -o pipefail

# output commands
debug=${DEBUG:-false}
if ${debug}; then
	echo debug mode enabled
	set -x
fi

# Source credentials from .env file if it exists
if test -f ".env"; then
	source .env
fi

# Default env vars
if [[ -z "${ORG}" ]]; then
	ORG="lmhd"
fi


# List Workspaces
# https://www.terraform.io/cloud-docs/api-docs/workspaces#list-workspaces
#
# TODO: handle pagination
curl -s \
	--header "Authorization: Bearer ${TOKEN}" \
	--header "Content-Type: application/vnd.api+json" \
	https://app.terraform.io/api/v2/organizations/${ORG}/workspaces \
	| jq . \
	> workspaces.json

# Get workspaces with the tags we want
cat workspaces.json \
	| jq '[ .data[] | select(.attributes."tag-names" | index("auto:daily")) | {id:.id, name:.attributes.name} ]' \
	> tagged-workspaces.json

# Result looks something like this:
#
#[
#  {
#    "id": "ws-42TEwCaYG3utWhxu",
#    "name": "bootstrap"
#  },
#  {
#    "id": "ws-mHMG4HMRvW91o8nM",
#    "name": "dns"
#  }
#]


# TODO: Create Runs
# https://www.terraform.io/cloud-docs/api-docs/run#create-a-run
for ws in $(cat tagged-workspaces.json | jq -c .[]); do

	id=$(echo ${ws} | jq -r .id)
	name=$(echo ${ws} | jq -r .name)

	echo "Triggering Run on ${name} (${id})"

	cat > payload.json <<EOF
{
	"data": {
		"attributes": {
			"message": "Triggered by Nomad"
		},
		"type":"runs",
		"relationships": {
			"workspace": {
				"data": {
					"type": "workspaces",
					"id": "${id}"
				}
			}
		}
	}
}
EOF

	curl -s \
		--header "Authorization: Bearer $TOKEN" \
		--header "Content-Type: application/vnd.api+json" \
		--request POST \
		--data @payload.json \
		https://app.terraform.io/api/v2/runs \
		> runs.json

	if ${debug}; then
		cat runs.json | jq .
	fi
done

