#!/bin/bash
set -e

export DERP_BUILD_TYPE=UNOFFICIAL
export WITH_GAPPS=true
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

repo init -u https://github.com/DerpFest-AOSP/android_manifest.git -b 16.2 --depth=1 --git-lfs --no-clone-bundle

mv .repo/local_manifests /tmp/old_manifests 2>/dev/null || true
git clone https://github.com/protpr0t/local_manifest_alphaplus.git -b main .repo/local_manifests

/opt/crave/resync.sh

source build/envsetup.sh

lunch derp_alphaplus-bp4a-userdebug

m installclean
mka derp
