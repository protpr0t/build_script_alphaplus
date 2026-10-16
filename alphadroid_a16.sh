#!/bin/bash
set -e

echo "Cleaning up old local manifests safely..."
destroy .repo/local_manifests || true
mkdir -p .repo/local_manifests

echo "Writing local manifest for alphaplus..."
cat << 'EOF' > .repo/local_manifests/alphaplus.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project path="device/lge/alphaplus" name="protpr0t/android_device_lge_alphaplus" remote="github" revision="alphadroid-23.2" clone-depth="1" />
  <project path="device/lge/sm8150-common" name="protpr0t/android_device_lge_sm8150-common" remote="github" revision="lineage-23.2" clone-depth="1" />
  <project path="hardware/lge" name="LineageOS/android_hardware_lge" remote="github" revision="lineage-23.2" clone-depth="1" />
  <project path="kernel/lge/sm8150" name="rainbowdashh/android_kernel_lge_sm8150" remote="github" revision="lineage-23.2" clone-depth="1" />
  <project path="vendor/lge/alphaplus" name="protpr0t/proprietary_vendor_lge_alphaplus" remote="github" revision="lineage-22.2" clone-depth="1" />
  <project path="vendor/lge/sm8150-common" name="protpr0t/proprietary_vendor_lge_sm8150-common" remote="github" revision="lineage-23.2" clone-depth="1" />
  <project path="hardware/pixelworks/interfaces" name="LineageOS/android_hardware_pixelworks_interfaces" remote="github" revision="lineage-23.2" clone-depth="1" />
</manifest>
EOF

echo "Initializing AlphaDroid 16.2 repository..."
repo init -u https://github.com/alphadroid-project/manifest.git -b alpha-16.2 --depth=1 --git-lfs --no-clone-bundle

echo "Cleaning sepolicy directories if they exist..."
if [ -d "device/lineage/sepolicy" ]; then
    git -C device/lineage/sepolicy clean -fdx 2>/dev/null || true
fi
if [ -d "device/alpha/sepolicy" ]; then
    git -C device/alpha/sepolicy clean -fdx 2>/dev/null || true
fi

echo "Running Crave resync..."
/opt/crave/resync.sh

echo "Patching sm8150-common sepolicy attributes and device.te..."
if [ -f "device/lge/sm8150-common/sepolicy/vendor/attributes" ]; then
    sed -i '/attribute hal_lgdata;/d' device/lge/sm8150-common/sepolicy/vendor/attributes
    sed -i '/attribute hal_lgdata_client;/d' device/lge/sm8150-common/sepolicy/vendor/attributes
    sed -i '/attribute hal_lgdata_server;/d' device/lge/sm8150-common/sepolicy/vendor/attributes
fi

if [ -f "device/lge/sm8150-common/sepolicy/vendor/device.te" ]; then
    sed -i '/type fingerprint_device, dev_type;/d' device/lge/sm8150-common/sepolicy/vendor/device.te
    sed -i '/type encrypt_block_device, dev_type;/d' device/lge/sm8150-common/sepolicy/vendor/device.te
fi

echo "Removing old AlphaDroid maintainer props..."
find device/lge/ -type f -name "*.prop" -exec sed -i '/AlphaDroidMaintainer/d' {} +
find vendor/alpha/ -type f -name "*.mk" -exec sed -i '/AlphaDroidMaintainer/d' {} + 2>/dev/null

echo "Setting up build environment..."
set +u
source build/envsetup.sh

echo "Selecting target and initiating build..."
lunch alpha_alphaplus-userdebug
m installclean
mka bacon
