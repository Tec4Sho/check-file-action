#!/bin/bash

set +e

LLVM_PATH=""

current_llvm_stable() {
  curl -fsSL https://apt.llvm.org/llvm.sh |
    sed -En 's/^CURRENT_LLVM_STABLE=([0-9]+)$/\1/p'
}

install_llvm() {
  llvm_version="$1";
  version="${llvm_version}";
  tmpdir="$(mktemp -d)";
  cd "${tmpdir}";
  curl -fsSL https://apt.llvm.org/llvm.sh -o llvm.sh
  chmod +x llvm.sh
  sudo env DPKG_FORCE=overwrite ./llvm.sh "${llvm_version}" all
  rm -rf -- "${tmpdir}";
  tmpfile="$(mktemp)";
  echo "/usr/lib/llvm-$llvm_version/bin" >>"$tmpfile";
  cat "${GITHUB_PATH}" >>"${tmpfile}";
  cat "${tmpfile}" > "${GITHUB_PATH}";
  rm -f -- "${tmpfile}";
  PATH="/usr/lib/llvm-${llvm_version}/bin:${PATH}";
  LLVM_PATH="/usr/lib/llvm-${llvm_version}";
  export PATH LLVM_PATH version
}

sanity_check() {
  llvm_version="$(llvm-config --version)";
  if [[ $(echo "${llvm_version}" | cut -d'.' -f1) != "$version" ]]; then
    echo "Expected LLVM major version ${version}, got ${llvm_version}" >&2
    exit 0
  fi;
}

LLVM_VERSION="${LLVM_VERSION:-$(current_llvm_stable)}";
install_llvm "${LLVM_VERSION}" >/dev/null 2>&1;
sanity_check "${LLVM_VERSION}" >/dev/null;

echo -e "\nLLVM ${LLVM_VERSION} has been installed to ${LLVM_PATH}" 2>&1;
echo "PATH=${PATH}" >>"${GITHUB_PATH}";
echo "LLVM_PATH=${LLVM_PATH}" >>"${GITHUB_ENV}";
