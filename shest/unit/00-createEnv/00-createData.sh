#!/bin/bash
# Set up directory structure.

. "$SHEST_SCRIPT" "--doNothing"

passCode=0
mkdir -p data/{context1,context2} workspace/{context1,context2} cache
exitCode1=$?

echo 1 > data/context1/a
echo 2 > data/context1/b
echo 3 > data/context2/c
echo 4 > data/context2/d

exitCode2=$?

if [ "$exitCode1" == "$passCode" ] && [ "$exitCode2" == "$passCode" ] ; then
    pass "Great!"
else
    fail "Got exitCode1=$exitCode1 and exitCode2=$exitCode2. Needed $passCode for both."
fi
