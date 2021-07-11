#!/bin/bash
# Set up directory structure.

. "$SHEST_SCRIPT" "--doNothing"

result="$(./misc/createDuseTestData)"
exitCode="$?"

expect_exitCode 0 
