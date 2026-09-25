# 1. Clean up old build trees and local manifests
rm -rf .repo/local_manifests/
rm -rf device/lge
rm -rf kernel/lge
rm -rf vendor/lge
rm -rf hardware/lge
rm -rf out/target/product/alphaplus

rm -rf out/target/product/*/system/etc/Changelog.txt \
       out/target/product/*/obj/ETC/Changelog.txt_intermediates \
       out/target/product/*/gen/ETC/Changelog.txt_intermediates

# 2. Initialize crDroid 15.0 repository
repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --depth=1 --git-lfs --no-clone-bundle

# 3. Fetch local manifest
mkdir -p .repo/local_manifests
curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
    -o .repo/local_manifests/alphaplus.xml

# 4. Sync repositories
/opt/crave/resync.sh

# 5. Patch ContactsProvider compilation error
CP_TARGET="packages/providers/ContactsProvider/src/com/android/providers/contacts/util/SelectionBuilder.java"

if [ -f "$CP_TARGET" ]; then
    if grep -q 'SQLiteTokenizer\.OPTION_CHECK_BRACKETS' "$CP_TARGET"; then
        echo "=== Patching ContactsProvider SelectionBuilder.java ==="
        sed -i 's/SQLiteTokenizer\.OPTION_CHECK_BRACKETS/0/g' "$CP_TARGET"
    else
        echo "OPTION_CHECK_BRACKETS not found, patch not required."
    fi
else
    echo "ERROR: $CP_TARGET not found."
    exit 1
fi

# 6. Configure 50G ccache
if command -v ccache >/dev/null 2>&1; then
    ccache --set-config max_size=50G
    ccache --set-config compression=true
    ccache --show-config
else
    apt-get update
    apt-get install -y ccache
    ccache --set-config max_size=50G
    ccache --set-config compression=true
    ccache --show-config
fi

# 7. Disable Ninja sandbox
export DISABLE_NINJA_SANDBOX=true

# 8. Build crDroid
source build/envsetup.sh
brunch alphaplus
