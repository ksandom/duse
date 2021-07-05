# Intended to be run like this:
# . misc/env.sh

set -x

export PATH="$PATH:`pwd`/bin"
export PS1="\$? $PS1"

set +x
