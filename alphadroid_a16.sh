#!/bin/bash
set -e

# 1. Nonaktifkan otentikasi interaktif Git
export GIT_TERMINAL_PROMPT=0
git config --global core.askPass ""
git config --global credential.helper ""

# 2. Initialize AlphaDroid A16 using the correct project manifest URL
repo init -u https://github.com/alphadroid-project/manifest.git \
          -b alpha-16 \
          --depth=1 \
          --git-lfs \
          --no-clone-bundle \
          --no-repo-verify

# 3. Fetch local manifest
git clone https://github.com/protpr0t/local_manifest_alphaplus.git --depth 1 -b main .repo/local_manifests || {
    mkdir -p .repo/local_manifests
    curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
        -o .repo/local_manifests/alphaplus.xml
}

# 4. PERBAIKAN REPOSITORI VENDOR (Ubah ke sumber publik yang valid)
MANIFEST_FILE=".repo/local_manifests/alphaplus.xml"
if [ -f "$MANIFEST_FILE" ]; then
    echo "=== Patching local manifest vendor repositories ==="
    # Perbaiki nama repo vendor alphaplus milik TheMuppets
    sed -i 's|TheMuppets/android_vendor_lge_alphaplus|TheMuppets/proprietary_vendor_lge_alphaplus|g' "$MANIFEST_FILE"
    
    # Perbaiki repo vendor sm8150-common milik rainbowdashh ke TheMuppets publik
    sed -i 's|rainbowdashh/android_vendor_lge_sm8150-common|TheMuppets/proprietary_vendor_lge_sm8150-common|g' "$MANIFEST_FILE"
    
    # Perbaiki repo kernel/device sm8150 jika ada
    sed -i 's|rainbowdashh/android_device_lge_sm8150-common|protpr0t/android_device_lge_sm8150-common|g' "$MANIFEST_FILE"
    sed -i 's|rainbowdashh/android_kernel_lge_sm8150|LineageOS/android_kernel_lge_sm8150|g' "$MANIFEST_FILE"
fi

# 5. Sync repositories
/opt/crave/resync.sh

# 6. Patch ContactsProvider SQLiteTokenizer compilation error jika ada
CP_TARGET="packages/providers/ContactsProvider/src/com/android/providers/contacts/util/SelectionBuilder.java"
if [ -f "$CP_TARGET" ]; then
    if grep -q 'SQLiteTokenizer\.OPTION_CHECK_BRACKETS' "$CP_TARGET"; then
        echo "=== Patching ContactsProvider SelectionBuilder.java ==="
        sed -i 's/SQLiteTokenizer\.OPTION_CHECK_BRACKETS/0/g' "$CP_TARGET"
    fi
fi

# 7. Configure CCACHE (30G Limit)
if command -v ccache >/dev/null 2>&1; then
    export USE_CCACHE=1
    export CCACHE_EXEC=$(which ccache)
    export CCACHE_DIR="${HOME}/.ccache"
    ccache --set-config max_size=30G
    ccache --set-config compression=true
    ccache --show-config
fi

# 8. Set environment flags & Jalankan Build
export DISABLE_NINJA_SANDBOX=true
source build/envsetup.sh

brunch alphaplus
