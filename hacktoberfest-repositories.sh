#!/usr/bin/env bash

# check wether required tools are available
if ! command -v "gh" >/dev/null 2>&1
then
  echo "ERROR: command line 'gh' required but not found. Exiting."
  exit 1
fi

if ! command -v "jq" >/dev/null 2>&1
then
  echo "ERROR: command line 'jq' required but not found. Exiting."
  exit 1
fi

if ! command -v "datamash" >/dev/null 2>&1
then
  echo "ERROR: command line 'datamash' required but not found. Exiting."
  exit 1
fi

## config
query='org:jenkinsci org:jenkins-infra topic:hacktoberfest fork:true'

# csv files
current_time=$(date "+%Y%m%d-%H%M%S")
data_filename_root="repo_data/hacktoberfest_repos"
filename_latest="${data_filename_root}_latest.csv"
summary_filename_latest="${data_filename_root}_summary_latest.csv"
filename="${data_filename_root}_${current_time}.csv"
summary_filename="${data_filename_root}_summary_$current_time.csv"

# Create the data directory if it doesn't exist yet
[ -d repo_data ] || mkdir repo_data
[ -d json_data ] || mkdir json_data
##

getRepositories() {
  local json_filename="json_data/hacktoberfest-repositories"

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

echo "---------------------------------------"
cat $filename | datamash -t, --sort --headers groupby 1 count 1 > "$summary_filename"
cat $summary_filename
echo "---------------------------------------"
nbr_repos=$(wc -l < <(tail -n +2 ${filename}))
echo "Total number of repositories: ${nbr_repos}"
echo "---------------------------------------"


# update the latest
cp $filename $filename_latest
cp $summary_filename $summary_filename_latest
