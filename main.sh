#!/bin/bash

MERGE_PR="$MERGE_PR"
CLOSE_PR="$CLOSE_PR"
PR_BODY="$PR_BODY"
PR_DESCRIPTION="$PR_DESCRIPTION"
BASE="$BASE_REF"
HEAD="$HEAD_REF"
SEP="&&"

# for curl API
token="$GITHUB_TOKEN"
BASE_URI="https://api.github.com"
owner="$REPO_OWNER"
repo="$REPO_NAME"
pull_number="$PR_NUMBER"

#date and time of PR
latest_commit_date=$(curl -X GET -u $owner:$token $BASE_URI/repos/$owner/$repo/pulls/$pull_number/commits | jq -r '.[-1].commit.committer.date')

live_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
convert_live_date=$(date -u -d "$live_date" +%s)
convert_latest_commit_date=$(date -u -d "$latest_commit_date" +%s)
DIFFERENCE=$((convert_live_date - convert_latest_commit_date))

echo "latest commit date: $latest_commit_date"
echo "live date: $live_date"
echo "convert live date: $convert_live_date"
echo "convert latest commit date: $convert_latest_commit_date"
echo "difference time: $DIFFERENCE"

#time
two_weeks=1209600 # 14 days

# Stale Pull Request
stale () {
case $((
(DIFFERENCE < two_weeks) * 1 +
(DIFFERENCE > two_weeks) * 2)) in
(1) echo "This PR is active." ;;
(2) echo "This PR is stale and close because it has been open from 14 days with no activity."
   curl -X POST -u $owner:$token $BASE_URI/repos/$owner/$repo/issues/$pull_number/labels \
  -d '{"labels":["Stale"]}'
   curl -X PATCH -u $owner:$token $BASE_URI/repos/$owner/$repo/pulls/$pull_number \
  -d '{ "state": "closed" }'
  curl -X POST -u $owner:$token $BASE_URI/repos/$owner/$repo/issues/$pull_number/comments \
  -d '{"body":"This PR was closed because it has been stalled for 14 days with no activity."}'
  ;;
esac  
}

# Issue comments
case "${MERGE_PR}" in
  "true") 
  echo "PR has Approved."
  curl -X PUT -u $owner:$token $BASE_URI/repos/$owner/$repo/pulls/$pull_number/merge \
  -d '{ "merged": true }'
  curl -X POST -u $owner:$token $BASE_URI/repos/$owner/$repo/issues/$pull_number/comments \
  -d '{"body":"Pull Request Merged!"}'
    ;;
esac

case "${CLOSE_PR}" in
  "true") 
  echo "PR has Closed manually by comments."
  curl -X PATCH -u $owner:$token $BASE_URI/repos/$owner/$repo/pulls/$pull_number \
  -d '{ "state": "closed" }'
  curl -X POST -u $owner:$token $BASE_URI/repos/$owner/$repo/issues/$pull_number/comments \
  -d '{"body":"Pull Request Closed!"}'
    ;;
esac

# Pull_request target master
target() {
case "${BASE}${SEP}${HEAD}" in
  "true${SEP}false") 
    curl -X PATCH -u $owner:$token $BASE_URI/repos/$owner/$repo/pulls/$pull_number \
  -d '{ "state": "closed" }'
    curl -X POST -u $owner:$token $BASE_URI/repos/$owner/$repo/issues/$pull_number/comments \
  -d '{"body":"Do not accept PR target from feature branch to master branch."}'
    ;;
esac
}

# Description
description() {
case "$PR_DESCRIPTION" in
  "true") 
    echo "PR has No valied description" 
    curl -X POST -u $owner:$token $BASE_URI/repos/$owner/$repo/issues/$pull_number/comments \
    -d '{"body":"No Description on PR body. Please add valid description."}'
    curl -X PATCH -u $owner:$token $BASE_URI/repos/$owner/$repo/pulls/$pull_number \
    -d '{ "state": "closed" }'
  ;;
esac  
}
"$@"
