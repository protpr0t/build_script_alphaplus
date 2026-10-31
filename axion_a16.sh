#!/bin/bash
set -e

if [ -d .repo/local_manifests ]; then
  mv .repo/local_manifests /tmp/old_manifests_$(date +%s)
fi

repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --depth=1 --git-lfs --no-clone-bundle
git clone https://github.com/protpr0t/local_manifest_alphaplus.git -b main .repo/local_manifests
/opt/crave/resync.sh
source build/envsetup.sh
gk -s
axion alphaplus gms
ax -br -j$(nproc)
