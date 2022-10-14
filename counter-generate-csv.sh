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
csv_filename_latest="${data_filename_root}_latest.csv"
summaryFileContribs_latest="${data_filename_root}_summary_latest.csv"
csv_filename="${data_filename_root}_${current_time}.csv"
raw_csv_filename="${data_filename_root}_raw_${current_time}.csv"
summaryFileContribs="${data_filename_root}_contribs_$current_time.csv"

# create the data directory if it doesn't exist
[ -d data ] || mkdir data
[ -d json_data ] || mkdir json_data
##

lookupHacktoberfestTopic() {
  local repos_csv_file="repo_data/hacktoberfest_repos_latest.csv"
  local raw_csv_file="$1"
  local output_csv_file="$2"

  echo "output:  ${output_csv_file}"

  ## Create header in output
  echo 'org,repository,is_hacktoberfest_repo,url,state,created_at,merged_at,user.login,is_hacktoberfest_labeled,approved,spam,invalid,title' >"$output_csv_file"

  while IFS="," read -r org repository url state created_at merged_at user_login is_hacktoberfest_labeled approved spam invalid title
  do
    trimmed_repository="$(echo "${repository}" | xargs)"
    if test "$(grep -c "/${trimmed_repository}\"" "${repos_csv_file}")" -eq 1
    then
      is_hacktoberfest_repo="true"
      #echo "${trimmed_repository} - ${url}"
      echo "$org,$repository,$is_hacktoberfest_repo,$url,$state,$created_at,$merged_at,$user_login,$is_hacktoberfest_labeled,$approved,$spam,$invalid,$title" >> "${output_csv_file}"
    else
      is_hacktoberfest_repo="false"
      # It might be a PR tagged "hacktoberfest" or "hacktoberfest-accepted"
      if test "$is_hacktoberfest_labeled" == "true" || test "$approved" == "true"
      then
        echo "$org,$repository,$is_hacktoberfest_repo,$url,$state,$created_at,$merged_at,$user_login,$is_hacktoberfest_labeled,$approved,$spam,$invalid,$title" >> "${output_csv_file}"
      fi 
    fi

  done < <(tail -n +2 ${raw_csv_file})

}

getOrganizationData() {
  local org="$1"
  local json_filename="json_data/${org}"

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

  jq --arg org "$org" --arg hacktoberfest_labeled "$label_hacktoberfest" --arg accepted_arg "$label_accepted" --arg spam "$label_spam_regex" --arg invalid "$label_invalid_regex" --raw-output --slurp --from-file json_to_csv.jq "$json_filename"*.json >>"$raw_csv_filename"
}

# Spec: Produce a CSV list of PRs with following details: PR URL, PR Title, Repository, Status (Open, Merged), Creation date, Merge date (if applicable), PR Author, Is flag “Hacktoberfest-approved” set?
echo 'org,repository,url,state,created_at,merged_at,user.login,is_hacktoberfest_labeled,approved,spam,invalid,title' >"$raw_csv_filename"

# seems not possible to query both org at the same time
# Spec: PRs in all repositories of jenkinsci and jenkins-infra
getOrganizationData jenkinsci
getOrganizationData jenkins-infra

# Update the list of participating repositories
./hacktoberfest-repositories.sh

# Look through the generated file and lookup the repositories that have the hacktoberfest topic
lookupHacktoberfestTopic ${raw_csv_filename} ${csv_filename} 

# update the latest
cp ${csv_filename} ${csv_filename_latest}
# #cp $summaryFileContribs $summaryFileContribs_latest



# #https://medium.com/clarityai-engineering/back-to-basics-how-to-analyze-files-with-gnu-commands-fe9f41665eb3
# # awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' hacktoberfest_20220928-162143.csv
# awk -F'"' -v OFS='"' '{for (i=2; i<=NF; i+=2) {gsub(",", "", $i)}}; $0' $filename | datamash -t, --sort --headers groupby 8 count 8 > "$summaryFileContribs"
# echo "----------------------------------------"
# cat $summaryFileContribs