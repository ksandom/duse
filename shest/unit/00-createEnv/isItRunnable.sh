#!/bin/bash
# Write a decription of the test here.

. "$SHEST_SCRIPT" "--doNothing"

result="$(./bin/duse --help)"
exitCode=$?

expect_exitCode 0
expect_resultContains "Valid commands are"
