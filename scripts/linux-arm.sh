#!/bin/bash

set +e
source ~/.bashrc

# Logic for distributionUrl
llvm_arm_install() {
    local version=$1
    local platform=$2 # Expected: linux, darwin, or win32
    local os_name="";
    local ext="";
    local download=$3
    local user=$4
    local arch=$5
    # Determine OS Name mapping
    if [[ "$version" == "13.0.0" || "$version" == "14.0.0" ]]; then
        case "$platform" in
            linux) os_name="linux" ;;
            win32) os_name="windows" ;;
            *) echo "Unsupported platform $platform for $version" >&2; return 1 ;;
        esac
    else
        case "$platform" in
            darwin)
                # Simple version comparison for Darwin naming
                if [[ "$version" < "18.0.0" ]]; then os_name="Darwin"; else os_name="Darwin-universal"; fi;
                ;;
            linux) os_name="Linux-x86_64" ;;
            win32) os_name="Windows-x86_64" ;;
            *) echo "Unsupported platform $platform" >&2; return 1 ;;
        esac
    fi;
    # Determine Extension
    if [[ "$platform" == "win32" ]]; then
        ext="zip";
    elif [[ "$version" < "17.0.0" ]]; then
        ext="tar.gz";
    elif [[ "$platform" == "darwin" ]]; then
        ext="dmg";
    else
        ext="tar.xz";
    fi;
    # Determine Filename Structure
    if [[ "$version" < "18.0.0" ]]; then
        basename="LLVMEmbeddedToolchainForArm-$version-$os_name";
        filename="release-$version/LLVMEmbeddedToolchainForArm-$version-$os_name.$ext";
        llvm_arm_path="/usr/lib/LLVMEmbeddedToolchainForArm-${version}/";
    else
        basename="LLVM-ET-Arm-$version-$os_name";
        filename="release-$version/LLVM-ET-Arm-$version-$os_name.$ext";
        llvm_arm_path="/usr/lib/LLVM-ET-Arm-${version}/";
    fi;
    export filename="$filename" basename="$basename" llvm_arm_path="$llvm_arm_path" ext="$ext";
    sudo mkdir -p "$llvm_arm_path/bin";
    tmp_file="$(mktemp)";  
    if [[ -d "${llvm_arm_path}" ]]; then
      echo "Downloading: ${download}/${filename}";         
      sudo wget -qO "llvm-embedded-toolchain-for-arm-$version.$ext" "$download/$filename" >/dev/null;
      sudo tar -xJvf "llvm-embedded-toolchain-for-arm-$version.$ext" -C "$llvm_arm_path" --strip-components=1 >/dev/null && rm -vrf "llvm-embedded-toolchain-for-arm-$version.$ext";
    else
      echo "Error: Could not download llvm-embedded-toolchain-for-arm-$version" >&2
      exit 2
    fi;
    sudo chmod -R 0755 "$llvm_arm_path";
    sudo chown -R "$user:$user" "$llvm_arm_path";
    echo "$llvm_arm_path/bin" >> "${tmp_file}";
    cat "${GITHUB_PATH}" >> "${tmp_file}";
    cat "${tmp_file}" > "${GITHUB_PATH}";
    rm -f -- "${tmp_file}";
    LLVM_ARM_PATH="$llvm_arm_path/bin";
    PATH="${LLVM_ARM_PATH}:${PATH}";  
    # 3. Find Clang Path (Equivalent to setup.findClang)
    clang_exe1=$(sudo find "$llvm_arm_path" -xdev -type f -name "clang-${version%%.*}" -print);
    clang_exe2="${LLVM_ARM_PATH}/clang-${version%%.*}";
    if [[ ! -x "${clang_exe1}" ]] || [[ ! -f "${clang_exe2}" ]]; then
        echo "Error: Could not find clang-$version executable path" >&2
    fi;
    # 4. Resolve Toolchain Path (Parent directory of /bin)
    LLVM_ARM_TOOLCHAIN="${LLVM_ARM_PATH%/*}";
    # GitHub Actions Outputs (only if running in GH Actions)
    if [[ -n "$LLVM_PATH" ]]; then
        echo "export LLVM_PATH=${LLVM_PATH}:${LLVM_ARM_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
        echo "LLVM_PATH=${LLVM_PATH}:${LLVM_ARM_PATH}" >> "${GITHUB_ENV}";
    else
        echo "export LLVM_PATH=${LLVM_ARM_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
        echo "LLVM_PATH=${LLVM_ARM_PATH}" >> "${GITHUB_ENV}";
    fi;
    # Export custom env vars if requested.
    if [[ -n "$LLVM_TOOLCHAIN" ]]; then
        echo "LLVM_TOOLCHAIN=${LLVM_TOOLCHAIN}:${LLVM_ARM_TOOLCHAIN}" >> "${GITHUB_ENV}";
        echo "export LLVM_TOOLCHAIN=${LLVM_TOOLCHAIN}:${LLVM_ARM_TOOLCHAIN}" | sudo tee -a ~/.bashrc >/dev/null;
    else
        echo "LLVM_TOOLCHAIN=${LLVM_ARM_TOOLCHAIN}" >> "${GITHUB_ENV}";
        echo "export LLVM_TOOLCHAIN=${LLVM_ARM_TOOLCHAIN}" | sudo tee -a ~/.bashrc >/dev/null;
    fi;
    # 5. Export variables (Equivalent to core.exportVariable / core.addPath)
    echo "export PATH=${PATH}" | sudo tee -a ~/.bashrc >/dev/null;
    echo "Added $LLVM_ARM_PATH to PATH";
    echo "LLVM-${version%%.*}: ${LLVM_ARM_PATH}";
    echo "Clang-${version%%.*}: ${clang_exe1:-clang_exe2}";
    echo "Toolchain: ${LLVM_ARM_TOOLCHAIN}";
    echo "LLVM-embedded-toolchain-for-arm-${version} setup completed.";
}

# --- Example Usage ---
# Configuration
download='https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download';
platform="linux";
version="${LLVM_ARM_VERSION}";
user="${USER:-runner}";
arch=$(uname -m);
export platform version user arch download
if [[ ${LLVM_VERSION} == '' ]]; then
     echo "::error;:[$?] llvm-tools missing.";
fi;
if [[ "${version}" == '' ]]; then
     version='19.1.1';
fi;
echo -e "\nInstalling llvm-arm-$version: $(llvm_arm_install $version $platform $download $user $arch)\n" || echo -e "::error;:[$?] Setting up llvm-embedded-toolchain-for-arm failed.\n";
