map(.items)
| add
| map(
[.owner.login, .html_url]
  )[]
| @csv
