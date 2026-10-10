#!/bin/bash
set -e

# 1. Nonaktifkan otentikasi interaktif Git
export GIT_TERMINAL_PROMPT=0
git config --global core.askPass ""
git config --global credential.helper ""

# 2. Safely clear the broken local manifests from previous Crave runs (without rm -rf)
if [ -d ".repo/local_manifests" ]; then
    mv .repo/local_manifests ".repo/local_manifests_backup_$(date +%s)" 2>/dev/null || true
fi

# 3. Fetch local manifest fresh (This will pull your updated XML with the <remove-project> tags)
git clone https://github.com/protpr0t/local_manifest_alphaplus.git --depth 1 -b main .repo/local_manifests || {
    mkdir -p .repo/local_manifests
    curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
        -o .repo/local_manifests/alphaplus.xml
}

# 4. Initialize AlphaDroid A16
repo init -u https://github.com/alphadroid-project/manifest.git \
          -b alpha-16.2 \
          --depth=1 \
          --git-lfs \
          --no-clone-bundle \
          --no-repo-verify

# 5. Clean conflicting sepolicy path safely
if [ -d "device/lineage/sepolicy" ]; then
    git -C device/lineage/sepolicy clean -fdx 2>/dev/null || true
fi
if [ -d "device/alpha/sepolicy" ]; then
    git -C device/alpha/sepolicy clean -fdx 2>/dev/null || true
fi

# 6. Sync repositories
/opt/crave/resync.sh

# 7. Patch ContactsProvider SQLiteTokenizer compilation error jika ada
CP_TARGET="packages/providers/ContactsProvider/src/com/android/providers/contacts/util/SelectionBuilder.java"
if [ -f "$CP_TARGET" ]; then
    if grep -q 'SQLiteTokenizer\.OPTION_CHECK_BRACKETS' "$CP_TARGET"; then
        echo "=== Patching ContactsProvider SelectionBuilder.java ==="
        sed -i 's/SQLiteTokenizer\.OPTION_CHECK_BRACKETS/0/g' "$CP_TARGET"
    fi
fi

# 8. Set environment flags & Disable strict bash checks temporarily
export DISABLE_NINJA_SANDBOX=true

set +u
set +e
source build/envsetup.sh
set -e

# 9. Jalankan Build
brunch alphaplus
