#!/usr/bin/env bash

## config
query='org:jenkinsci org:jenkins-infra org:stapler topic:hacktoberfest fork:true'
# csv files
current_time=$(date "+%Y%m%d-%H%M%S")
filename="repo_data/hacktoberfest_repositories_$current_time.csv"
summary_filename="repo_data/hacktoberfest_repositories_summary_$current_time.csv"
# Create the data directory if it doesn't exist yet
[ -d repo_data ] || mkdir repo_data
##

getRepositories() {
  local json_filename="hacktoberfest-repositories"

  rm -f "$json_filename"*.json
  local url_encoded_query
  url_encoded_query=$(jq --arg query "$query" --raw-output --null-input '$query|@uri')
  local page=1
  while true; do
    echo "$json_filename get page $page"
    gh api -H "Accept: application/vnd.github+json" "/search/repositories?q=$url_encoded_query&sort=updated&order=desc&per_page=100&page=$page" >"$json_filename$page.json"
    # less accurate, can make 1 useless call if the number of issues is a multiple of 100
    if test "$(jq --raw-output '.items|length' "$json_filename$page.json")" -ne 100; then
      break
    fi
    ((page++))
  done

  jq --raw-output --slurp --from-file json_to_repositories.jq "$json_filename"*.json >>"$filename"
}

echo 'org,name,url' >"$filename"

getRepositories

cat $filename | datamash -t, --sort --headers groupby 1 count 1 > "$summary_filename"
cat $summary_filename
