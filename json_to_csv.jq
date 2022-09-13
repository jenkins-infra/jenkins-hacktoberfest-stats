($accepted_arg | split(",") | map(ltrimstr(" ") | rtrimstr(" ") | ascii_downcase) ) as $accepted_arr
| map(.items)
| add
| map(
    select(
      # Spec: - Status is either open or merged
      (.state == "open" or .pull_request.merged_at != null)
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
        ([$accepted_arr[] as $accepted | any(.labels[]; .name | ascii_downcase == $accepted)] | any), # Spec: Is flag “Hacktoberfest-approved” set?
         any(.labels[]; .name | test($spam; "i")), # Spec: Additional labels should be reported in the result (true/false): spam
         any(.labels[]; .name | test($invalid; "i")) # Spec: Additional labels should be reported in the result (true/false): invalid
      ]
  )[]
| @csv