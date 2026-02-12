#!/bin/bash

# Configuration
BASE_URL="https://github.com"

# Logic for hasSHA256
has_sha256() {
    [[ "$1" != "13.0.0" && "$1" != "14.0.0" ]]
}

# Logic for distributionUrl
get_distribution_url() {
    local version=$1
    local platform=$2 # Expected: linux, darwin, or win32
    local os_name=""
    local ext=""

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
                if [[ "$version" < "18.0.0" ]]; then os_name="Darwin"; else os_name="Darwin-universal"; fi
                ;;
            linux) os_name="Linux-x86_64" ;;
            win32) os_name="Windows-x86_64" ;;
            *) echo "Unsupported platform $platform" >&2; return 1 ;;
        esac
    fi

    # Determine Extension
    if [[ "$platform" == "win32" ]]; then
        ext="zip";
    elif [[ "$version" < "17.0.0" ]]; then
        ext="tar.gz"
    elif [[ "$platform" == "darwin" ]]; then
        ext="dmg";
    else
        ext="tar.xz";
    fi

    # Determine Filename Structure
    if [[ "$version" < "18.0.0" ]]; then
        filename="release-$version/LLVMEmbeddedToolchainForArm-$version-$os_name.$ext";
    else
        filename="release-$version/LLVM-ET-Arm-$version-$os_name.$ext";
    fi

    echo "$BASE_URL/$filename"
}

# Logic for getSHA256
get_sha256() {
    local url=$(get_distribution_url "$1" "$2")
    # Fetch content, follow redirects (-L), and get the first word
    curl -sL "${url}.sha256" | awk '{print $1}'
}

llvm_final() {
    # 3. Find Clang Path (Equivalent to setup.findClang)
    CLANG_PATH=$(which clang-"${RELEASE%%.*}" || which clang)
    
    if [[ -z "$CLANG_PATH" ]]; then
        echo "Error: Could not find clang executable" >&2
        exit 1
    fi

    # 4. Resolve Toolchain Path (Parent directory of /bin)
    BIN_DIR=$(dirname "$CLANG_PATH")
    TOOLCHAIN_PATH=$(realpath "$BIN_DIR/..")

    # 5. Export variables (Equivalent to core.exportVariable / core.addPath)
    echo "Adding $BIN_DIR to PATH"
    export PATH="$BIN_DIR:$PATH"

    # Export custom env vars if requested
    if [[ -n "$CLANG_PATH" ]]; then
        export "LLVM_ARM_PATH=$CLANG_PATH" | sudo tee -a ~/.bashrc >/dev/null;
    fi

    if [[ -n "$TOOLCHAIN_PATH" ]]; then
        export "LLVM_ARM_TOOLCHAIN=$TOOLCHAIN_PATH" | sudo tee -a ~/.bashrc >/dev/null;
    fi

    # GitHub Actions Outputs (only if running in GH Actions)
    if [[ -n "$GITHUB_ENV" ]]; then
        echo "LLVM_ARM_PATH=$CLANG_PATH" >> "$GITHUB_ENV"
        echo "LLVM_ARM_TOOLCHAIN=$TOOLCHAIN_PATH" >> "$GITHUB_ENV"
    fi

    echo -e "\nLLVM $RELEASE llvm-embedded-toolchain-for-arm setup complete.";
    echo "Clang: $LLVM_ARM_PATH";
    echo -e "Toolchain: $LLVM_ARM_TOOLCHAIN\n";
}
# --- Example Usage ---
PLATFORM="linux"
VERSION="${LLVM_ARM_VERSION:-latest}"
RELEASE="${LLVM_VERSION}";
if [[ ${RELEASE} == '' ]]; then
     echo "::error;:[$?] llvm-tools missing.";
fi;

if has_sha256 "$VERSION"; then
    echo "URL: $(get_distribution_url $VERSION $PLATFORM)";
    echo -e "SHA256: $(get_sha256 $VERSION $PLATFORM)\n";
else
    echo -e "::error;:[$?] Setting up llvm-embedded-toolchain-for-arm.\n";
fi;
