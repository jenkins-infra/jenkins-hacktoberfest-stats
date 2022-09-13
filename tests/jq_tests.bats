@test "Empty json should produce 0 line" {
  run jq --arg org "test_org" --arg accepted_arg "foo" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq <<'JSON'
{ "total_count": 0, "incomplete_results": false, "items": [ ] }
JSON

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "" ]
}

@test "Is approved lowercase" {
  run jq --arg org "test_org" --arg accepted_arg "foo" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",true,false,false' ]
}

@test "Is approved uppercase" {
  run jq --arg org "test_org" --arg accepted_arg "BAR" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_BAR.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",true,false,false' ]
}

@test "Approved label must be exactly the same" {
  run jq --arg org "test_org" --arg accepted_arg "foo" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,false' ]

  run jq --arg org "test_org" --arg accepted_arg "bar" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,false' ]

  run jq --arg org "test_org" --arg accepted_arg "baz" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,false' ]
}

@test "Is not approved" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,false' ]
}

@test "Is spam lowercase" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "foo" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,true,false' ]
}

@test "Is spam uppercase" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "BAR" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_BAR.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,true,false' ]
}

@test "Spam label regex is not global" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "foo" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,true,false' ]

  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "bar" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,true,false' ]

  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "baz" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,true,false' ]
}

@test "Is not spam" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,false' ]
}

@test "Is invalid lowercase" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "foo" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,true' ]
}

@test "Is invalid uppercase" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "BAR" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_BAR.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,true' ]
}

@test "Invalid label regex is not global" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "foo" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,true' ]

  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "bar" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,true' ]

  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "baz" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo_bar_baz.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,true' ]
}

@test "Is not invalid" {
  run jq --arg org "test_org" --arg accepted_arg "accepted" --arg spam "spam" --arg invalid "invalid" --raw-output --slurp --from-file json_to_csv.jq "$BATS_TEST_DIRNAME/label_foo.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '"test_org","https://github.com/jenkinsci/workflow-api-plugin/pull/107","Fix bad assertion in TestVisitor#assertNoIllegalNullsInEvents","workflow-api-plugin","closed","2019-10-04T15:53:45Z",,"bats",false,false,false' ]
}

@test "Test regex: ^ and $ are boundary" {
  run jq --arg regex '\bfoo\b' --null-input '"foo" | test($regex; "i")'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'true' ]
}

@test "Test regex: space is boundary" {
  run jq --arg regex '\bfoo\b' --null-input '" foo " | test($regex; "i")'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'true' ]
}

@test "Test regex: _ is NOT a boundary" {
  run jq --arg regex '\bfoo\b' --null-input '"_foo_" | test($regex; "i")'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'false' ]
}

@test "Test escape inline regex" {
  run jq --null-input '"foo" | test("\\bfoo\\b"; "i")'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'true' ]
}
