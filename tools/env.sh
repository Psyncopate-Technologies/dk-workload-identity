# Source this to put tools/bin on PATH for the current shell:
#   source ./tools/env.sh

_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export PATH="${_TOOLS_DIR}/bin:${PATH}"
unset _TOOLS_DIR
