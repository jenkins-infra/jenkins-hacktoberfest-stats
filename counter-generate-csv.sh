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
#  - Additional labels should be reported in the result (true/false): /\bspam\b/i, /\binvalid\b/i
# Matching the following conditions:
#  - PRs in all repositories of jenkinsci and jenkins-infra
#  - Created after 01-OCT-2022
#  - Labeled as hacktoberfest
#  - Status is either open or merged

## config
# Spec: Labeled as hacktoberfest
# Spec: It is a PR
# Spec: Created after 01-OCT-2022
query='label:hacktoberfest is:pr created:>2022-10-01'
#query='label:hacktoberfest is:pr created:>2012-12-31'

# Spec: Is flag “Hacktoberfest-approved” set? (case insensitive)
label_accepted='Hacktoberfest-accepted, Hacktoberfest-approved'
#  - Additional labels should be reported in the result (true/false): spam, invalid
label_spam_regex='\bspam\b'
#  - Additional labels should be reported in the result (true/false): spam, invalid
label_invalid_regex='\binvalid\b'
# csv files
current_time=$(date "+%Y%m%d-%H%M%S")
filename="hacktoberfest_$current_time.csv"
summaryFileContribs="hacktoberfest_contribs_$current_time.csv"
##

getOrganizationData() {
  local org="$1"
  local json_filename="$org"

  rm "$json_filename"*.json
  local url_encoded_query
  url_encoded_query=$(jq --arg query "org:$org $query" --raw-output --null-input '$query|@uri')
  local page=1
  while true; do
    echo "org: $org get page $page"
    gh api -H "Accept: application/vnd.github+json" "/search/issues?q=$url_encoded_query&sort=updated&order=desc&per_page=100&page=$page" >"$json_filename$page.json"
    # less accurate, can make 1 useless call if the number of issues is a multiple of 100
    if test "$(jq --raw-output '.items|length' "$json_filename$page.json")" -ne 100; then
      break
    fi
    ((page++))
  done

  jq --arg org "$org" --arg accepted_arg "$label_accepted" --arg spam "$label_spam_regex" --arg invalid "$label_invalid_regex" --raw-output --slurp --from-file json_to_csv.jq "$json_filename"*.json >>"$filename"
}

# Spec: Produce a CSV list of PRs with following details: PR URL, PR Title, Repository, Status (Open, Merged), Creation date, Merge date (if applicable), PR Author, Is flag “Hacktoberfest-approved” set?
echo 'org,url,title,repository,state,created_at,merged_at,user.login,approved,spam,invalid' >"$filename"

# seems not possible to query both org at the same time
# Spec: PRs in all repositories of jenkinsci and jenkins-infra
getOrganizationData jenkinsci
getOrganizationData jenkins-infra

#https://medium.com/clarityai-engineering/back-to-basics-how-to-analyze-files-with-gnu-commands-fe9f41665eb3
# awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' hacktoberfest_20220928-162143.csv
awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' $filename | datamash -t, --sort --headers groupby 8 count 8 > "$summaryFileContribs"
echo "----------------------------------------"
cat $summaryFileContribs