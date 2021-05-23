#!/bin/bash
# Set up directory structure.

. "$SHEST_SCRIPT" "--doNothing"

passCode=0
mkdir -p data/{context1,context2}/{source,cache} pad/{context1,context2}
exitCode1=$?

echo 1 > data/context1/source/a
echo 2 > data/context1/source/b
echo 3 > data/context2/source/c
echo 4 > data/context2/source/d

exitCode2=$?

if [ "$exitCode1" == "$passCode" ] && [ "$exitCode2" == "$passCode" ] ; then
    pass "Great!"
else
    fail "Got exitCode1=$exitCode1 and exitCode2=$exitCode2. Needed $passCode for both."
fi
