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
    local base_url='https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download';
    local arch=$4
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
    sudo mkdir -p "$llvm_arm_path";
    echo "${base_url}/${filename}";
    export filename llvm_arm_path base_name version ext
    echo -e "INSTALLING:\n $(llvm_arm_install $version $ext $base_url $filename $llvm_arm_path $user $arch)\n";
}

# Logic for getSHA256
get_sha256() {
    local url=$(get_distribution_url "$1" "$2")
    # Fetch content, follow redirects (-L), and get the first word
    curl -sL "${url}.sha256" | awk '{print $1}'
}

llvm_arm_install() {
    version=$1
    ext=$2
    base_url=$3
    filename=$4
    llvm_arm_path=$5 
    user=$6
    arch=$7
    tmp_file="$(mktemp)";
    sudo wget -qO "llvm-embedded-toolchain-for-arm-$version.$ext" "$base_url/$filename" >/dev/null;
    sudo tar -xJvf "llvm-embedded-toolchain-for-arm-$version.$ext" -C "$llvm_arm_path" >/dev/null && rm -vrf "llvm-embedded-toolchain-for-arm-$version.$ext";
    sudo chmod -R 0755 "$llvm_arm_path";
    sudo chown -R "$user:$user" "$llvm_arm_path";
    echo "$llvm_arm_path" >> "${tmp_file}";
    cat "${GITHUB_PATH}" >> "${tmp_file}";
    cat "${tmp_file}" > "${GITHUB_PATH}";
    rm -f -- "${tmp_file}";
    LLVM_ARM_PATH="$llvm_arm_path";
    PATH="${LLVM_ARM_PATH}/bin:${PATH}";  
    # 3. Find Clang Path (Equivalent to setup.findClang)
    if [[ ! -d "$LLVM_ARM_PATH" ]]; then
        echo "Error: Could not find llvm-embedded-toolchain-for-arm-$version executable path" >&2
        exit 1
    fi;
    # 4. Resolve Toolchain Path (Parent directory of /bin)
    LLVM_ARM_TOOLCHAIN="${LLVM_ARM_PATH}/${filename%.*}-${arch}";
    # 5. Export variables (Equivalent to core.exportVariable / core.addPath)
    echo "Added $LLVM_ARM_PATH to PATH";
    # Export custom env vars if requested
    if [[ -n "$LLVM_ARM_TOOLCHAIN" ]]; then
        echo "export LLVM_PATH=${LLVM_PATH}:${LLVM_ARM_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
        echo "export LLVM_TOOLCHAIN=${LLVM_TOOLCHAIN}:${LLVM_ARM_TOOLCHAIN}" | sudo tee -a ~/.bashrc >/dev/null;
    fi;
    # GitHub Actions Outputs (only if running in GH Actions)
    if [[ -n "$GITHUB_ENV" ]]; then
        echo "LLVM_PATH=${LLVM_PATH}:${LLVM_ARM_PATH}" >> "${GITHUB_ENV}";
        echo "LLVM_TOOLCHAIN=${LLVM_TOOLCHAIN}:${LLVM_ARM_TOOLCHAIN}" >> "${GITHUB_ENV}";
    fi;
    echo "export PATH=${PATH}" | sudo tee -a ~/.bashrc >/dev/null;
    echo -e "\nLLVM-embedded-toolchain-for-arm: $version setup completed.";
    echo "llvm-${version%%.*}: $LLVM_ARM_PATH";
    echo "clang-${version%%.*}: $LLVM_ARM_PATH/bin/clang-${version%%.*}";
    echo -e "Toolchain: $LLVM_ARM_TOOLCHAIN\n";
}

# --- Example Usage ---
# Configuration
platform="linux";
version="${LLVM_ARM_VERSION}";
user="${USER:-runner}";
arch=$(uname -m);
export USER platform version arch
if [[ ${LLVM_VERSION} == '' ]]; then
     echo "::error;:[$?] llvm-tools missing.";
fi;
if [[ ${version} == '' ]]; then
     version='19.1.1';
fi;
if has_sha256 "$version"; then
    echo -e "URL: $(get_distribution_url $version $platform $user $arch)\n";
    echo -e "SHA256: $(get_sha256 $version $platform)\n";
else
    echo -e "::error;:[$?] Setting up llvm-embedded-toolchain-for-arm.\n";
fi;
