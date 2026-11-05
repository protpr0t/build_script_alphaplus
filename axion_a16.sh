#!/bin/bash
set -e

STAMP=$(date +%s)

backup() {
  if [ -e "$1" ]; then
    mv "$1" "/tmp/bak_${STAMP}_$(echo "$1" | tr '/' '_')"
  fi
  return 0
}

echo "debug - init $(pwd)"
backup .repo/local_manifests
repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --depth=1 --git-lfs --no-clone-bundle
git clone https://github.com/protpr0t/local_manifest_alphaplus.git -b main .repo/local_manifests

echo "debug - sync $(pwd)"
/opt/crave/resync.sh

export BUILD_USERNAME=protpr0t
export BUILD_HOSTNAME=crave
export TZ=Asia/Jakarta
export KBUILD_USERNAME="$BUILD_USERNAME"
export KBUILD_HOSTNAME="$BUILD_HOSTNAME"

echo "debug - device tree $(pwd)"
if [ ! -f device/lge/alphaplus/lineage_alphaplus.mk ]; then
  backup device/lge/alphaplus
  git clone --depth=1 -b axion https://github.com/protpr0t/android_device_lge_alphaplus device/lge/alphaplus
fi
ls device/lge/alphaplus
ls kernel/lge/sm8150/arch/arm64/configs/vendor | grep -i alpha || true

echo "debug - build $(pwd)"
source build/envsetup.sh
gk -s || true
axionSync
export AXION_BUILD_TYPE=UNOFFICIAL
axion alphaplus userdebug gms
m installclean
ax -br
