#!/bin/bash
# Write a decription of the test here.

. "$SHEST_SCRIPT" "--doNothing"

passCode=0

result="$(./bin/duse --help)"
exitCode=$?

if [[ "$result" == *"Valid commands are"* ]] &&  [ "$exitCode" == "$passCode" ] ; then
    pass "Great!"
else
    fail "Got exit code=$exitCode, or didn't get the expected output."
fi

