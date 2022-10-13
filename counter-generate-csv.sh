#!/usr/bin/env bash


# We exclude the PRs created by dependabot and renovate
query='is:pr -author:app/dependabot -author:app/renovate created:>2022-10-01'

#Spec: is "hacktoberfest" flag set? 
label_hacktoberfest='\bhacktoberfest\b'

# Spec: Is flag “Hacktoberfest-approved” set? (case insensitive)
label_accepted='Hacktoberfest-accepted, Hacktoberfest-approved'
#  - Additional labels should be reported in the result (true/false): spam, invalid
label_spam_regex='\bspam\b'
#  - Additional labels should be reported in the result (true/false): spam, invalid
label_invalid_regex='\binvalid\b'

# csv files
current_time=$(date "+%Y%m%d-%H%M%S")
data_filename_root="data/hacktoberfest"
filename_latest="${data_filename_root}_latest.csv"
summaryFileContribs_latest="${data_filename_root}_summary_latest.csv"
filename="${data_filename_root}_${current_time}.csv"
summaryFileContribs="${data_filename_root}_contribs_$current_time.csv"

# create the data directory if it doesn't exist
[ -d data ] || mkdir data
##

getOrganizationData() {
  local org="$1"
  local json_filename="$org"

  rm -f "$json_filename"*.json
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

  jq --arg org "$org" --arg hacktoberfest_labeled "$label_hacktoberfest" --arg accepted_arg "$label_accepted" --arg spam "$label_spam_regex" --arg invalid "$label_invalid_regex" --raw-output --slurp --from-file json_to_csv.jq "$json_filename"*.json >>"$filename"
}

# Spec: Produce a CSV list of PRs with following details: PR URL, PR Title, Repository, Status (Open, Merged), Creation date, Merge date (if applicable), PR Author, Is flag “Hacktoberfest-approved” set?
echo 'org,url,title,repository,state,created_at,merged_at,user.login,is_hacktoberfest_labeled,approved,spam,invalid' >"$filename"

# seems not possible to query both org at the same time
# Spec: PRs in all repositories of jenkinsci and jenkins-infra
getOrganizationData jenkinsci
getOrganizationData jenkins-infra

# #https://medium.com/clarityai-engineering/back-to-basics-how-to-analyze-files-with-gnu-commands-fe9f41665eb3
# # awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' hacktoberfest_20220928-162143.csv
# awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' $filename | datamash -t, --sort --headers groupby 8 count 8 > "$summaryFileContribs"
# echo "----------------------------------------"
# cat $summaryFileContribs

# update the latest
cp $filename $filename_latest
#cp $summaryFileContribs $summaryFileContribs_latest
