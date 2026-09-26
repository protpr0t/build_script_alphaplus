#!/bin/bash
set -e

# 1. Initialize DerpFest 15.2 repository
repo init -u https://github.com/DerpFest-LOS/android_manifest.git -b 15.2 --depth=1 --git-lfs --no-clone-bundle

# 2. Fetch local manifest
mkdir -p .repo/local_manifests
curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
    -o .repo/local_manifests/alphaplus.xml

# Fix repo names inside local manifest if fetched directly from remote
sed -i 's/proprietary_vendor_lge_alphaplus/android_vendor_lge_alphaplus/g' .repo/local_manifests/alphaplus.xml
sed -i 's/proprietary_vendor_lge_sm8150-common/android_vendor_lge_sm8150-common/g' .repo/local_manifests/alphaplus.xml

# 3. Sync repositories using Crave resync script
/opt/crave/resync.sh

# 4. Configure 50G ccache
if command -v ccache >/dev/null 2>&1; then
    ccache --set-config max_size=50G
    ccache --set-config compression=true
    ccache --show-config
else
    apt-get update && apt-get install -y ccache
    ccache --set-config max_size=50G
    ccache --set-config compression=true
    ccache --show-config
fi

# 5. Set build environment flags
export DISABLE_NINJA_SANDBOX=true

# 6. Build DerpFest
source build/envsetup.sh
make installclean
lunch derp_alphaplus-bp1a-userdebug
mka derp
