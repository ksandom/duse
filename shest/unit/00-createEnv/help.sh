#!/bin/bash
# Help responds with expected output.

. "$SHEST_SCRIPT" "--doNothing"

result="$(./bin/duse --help)"
exitCode=$?

expect_exitCode 0
expect_resultContains "Show this help."
