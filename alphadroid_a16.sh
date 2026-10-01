#!/bin/bash
set -e

# Cleanup previous manifests, device/vendor/kernel trees, and out directory
rm -rf .repo/local_manifests/
rm -rf out/target/product/alphaplus
# Cleanup previous changelog to make it always fresh
rm -rf out/target/product/*/system/etc/Changelog.txt \
       out/target/product/*/obj/ETC/Changelog.txt_intermediates \
       out/target/product/*/gen/ETC/Changelog.txt_intermediates

# 2. Initialize AlphaDroid (Android 16 / A16 baseline)
repo init -u https://github.com/AlphaDroid-AOSP/manifest.git -b alpha-16 --depth=1 --git-lfs --no-clone-bundle

# Clone local manifest
git clone https://github.com/protpr0t/local_manifest_alphaplus.git --depth 1 -b main .repo/local_manifests
if [ ! $? -eq 0 ]; then
    mkdir -p .repo/local_manifests
    curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
        -o .repo/local_manifests/alphaplus.xml
fi

# Sync repositories using Crave resync
/opt/crave/resync.sh

# Patch ContactsProvider SQLiteTokenizer compilation error if present
CP_TARGET="packages/providers/ContactsProvider/src/com/android/providers/contacts/util/SelectionBuilder.java"
if [ -f "$CP_TARGET" ]; then
    if grep -q 'SQLiteTokenizer\.OPTION_CHECK_BRACKETS' "$CP_TARGET"; then
        echo "=== Patching ContactsProvider SelectionBuilder.java ==="
        sed -i 's/SQLiteTokenizer\.OPTION_CHECK_BRACKETS/0/g' "$CP_TARGET"
    fi
fi

# Configure CCACHE (30G Limit)
if command -v ccache >/dev/null 2>&1; then
    export USE_CCACHE=1
    export CCACHE_EXEC=$(which ccache)
    export CCACHE_DIR="${HOME}/.ccache"
    ccache --set-config max_size=30G
    ccache --set-config compression=true
    ccache --show-config
fi

# Set build environment flags and start build
export DISABLE_NINJA_SANDBOX=true
source build/envsetup.sh

brunch alphaplus
