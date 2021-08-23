# Intended to be run like this:
# . misc/env.sh

set -x

export PATH="`pwd`/bin:$PATH"
export PS1="\$? $PS1"

set +x
