body_to_post=$(cat << EOF
### $body_message_to_post ###
$(cat "$custom_plan_location")
EOF
)

set -e
echo $body_to_post
curl -L -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$client_repository/issues/$client_pull_request_number/comments \
  -d "$(jq -n --arg body "$body_to_post" '{"body": $body}')"