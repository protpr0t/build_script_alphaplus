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
curl -s -L "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" -o .repo/local_manifests/alphaplus.xml

# 4. Sync repositories
/opt/crave/resync.sh

# 5. Patch ContactsProvider compilation error (OPTION_CHECK_BRACKETS)
CP_TARGET="packages/providers/ContactsProvider/src/com/android/providers/contacts/util/SelectionBuilder.java"
if [ -f "$CP_TARGET" ]; then
    echo "=== Patching ContactsProvider SelectionBuilder.java ==="
    sed -i 's/SQLiteTokenizer\.OPTION_CHECK_BRACKETS/0/g' "$CP_TARGET"
fi

# 6. Set environment flags and build
export DISABLE_NINJA_SANDBOX=true

source build/envsetup.sh
brunch alphaplus
