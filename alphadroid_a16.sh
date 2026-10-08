#!/bin/bash
set -euo pipefail

export GIT_TERMINAL_PROMPT=0
git config --global core.askPass ""
git config --global credential.helper ""

# Repo init first so .repo exists
repo init -u https://github.com/alphadroid-project/manifest.git \
    -b alpha-16.2 \
    --depth=1 \
    --git-lfs \
    --no-clone-bundle \
    --no-repo-verify

# Prepare local manifests
mkdir -p .repo/local_manifests

# Fetch local manifest
if git clone https://github.com/protpr0t/local_manifest_alphaplus.git --depth 1 -b main /tmp/local_manifest_alphaplus 2>/dev/null; then
    cp /tmp/local_manifest_alphaplus/*.xml .repo/local_manifests/ 2>/dev/null || true
else
    curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
        -o .repo/local_manifests/alphaplus.xml
fi

# Optional: remove hardware/lge references only if they are causing duplicate-path issues
for f in .repo/local_manifests/*.xml; do
    [ -f "$f" ] || continue
    sed -i '/hardware\/lge/d' "$f"
done

# Sync source
/opt/crave/resync.sh

# Patch ContactsProvider if the known token exists
CP_TARGET="packages/providers/ContactsProvider/src/com/android/providers/contacts/util/SelectionBuilder.java"
if [ -f "$CP_TARGET" ] && grep -q 'SQLiteTokenizer\.OPTION_CHECK_BRACKETS' "$CP_TARGET"; then
    echo "=== Patching ContactsProvider SelectionBuilder.java ==="
    sed -i 's/SQLiteTokenizer\.OPTION_CHECK_BRACKETS/0/g' "$CP_TARGET"
fi

# Build environment
export DISABLE_NINJA_SANDBOX=true
source build/envsetup.sh
lunch alphaplus-userdebug

# Clean build outputs before building
make installclean

# Build
mka bacon
