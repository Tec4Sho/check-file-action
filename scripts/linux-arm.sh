#!/bin/bash

set +e

# Logic for hasSHA256
has_sha256() {
    [[ "$1" != "13.0.0" && "$1" != "14.0.0" ]]
}

# Logic for distributionUrl
get_distribution_url() {
    local version=$1
    local platform=$2 # Expected: linux, darwin, or win32
    local os_name="";
    local ext="";
    local user=$3
    local base_url=$4
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
        filename="release-$version/LLVMEmbeddedToolchainForArm-$version-$os_name.$ext";
        llvm_arm_path="/usr/lib/LLVMEmbeddedToolchainForArm-${version}/bin";
    else
        filename="release-$version/LLVM-ET-Arm-$version-$os_name.$ext";
        llvm_arm_path="/usr/lib/LLVM-ET-Arm-${version}/bin";
    fi;
    echo "${BASE_URL}/${filename}";
    export filename llvm_arm_path version ext
    echo -e "INSTALLING: $(llvm_arm_install $version $ext $base_url $filename $llvm_arm_path $user)\n";
}

# Logic for getSHA256
get_sha256() {
    local url=$(get_distribution_url "$1" "$2")
    # Fetch content, follow redirects (-L), and get the first word
    curl -sL "${url}.sha256" | awk '{print $1}'
}

llvm_arm_install() {
    tmp_file="$(mktemp)";
    sudo wget -qO "llvm-embedded-toolchain-for-arm-$1.$2" "$3/$4" >/dev/null;
    sudo tar xf "llvm-embedded-toolchain-for-arm-$1.$2" -C "$5" "llvm-${1%%.*}" >/dev/null && rm -vrf "llvm-embedded-toolchain-for-arm-$1.$2";
    sudo chown -R "$6:$6" "$5";
    echo "$5" >> "${tmp_file}";
    cat "${GITHUB_PATH}" >>"${tmp_file}";
    cat "${tmp_file}" > "${GITHUB_PATH}";
    rm -f -- "${tmp_file}";
    LLVM_ARM_PATH="$5";
    PATH="${LLVM_ARM_PATH}/bin:${PATH}";  
    # 3. Find Clang Path (Equivalent to setup.findClang)
    if [[ ! -d "$LLVM_ARM_PATH" ]]; then
        echo "Error: Could not find clang executable" >&2
        exit 1
    fi;
    # 4. Resolve Toolchain Path (Parent directory of /bin)
    LLVM_ARM_TOOLCHAIN_PATH=$(realpath "${LLVM_ARM_PATH}/..");
    # 5. Export variables (Equivalent to core.exportVariable / core.addPath)
    echo "Added $LLVM_ARM_PATH to PATH";
    # Export custom env vars if requested
    if [[ -n "$LLVM_ARM_PATH" ]]; then
        echo "export LLVM_ARM_PATH=${LLVM_ARM_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
    fi;
    if [[ -n "$LLVM_ARM_TOOLCHAIN_PATH" ]]; then
        echo "export LLVM_ARM_TOOLCHAIN_PATH=${LLVM_ARM_TOOLCHAIN_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
    fi;
    # GitHub Actions Outputs (only if running in GH Actions)
    if [[ -n "$GITHUB_ENV" ]]; then
        echo "CLANG_PATH=${LLVM_ARM_PATH}" >> "${GITHUB_ENV}";
        echo "LLVM_ARM_TOOLCHAIN=${LLVM_ARM_TOOLCHAIN_PATH}" >> "${GITHUB_ENV}";
    fi;
    echo "export PATH=${PATH}" | sudo tee -a ~/.bashrc >/dev/null;
    echo -e "\nLLVM $1 llvm-embedded-toolchain-for-arm setup complete.";
    echo "llvm-${1%%.*}: $LLVM_ARM_PATH";
    echo -e "Toolchain: $LLVM_ARM_TOOLCHAIN\n";
}

# --- Example Usage ---
# Configuration
base_url='https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download';
platform="linux";
version="${LLVM_ARM_VERSION}";
user="${USER:-runner}";
if [[ ${LLVM_VERSION} == '' ]]; then
     echo "::error;:[$?] llvm-tools missing.";
fi;
if [[ ${version} == '' ]]; then
     version='19.1.1';
fi;
if has_sha256 "$version"; then
    echo "URL: $(get_distribution_url $version $platform $user $base_url)";
    echo -e "SHA256: $(get_sha256 $version $platform)\n";
else
    echo -e "::error;:[$?] Setting up llvm-embedded-toolchain-for-arm.\n";
fi;
