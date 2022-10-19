# jenkins-hacktoberfest-stats

A set of scripts to monitor the Hacktoberfest participation in the Jenkins projects.

The main script is `counter-generate-csv.sh` (it will automatically call the repository query). 
The results are stored in the `data` sub-directory and are time-stamped. The latest version is also stored as `hacktoberfest_latest.csv`.

The scripts require the following tools to be installed:

- `gh`: GitHub command line tool
- `jq`: Json query tool
- `datamash`: CSV data manipulation tool 

Special thanks to Jean-Marc Desprez (@jmdesprez)for having provided the original scripts.
