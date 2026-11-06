set -e

# Move any existing local manifests aside instead of deleting them.
if [ -d .repo/local_manifests ]; then
  mv .repo/local_manifests ".repo/local_manifests.bak.$(date +%s)"
fi

repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs --depth=1
git clone https://github.com/protpr0t/local_manifest_alphaplus -b evox-17 .repo/local_manifests
/opt/crave/resync.sh

export EVO_BUILD_TYPE=Unofficial
. build/envsetup.sh

croot
if [ ! -f vendor/evolution-priv/keys/keys.sh ]; then
  if [ -d vendor/evolution-priv/keys ]; then
    mv vendor/evolution-priv/keys "vendor/evolution-priv/keys.bak.$(date +%s)"
  fi
  croot && git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
  cd vendor/evolution-priv/keys && ./keys.sh
  croot
  if [ ! -s vendor/evolution-priv/keys/keys.mk ]; then
    echo "error: vendor/evolution-priv/keys/keys.mk was not created by keys.sh" >&2
    exit 1
  fi
fi

lunch lineage_alphaplus-cp2a-eng
m installclean
m evolution
