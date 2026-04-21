#!/usr/bin/env bash
# Download pinned CLI versions into tools/bin/. Idempotent — re-running skips
# anything already at the right version. Used by local dev and by the GitHub
# Actions workflow.
#
#   ./tools/install.sh
#   source ./tools/env.sh   # adds tools/bin to PATH

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"
CACHE_DIR="${SCRIPT_DIR}/.cache"
PYTHON_DIR="${SCRIPT_DIR}/.python"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/versions.env"

mkdir -p "${BIN_DIR}" "${CACHE_DIR}" "${PYTHON_DIR}"

# --- OS / arch detection (matches asset naming used by HashiCorp / Gruntwork / Confluent / Astral) ---
case "$(uname -s)" in
  Linux)  OS="linux" ;;
  Darwin) OS="darwin" ;;
  *)      echo "unsupported OS: $(uname -s)"; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) ARCH="amd64"; UV_ARCH="x86_64" ;;
  arm64|aarch64) ARCH="arm64"; UV_ARCH="aarch64" ;;
  *) echo "unsupported arch: $(uname -m)"; exit 1 ;;
esac

version_of() { "${BIN_DIR}/$1" --version 2>/dev/null | head -n1 || echo ""; }

install_terraform() {
  local want="${TERRAFORM_VERSION}"
  if version_of terraform | grep -q "v${want}"; then
    echo "terraform ${want} already installed"; return
  fi
  local zip="${CACHE_DIR}/terraform_${want}_${OS}_${ARCH}.zip"
  curl -fsSL -o "${zip}" "https://releases.hashicorp.com/terraform/${want}/terraform_${want}_${OS}_${ARCH}.zip"
  unzip -oq "${zip}" -d "${BIN_DIR}"
  chmod +x "${BIN_DIR}/terraform"
  echo "installed terraform ${want}"
}

install_terragrunt() {
  local want="${TERRAGRUNT_VERSION}"
  if version_of terragrunt | grep -q "v${want}"; then
    echo "terragrunt ${want} already installed"; return
  fi
  curl -fsSL -o "${BIN_DIR}/terragrunt" \
    "https://github.com/gruntwork-io/terragrunt/releases/download/v${want}/terragrunt_${OS}_${ARCH}"
  chmod +x "${BIN_DIR}/terragrunt"
  echo "installed terragrunt ${want}"
}

install_confluent_cli() {
  local want="${CONFLUENT_CLI_VERSION}"
  if version_of confluent | grep -q "v${want}"; then
    echo "confluent ${want} already installed"; return
  fi
  local tgz="${CACHE_DIR}/confluent_${want}_${OS}_${ARCH}.tar.gz"
  curl -fsSL -o "${tgz}" \
    "https://github.com/confluentinc/cli/releases/download/v${want}/confluent_${want}_${OS}_${ARCH}.tar.gz"
  rm -rf "${CACHE_DIR}/confluent"
  tar -xzf "${tgz}" -C "${CACHE_DIR}"
  cp "${CACHE_DIR}/confluent/confluent" "${BIN_DIR}/confluent"
  chmod +x "${BIN_DIR}/confluent"
  echo "installed confluent ${want}"
}

install_uv_and_python() {
  local want="${UV_VERSION}"
  if ! version_of uv | grep -q "uv ${want}"; then
    local tgz="${CACHE_DIR}/uv_${want}_${OS}_${UV_ARCH}.tar.gz"
    local asset
    if [[ "${OS}" == "linux" ]]; then
      asset="uv-${UV_ARCH}-unknown-linux-gnu.tar.gz"
    else
      asset="uv-${UV_ARCH}-apple-darwin.tar.gz"
    fi
    curl -fsSL -o "${tgz}" "https://github.com/astral-sh/uv/releases/download/${want}/${asset}"
    tar -xzf "${tgz}" -C "${CACHE_DIR}"
    cp "${CACHE_DIR}/${asset%.tar.gz}/uv" "${BIN_DIR}/uv"
    chmod +x "${BIN_DIR}/uv"
    echo "installed uv ${want}"
  else
    echo "uv ${want} already installed"
  fi

  # Install the pinned Python under tools/.python/ — UV_PYTHON_INSTALL_DIR keeps it local.
  UV_PYTHON_INSTALL_DIR="${PYTHON_DIR}" "${BIN_DIR}/uv" python install "${PYTHON_VERSION}"
  local py_bin
  py_bin="$(UV_PYTHON_INSTALL_DIR="${PYTHON_DIR}" "${BIN_DIR}/uv" python find "${PYTHON_VERSION}")"
  ln -sf "${py_bin}" "${BIN_DIR}/python3.12"
  ln -sf "${py_bin}" "${BIN_DIR}/python3"
  echo "installed python ${PYTHON_VERSION}"
}

install_terraform
install_terragrunt
install_confluent_cli
install_uv_and_python

echo
echo "all tools installed under ${BIN_DIR}"
echo "run: source ${SCRIPT_DIR}/env.sh"
