#!/usr/bin/env bash

######
# this script retrieves informations from GitHub to track Hacktoberfest participation in the Jenkins project
# The resulting data is enriched and made available as a CSV
###### 

set -e

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

### Setting up constants

# We exclude the PRs created by dependabot and renovate and those created outside the period
hacktoberfest_year="2022"
query="is:pr -author:app/dependabot -author:app/renovate created:${hacktoberfest_year}-10-01..${hacktoberfest_year}-10-31"

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
raw_csv_filename="${data_filename_root}_raw_${current_time}.csv"
csv_filename="${data_filename_root}_${current_time}.csv"
csv_filename_latest="${data_filename_root}_latest.csv"
summaryFileContribs="${data_filename_root}_contributors_$current_time.csv"
summaryFileContribs_latest="${data_filename_root}_contributors_latest.csv"

# CSV file with the hacktoberfest repositories
repos_csv_file="repo_data/hacktoberfest_repos_latest.csv"

# create the data directory if it doesn't exist
[ -d data ] || mkdir data
[ -d json_data ] || mkdir json_data
##


# Function to facilitate checking whether a PR is complete and acceptable for Hacktoberfest
isAccepted() {
  local merge_date="$2"
  local hacktoberfest_approved="$1"

  #is the merge_date empty?
  if [ -z "$merge_date" ]
  then
    # it has not been merged
    if test "$hacktoberfest_approved" == "true"
    then
      echo "1"
    else
      echo "0"
    fi
  else
    # the PR has been merged
    echo "1"
  fi
}

# Loops through the raw CSV to see if the PR is a hacktoberfest candidate
lookupHacktoberfestTopic() {
  local raw_csv_file="$1"
  local output_csv_file="$2"

  echo "output:  ${output_csv_file}"

  ## Create header in output
  echo 'org,repository,is_hacktoberfest_repo,url,state,created_at,merged_at,user.login,is_hacktoberfest_labeled,approved,spam,invalid,hacktoberfest_complete,title' >"$output_csv_file"

  while IFS="," read -r org repository url state created_at merged_at user_login is_hacktoberfest_labeled approved spam invalid title
  do
    trimmed_repository="$(echo "${repository}" | xargs)"
    if test "$(grep -c "/${trimmed_repository}\"" "${repos_csv_file}")" -eq 1
    then
      is_hacktoberfest_repo="true"
      #echo "${trimmed_repository} - ${url}"
      hacktoberfest_complete=$(isAccepted $approved $merged_at )
      echo "$org,$repository,$is_hacktoberfest_repo,$url,$state,$created_at,$merged_at,$user_login,$is_hacktoberfest_labeled,$approved,$spam,$invalid,$hacktoberfest_complete,$title" >> "${output_csv_file}"
    else
      is_hacktoberfest_repo="false"
      # It might be a PR tagged "hacktoberfest" or "hacktoberfest-accepted"
      if test "$is_hacktoberfest_labeled" == "true" || test "$approved" == "true"
      then
        hacktoberfest_complete=$(isAccepted $approved $merged_at)
        echo "$org,$repository,$is_hacktoberfest_repo,$url,$state,$created_at,$merged_at,$user_login,$is_hacktoberfest_labeled,$approved,$spam,$invalid,$hacktoberfest_complete,$title" >> "${output_csv_file}"
      fi 
    fi
  done < <(tail -n +2 ${raw_csv_file})
}

# Function that retrieves and processes the GitHub information for a given organization
getOrganizationData() {
  local org="$1"
  local json_filename="json_data/${org}"

  rm -f "$json_filename"*.json
  local url_encoded_query
  url_encoded_query=$(jq --arg query "org:$org $query" --raw-output --null-input '$query|@uri')
  local page=1
  while true; do
    echo "org: $org get page $page"
    gh api -H "Accept: application/vnd.github+json Retry-After: 30" "/search/issues?q=$url_encoded_query&sort=updated&order=desc&per_page=100&page=$page" >"$json_filename$page.json"
    # less accurate, can make 1 useless call if the number of issues is a multiple of 100
    if test "$(jq --raw-output '.items|length' "$json_filename$page.json")" -ne 100; then
      break
    fi
    ((page++))
    # Dirty trick to a avoid hitting secondary rate limit.
    sleep 15
  done

  jq --arg org "$org" --arg hacktoberfest_labeled "$label_hacktoberfest" --arg accepted_arg "$label_accepted" --arg spam "$label_spam_regex" --arg invalid "$label_invalid_regex" --raw-output --slurp --from-file json_to_csv.jq "$json_filename"*.json >>"$raw_csv_filename"
}

# Spec: Produce a CSV list of PRs with following details: PR URL, PR Title, Repository, Status (Open, Merged), Creation date, Merge date (if applicable), PR Author, Is flag “Hacktoberfest-approved” set?
echo 'org,repository,url,state,created_at,merged_at,user.login,is_hacktoberfest_labeled,approved,spam,invalid,title' >"$raw_csv_filename"

# seems not possible to query both org at the same time
# Spec: PRs in all repositories of jenkinsci and jenkins-infra
getOrganizationData jenkinsci
getOrganizationData jenkins-infra

# # Update the list of participating repositories (only if it doesn't exist)
if [ ! -f ${repos_csv_file} ]
then
  ./hacktoberfest-repositories.sh
fi


# Look through the generated file and lookup the repositories that have the hacktoberfest topic
lookupHacktoberfestTopic ${raw_csv_filename} ${csv_filename} 

#https://medium.com/clarityai-engineering/back-to-basics-how-to-analyze-files-with-gnu-commands-fe9f41665eb3
# awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' hacktoberfest_20220928-162143.csv
awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' $csv_filename | datamash -t, --sort --headers groupby 8 sum 13 > "$summaryFileContribs"
echo "----------------------------------------"
cat $summaryFileContribs

# update the latest
cp ${csv_filename} ${csv_filename_latest}
cp $summaryFileContribs $summaryFileContribs_latest


echo "----------------------------------------"
echo " SUMMARY"
echo "----------------------------------------"
# total not automated PRs in Jenkinsci and Jenkin-infra organisation
wrk_raw_pr=$(cat ${raw_csv_filename} | wc -l)
raw_pr=$(echo "${wrk_raw_pr}" | xargs)
echo "Total number of PRs created in jenkinsci and jenkins-infra orgs: ${raw_pr}"
set +x

# Total Hacktoberfest PRs
wrk_tot_pr=$(wc -l < <(tail -n +2 ${csv_filename}))
tot_pr=$(echo "${wrk_tot_pr}" | xargs)
# Total number of Hacktoberfest contributors
wrk_tot_contributors=$(wc -l < <(tail -n +2 ${summaryFileContribs}))
tot_contributors=$(echo "${wrk_tot_contributors}" | xargs)
# Display these results
echo "Total Hacktoberfest PRs: ${tot_pr} (by ${tot_contributors} contributors)"

# Total number of validated hacktoberfest PRs
wrk_tot_valid_pr=$(cat ${csv_filename}| grep ",1,\"" | wc -l)
tot_valid_pr=$(echo "${wrk_tot_valid_pr}" | xargs)
# Total number of Hacktoberfest contributors with valid PRs
wrk_tot_valid_contributors=$(tail -n +2  $summaryFileContribs | grep -v "\",0" | wc -l)
tot_valid_contributors=$(echo "${wrk_tot_valid_contributors}" | xargs)
# Display these results
echo "Total validated Hacktoberfest PRs: ${tot_valid_pr} (by ${tot_valid_contributors} contributors)"
