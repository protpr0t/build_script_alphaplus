#!/bin/bash
set -e

if [ -d .repo/local_manifests ]; then
  mv .repo/local_manifests /tmp/old_manifests_$(date +%s)
fi

repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --depth=1 --git-lfs --no-clone-bundle
git clone https://github.com/protpr0t/local_manifest_alphaplus.git -b main .repo/local_manifests
/opt/crave/resync.sh
source build/envsetup.sh

mkdir -p vendor/lineage-priv/keys
subject='/C=US/ST=California/L=Los Angeles/O=AxionOS/OU=AxionOS/CN=AxionOS'
for x in releasekey platform shared media networkstack testkey cyngn-priv-app bluetooth sdk_sandbox verifiedboot nfc; do
  if [ ! -f vendor/lineage-priv/keys/$x.pk8 ]; then
    echo "" | ./development/tools/make_key vendor/lineage-priv/keys/$x "$subject"
  fi
done
echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey" > vendor/lineage-priv/keys/keys.mk

axion alphaplus gms
ax -br
