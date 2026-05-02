comment_marker=$1
body_to_post=$(cat << EOF
<!-- ${comment_marker} -->
### $body_message_to_post ###
$(cat "$custom_plan_location")
EOF
)

set -e
echo "$body_to_post"

# locate existing comment
existing_comment_id=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$client_repository/issues/$client_pull_request_number/comments" \
  | jq -r --arg marker "<!-- ${comment_marker} -->" \
    '[.[] | select(.body | contains($marker))] | first | .id // empty')

if [ -n "$existing_comment_id" ]; then
  # Update existing comment
  curl -L -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$client_repository/issues/comments/$existing_comment_id" \
    -d "$(jq -n --arg body "$body_to_post" '{"body": $body}')"
else
  # Create new comment
  curl -L -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$client_repository/issues/$client_pull_request_number/comments" \
    -d "$(jq -n --arg body "$body_to_post" '{"body": $body}')"
fi