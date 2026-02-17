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
    local llvm=$6
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
    else
        filename="release-$version/LLVM-ET-Arm-$version-$os_name.$ext";
    fi;
    llvm_arm_path="/usr/lib/llvm-arm-${version%%.*}/bin";
    export filename="$filename" llvm_arm_path="$llvm_arm_path" ext="$ext";
    sudo mkdir -p "$llvm_arm_path";
    tmp_file="$(mktemp)";
    if [[ -d "${llvm_arm_path}" ]]; then
      echo "Downloading: ${download}/${filename}";         
      sudo wget -qO "llvm-embedded-toolchain-for-arm-$version.$ext" "$download/$filename" >/dev/null;
      sudo tar -xJvf "llvm-embedded-toolchain-for-arm-$version.$ext" -C "${llvm_arm_path%/*}" --strip-components=1 >/dev/null && rm -rf "llvm-embedded-toolchain-for-arm-$version.$ext";
    else
      echo "Error: Could not download llvm-embedded-toolchain-for-arm-$version" >&2
      exit 2
    fi;
    sudo chmod -R 0755 "$llvm_arm_path";
    echo "$llvm_arm_path" >> "${tmp_file}";
    cat "${GITHUB_PATH}" >> "${tmp_file}";
    cat "${tmp_file}" > "${GITHUB_PATH}";
    rm -f -- "${tmp_file}";
    LLVM_ARM_PATH="$llvm_arm_path";
    # 3. Find Clang Path (Equivalent to setup.findClang)
    clang_exe1=$(sudo find "${llvm_arm_path%/*}" -xdev -type f -name "clang-${version%%.*}" -print);
    clang_exe2="${LLVM_ARM_PATH}/clang-${version%%.*}";
    # run checks
    if [[ ! -x "$clang_exe1" || ! -x "$clang_exe2" ]]; then
        echo "Error: Could not find clang-$version executable path" >&2
        exit 2
    fi;
    if [[ ! $(cat "${GITHUB_PATH}" | grep -sF "$LLVM_ARM_PATH") ]]; then
        echo 'Updating github paths ......'
        echo "LLVM_ARM_PATH=${LLVM_ARM_PATH}" >> "${GITHUB_PATH}";
    fi;
    # 4. Resolve Toolchain Path (Parent directory of /bin)
    LLVM_ARM_TOOLCHAIN="${LLVM_ARM_PATH%/*}";
    # GitHub Actions Outputs (only if running in GH Actions)
    if [[ -n "$LLVM_PATH" ]]; then
        echo "Adding $LLVM_ARM_PATH with $LLVM_PATH to PATH";
        echo "export LLVM_PATH=${LLVM_ARM_PATH}:${LLVM_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
        echo "LLVM_PATH=${LLVM_ARM_PATH}:${LLVM_PATH}:" >> "${GITHUB_ENV}";
    else
        echo "Adding $LLVM_ARM_PATH to PATH";
        echo "export LLVM_PATH=${LLVM_ARM_PATH}" | sudo tee -a ~/.bashrc >/dev/null;
        echo "LLVM_PATH=${LLVM_ARM_PATH}" >> "${GITHUB_ENV}";
    fi;
    # Export custom env vars if requested.
    if [[ -n "$LLVM_TOOLCHAIN" ]]; then
        echo "LLVM_TOOLCHAIN=${LLVM_ARM_TOOLCHAIN}:${LLVM_TOOLCHAIN}" >> "${GITHUB_ENV}";
        echo "export LLVM_TOOLCHAIN=${LLVM_TOOLCHAIN}:${LLVM_ARM_TOOLCHAIN}" | sudo tee -a ~/.bashrc >/dev/null;
    else
        echo "LLVM_TOOLCHAIN=${LLVM_ARM_TOOLCHAIN}" >> "${GITHUB_ENV}";
        echo "export LLVM_TOOLCHAIN=${LLVM_ARM_TOOLCHAIN}" | sudo tee -a ~/.bashrc >/dev/null;
    fi;
    export PATH="${LLVM_ARM_PATH}:${PATH}";
    # Ensure the source directory exists
    if [[ ! -d "$LLVM_ARM_PATH" ]]; then
        echo "Source directory $LLVM_ARM_PATH does not exist."
        exit 1
    fi;
    check1="clang-${version%%.*}";
    check2=$(find /usr -type d -name "*linux-gnueabihf*");
    echo "Clearing clang alternatives.";
    hash -r
    unalias clang 2>/dev/null;
    unalias clang++ 2>/dev/null;
    alias clang-${llvm}=$LLVM_ARM_PATH/clang-${version%%.*} 2>/dev/null;
    # Iterate over all files in the source directory
    sudo update-alternatives --install /usr/bin/clang clang $LLVM_ARM_PATH/clang 200 >/dev/null;
    sudo update-alternatives --install /usr/bin/cc cc $LLVM_ARM_PATH/clang 200 >/dev/null;
    sudo update-alternatives --install /usr/bin/clang++ clang++ $LLVM_ARM_PATH/clang++ 200 >/dev/null;
    sudo update-alternatives --install /usr/bin/c++ c++ $LLVM_ARM_PATH/clang++ 200 >/dev/null;
    sudo update-alternatives --set clang $LLVM_ARM_PATH/clang
    sudo update-alternatives --set clang++ $LLVM_ARM_PATH/clang++
    # 5. Export variables (Equivalent to core.exportVariable / core.addPath)
    echo "Updated LLVM Toolchain to llvm-$llvm and llvm-arm-${version%%.*} ......";
    echo "clang: $(readlink -f $(which clang))";
    echo "Toolchain: ${LLVM_ARM_TOOLCHAIN}";
    sudo dpkg --add-architecture i386 2>/dev/null
    sudo apt-get -yq update >/dev/null
    sudo aptitude install -yq sudo apt-get install -y linux-headers-generic-armhf gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf libc6-dev-armhf-cross gcc-multilib libc6-dev libgcc-s1 libc6:i386 libstdc++6:i386 gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross >/dev/null 2>&1
    LIBRARY_PATH="${LLVM_ARM_TOOLCHAIN}/lib:/usr/lib/gcc:${LIBRARY_PATH}";
    LIBRARY_PATH="${LIBRARY_PATH%:}";
    export LIBRARY_PATH="${LIBRARY_PATH%:}";
    echo -e "Compilier: ${check1}\nPaths: ${LLVM_ARM_PATH}\n$check2";
    echo -e "Library Path: $LIBRARY_PATH";
    echo -e "\n\033[32mllvm-embedded-toolchain-for-arm-\033[0m${version}\033[32m has been installed to\033[0m \033[1m${LLVM_ARM_TOOLCHAIN}\033[0m.";
    echo "export LIBRARY_PATH=$LIBRARY_PATH" | sudo tee -a ~/.bashrc >/dev/null;
    echo "export PATH=${PATH}" | sudo tee -a ~/.bashrc >/dev/null;
}

# --- Example Usage ---
# Configuration
download='https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download';
platform="linux";
version="${LLVM_ARM_VERSION}";
llvm="${LLVM_VERSION}";
user="${USER:-runner}";
arch=$(uname -m);
export platform version user arch download llvm
if [[ "${LLVM_VERSION}" == '' ]]; then
     echo "::error;:[$?] llvm-tools missing.";
fi;
if [[ "${version}" == '' ]]; then
     version='19.1.1';
fi;
echo -e "Installing llvm-arm-$version:\n$(llvm_arm_install $version $platform $download $user $arch $llvm)\n" || echo -e "::error;:[$?] Setting up llvm-embedded-toolchain-for-arm failed.\n";
