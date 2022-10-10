map(.items)
| add
| map(
    [
      .owner.login,
      (.html_url | split("/") | last),
      .html_url
    ]
  )[]
| @csv
