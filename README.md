# jenkins-hacktoberfest-stats

A set of scripts to monitor the Hacktoberfest participation in the Jenkins projects.

The main script is `counter-generate-csv.sh` (it will automatically call the repository query). 
The results are stored in the `data` sub-directory and are time-stamped. 
- the list of all PRs created in the `jenkinsci` and `jenkin-infra` orgs is available in `data/hacktoberfest_raw_<timestamp>.csv`.
- the list of potential hacktoberfest PR with their status is available in `data/hacktoberfest_<timestamp>.csv`. The latest version is stored as `data/hacktoberfest_latest.csv`.
- the list of the number of validated PR per contributor is available in `data/hacktoberfest_contributors_<timestamp>.csv`. The latest version is stored as `data/hacktoberfest_contributors_latest.csv`

The main script relies on the list of repos in both organisations that are welcoming hacktoberfest PRs. This list is computed by the `hacktoberfest_repositories.sh` script.
The results are stored in the `repo_data` sub-directory and are also timestamped.
- the list of participating repositories stored in `repo_data/hacktoberfest_repos_<timestamp>.csv`. The latest version is stored as `repo_data/hacktoberfest_repos_latest.csv`.
- a summary, listing the number of participating repositories per organisation, is available as `repo_data/hacktoberfest_repos_summary_<timestamp>.csv`. The latest verstion is stored as `repo_data/hacktoberfest_repos_summary_latest.csv`.

The scripts require the following tools to be installed:

- `gh`: GitHub command line tool
- `jq`: Json query tool
- `datamash`: CSV data manipulation tool 

Special thanks to Jean-Marc Desprez (@jmdesprez)for having provided the original scripts.
