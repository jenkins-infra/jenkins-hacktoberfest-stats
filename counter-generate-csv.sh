#!/usr/bin/env bash

## Specifications:
# Produce a CSV list of PRs with following details
#  - PR URL
#  - PR Title
#  - Repository
#  - Status (Open, Merged)
#  - Creation date
#  - Merge date (if applicable)
#  - PR Author
#  - Is flag “Hacktoberfest-approved” set?
# Matching the following conditions:
#  - PRs in all repositories of jenkinsci and jenkins-infra
#  - Created after 01-OCT-2022
#  - Title contains “hacktoberfest” (case insensitive)
#  - Status is either open or merged

## config
# Spec: Created after 01-OCT-2022
query='label:hacktoberfest is:pr created:>2012-12-31'
# Spec: Is flag “Hacktoberfest-approved” set? (case insensitive)
tag='Hacktoberfest-accepted, Hacktoberfest-approved'
# Spec: Title contains “hacktoberfest” (case insensitive)
title='Hacktoberfest'
# csv files
current_time=$(date "+%Y%m%d-%H%M%S")
filename="hacktoberfest_$current_time"
# do not request GH api, use only the existing files
no_api=false
##

read -r -d '' jq_script <<'JQ_SCRIPT'
($tagstr | split(",") | map(ltrimstr(" ") | rtrimstr(" ") | ascii_downcase) ) as $tags
| map(.items)
| add
| map(
    select(
      # Spec: - Status is either open or merged
      (.state == "open" or .pull_request.merged_at != null)
      # Spec: Title contains “hacktoberfest” (case insensitive)
      and ( .title | ascii_downcase | contains($title | ascii_downcase) )
      )
    # Spec: Produce a CSV list of PRs with following details: PR URL, PR Title, Repository, Status (Open, Merged), Creation date, Merge date (if applicable), PR Author, Is flag “Hacktoberfest-approved” set?
    | [
        $org,
        .html_url,
        .title,
        # Hacky, but requires far less API calls
        (.repository_url | split("/") | last),
        .state,
        .created_at,
        .merged_at,
        .user.login,
        ([$tags[] as $tag | any(.labels[]; .name | ascii_downcase == $tag)] | any)
      ]
  )[]
| @csv
JQ_SCRIPT

getOrganizationData() {
  local org="$1"
  local json_filename="$org"

  if ! $no_api; then
    rm "$json_filename"*.json
    local url_encoded_query
    url_encoded_query=$(jq --arg query "org:$org $query" --raw-output --null-input '$query|@uri')
    page=1
    while true; do
      echo "org: $org get page $page"
      gh api -H "Accept: application/vnd.github+json" "/search/issues?q=$url_encoded_query&sort=updated&order=desc&per_page=100&page=$page" >"$json_filename$page.json"
      # less accurate, can make 1 useless call if the number of issues is a multiple of 100
      if test "$(jq --raw-output '.items|length' "$json_filename$page.json")" -ne 100; then
        break
      fi
      ((page++))
    done
  fi

  jq --arg org "$org" --arg tagstr "$tag" --arg title "$title" --raw-output --slurp "${jq_script[*]}" "$json_filename"*.json >>"$filename.csv"
}

# Spec: Produce a CSV list of PRs with following details: PR URL, PR Title, Repository, Status (Open, Merged), Creation date, Merge date (if applicable), PR Author, Is flag “Hacktoberfest-approved” set?
echo 'org,url,title,repository,state,created_at,merged_at,user.login,Hacktoberfest-approved' >"$filename.csv"

# seems not possible to query both org at the same time
# Spec: PRs in all repositories of jenkinsci and jenkins-infra
getOrganizationData jenkinsci
getOrganizationData jenkins-infra
