#!/bin/bash
# Help responds with expected output.

. "$SHEST_SCRIPT" "--doNothing"

passCode=0

result="$(./bin/duse --help)"
exitCode=$?

if [[ "$result" == *"Show this help."* ]] &&  [ "$exitCode" == "$passCode" ] ; then
    pass "Great!"
else
    fail "Got exit code=$exitCode, or didn't get the expected output."
fi

