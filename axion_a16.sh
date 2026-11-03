set -e

if [ -d .repo/local_manifests ]; then
  mv .repo/local_manifests /tmp/old_manifests_$(date +%s)
fi

repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --depth=1 --git-lfs --no-clone-bundle
git clone https://github.com/protpr0t/local_manifest_alphaplus.git -b main .repo/local_manifests
/opt/crave/resync.sh

mkdir -p vendor/lineage-priv
if [ -d vendor/lineage-priv/keys ]; then
  mv vendor/lineage-priv/keys /tmp/old_keys_$(date +%s)
fi
git clone https://github.com/protpr0t/android_vendor_lineage-priv_keys.git vendor/lineage-priv/keys

if [ ! -f device/lge/alphaplus/lineage_alphaplus.mk ]; then
  if [ -d device/lge/alphaplus ]; then
    mv device/lge/alphaplus /tmp/old_alphaplus_$(date +%s)
  fi
  git clone https://github.com/protpr0t/android_device_lge_alphaplus.git -b axion device/lge/alphaplus
fi
ls device/lge/alphaplus

export BUILD_USERNAME=protpr0t
export BUILD_HOSTNAME=crave
export AXION_BUILD_TYPE=UNOFFICIAL

source build/envsetup.sh
axion alphaplus userdebug gms
m installclean
ax -br
