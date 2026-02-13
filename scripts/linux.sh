#!/bin/bash

set +e
set -a

LLVM_PATH=""

current_llvm_stable() {
  curl -fsSL https://apt.llvm.org/llvm.sh |
    sed -En 's/^CURRENT_LLVM_STABLE=([0-9]+)$/\1/p'
}

install_llvm() {
  llvm_version="$1";
  version="${llvm_version}";
  tmp_dir="$(mktemp -d)";
  cd "${tmp_dir}";
  curl -fsSL https://apt.llvm.org/llvm.sh -o llvm.sh
  chmod +x llvm.sh
  sudo env DPKG_FORCE=overwrite ./llvm.sh "${llvm_version}" all
  rm -rf -- "${tmp_dir}";
  tmp_file="$(mktemp)";
  echo "/usr/lib/llvm-${llvm_version}/bin" >>"${tmp_file}";
  cat "${GITHUB_PATH}" >>"${tmp_file}";
  cat "${tmp_file}" > "${GITHUB_PATH}";
  rm -f -- "${tmp_file}";
  LLVM_PATH="/usr/lib/llvm-${llvm_version}";
  PATH="${LLVM_PATH}/bin:${PATH}";  
  export LLVM_PATH PATH version
}

llvm_version() {
  llvm_version="$(llvm-config --version)";
  if [[ $(printf '%s\n%s' "${llvm_version}" "${version}" | sort -V | head -n1) == "${llvm_version}" ]] && [[ "${llvm_version}" != "${version}" ]]; then
    echo -e "\nExpected LLVM major version: ${version}, but got default version: ${llvm_version}" >&2
    exit 0
  elif [[ "${llvm_version}" == "${version}" ]]; then
    echo -e "\nUpdated LLVM major version: ${llvm_version}" 2>&1;
  elif [[ "${llvm_version%%.*}" != "${version}" ]]; then
    echo -e "\nExpected LLVM major version: ${version}, but got version: ${llvm_version}" >&2
    exit 0
  else
    echo -e "\nUpdated LLVM major version: ${llvm_version}" 2>&1;
  fi;
}

LLVM_VERSION="${LLVM_VERSION:-$(current_llvm_stable)}";
install_llvm "${LLVM_VERSION}" >/dev/null 2>&1;
llvm_version "${LLVM_VERSION}";

echo -e "\n\033[32mLLVM\033[0m ${LLVM_VERSION} \033[32mhas been installed to\033[0m \033[1m${LLVM_PATH}\033[0m\n" 2>&1;
echo "export LLVM_VERSION=${LLVM_VERSION}" | sudo tee -a ~/.bashrc >/dev/null;
echo "export LLVM_PATH=${LLVM_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
echo "export PATH=${PATH}" | sudo tee -a ~/.bashrc >/dev/null;
echo "PATH=${PATH}" >> "${GITHUB_PATH}";
echo "LLVM_PATH=${LLVM_PATH}" >> "${GITHUB_ENV}";
