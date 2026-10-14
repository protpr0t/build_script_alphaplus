#!/bin/bash
set -e

# 1. Clean old manifests safely
mkdir -p .repo/local_manifests
find .repo/local_manifests -type f -name "*.xml" -delete

# 2. Inject fresh manifest directly for alphaplus
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

# 3. Initialize AlphaDroid
repo init -u https://github.com/alphadroid-project/manifest.git -b alpha-16.2 --depth=1 --git-lfs --no-clone-bundle

# 4. Clean conflicting sepolicy symlinks safely before sync
if [ -d "device/lineage/sepolicy" ]; then
    git -C device/lineage/sepolicy clean -fdx 2>/dev/null || true
fi
if [ -d "device/alpha/sepolicy" ]; then
    git -C device/alpha/sepolicy clean -fdx 2>/dev/null || true
fi

# 5. Sync repositories
/opt/crave/resync.sh

# 6. Apply fixes and clean up props
# Fix duplicate sepolicy attributes
if [ -f "device/lge/sm8150-common/sepolicy/vendor/attributes" ]; then
    sed -i '/attribute hal_lgdata;/d' device/lge/sm8150-common/sepolicy/vendor/attributes
    sed -i '/attribute hal_lgdata_client;/d' device/lge/sm8150-common/sepolicy/vendor/attributes
    sed -i '/attribute hal_lgdata_server;/d' device/lge/sm8150-common/sepolicy/vendor/attributes
fi

# Fix duplicate fingerprint_device type
if [ -f "device/lge/sm8150-common/sepolicy/vendor/device.te" ]; then
    sed -i '/type fingerprint_device, dev_type;/d' device/lge/sm8150-common/sepolicy/vendor/device.te
fi

find device/lge/ -type f -name "*.prop" -exec sed -i '/AlphaDroidMaintainer/d' {} +
find vendor/alpha/ -type f -name "*.mk" -exec sed -i '/AlphaDroidMaintainer/d' {} + 2>/dev/null

export DISABLE_NINJA_SANDBOX=true

# 7. Disable strict bash checks entirely for the build phase
set +u
source build/envsetup.sh

# 8. Build
breakfast alphaplus
m installclean
mka bacon
