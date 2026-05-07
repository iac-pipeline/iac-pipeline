marker_tag="<!-- ${comment_marker} -->"

if [ -z "$custom_plan_location" ]; then
  body_to_post=$(cat << EOF
${marker_tag}
### $body_message_to_post ###
EOF
)
else
  body_to_post=$(cat << EOF
${marker_tag}
### $body_message_to_post ###
$(cat "$custom_plan_location")
EOF
)
fi

set -e
echo "$body_to_post"
 
# locate existing comment
comments_response=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $github_token" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$client_repository/issues/$client_pull_request_number/comments")

echo "Comments response: $comments_response"

existing_comment_id=$(echo "$comments_response" \
  | jq -r --arg marker "$marker_tag" \
    '[.[] | select(.body | contains($marker))] | first | .id // empty')

if [ -n "$existing_comment_id" ]; then
  # Update existing comment
  curl -L -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $github_token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$client_repository/issues/comments/$existing_comment_id" \
    -d "$(jq -n --arg body "$body_to_post" '{"body": $body}')"
else
  # Create new comment
  curl -L -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $github_token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$client_repository/issues/$client_pull_request_number/comments" \
    -d "$(jq -n --arg body "$body_to_post" '{"body": $body}')"
fi