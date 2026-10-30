set -e

export DERP_BUILD_TYPE=UNOFFICIAL
export WITH_GAPPS=true
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

LOCAL_MANIFEST_BRANCH=main

if [ -d .repo/manifests ]; then
  git -C .repo/manifests stash --include-untracked >/dev/null 2>&1 || true
fi

repo init -u https://github.com/DerpFest-AOSP/android_manifest.git -b 16.2 --depth=1 --git-lfs --no-clone-bundle

if [ -d .repo/local_manifests ]; then
  mv .repo/local_manifests "/tmp/old_manifests_$(date +%s)"
fi
git clone https://github.com/protpr0t/local_manifest_alphaplus.git -b "$LOCAL_MANIFEST_BRANCH" .repo/local_manifests

grep -rn "device/lineage/sepolicy" .repo/manifests .repo/local_manifests || true

/opt/crave/resync.sh

if [ ! -f device/lineage/sepolicy/libperfmgr/sepolicy.mk ]; then
  echo "ERROR: device/lineage/sepolicy/libperfmgr/sepolicy.mk tidak ada. Cek error 'duplicate path' pada sync di atas."
  exit 1
fi

source build/envsetup.sh

lunch derp_alphaplus-bp4a-userdebug

m installclean
mka derp
