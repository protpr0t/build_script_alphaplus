#!/bin/bash
set -e

repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --depth=1 --git-lfs --no-clone-bundle
mv .repo/local_manifests /tmp/old_manifests 2>/dev/null || true
git clone https://github.com/protpr0t/local_manifest_alphaplus.git -b main .repo/local_manifests
/opt/crave/resync.sh
source build/envsetup.sh
gk -s
axion alphaplus core
ax -br -j$(nproc)
