rm -rf .repo/local_manifests/
rm -rf device/lge
rm -rf kernel/lge
rm -rf vendor/lge
rm -rf hardware/lge
rm -rf out/target/product/alphaplus

# Cleanup previous changelog
rm -rf out/target/product/*/system/etc/Changelog.txt \
       out/target/product/*/obj/ETC/Changelog.txt_intermediates \
       out/target/product/*/gen/ETC/Changelog.txt_intermediates

# Initialize crDroid 15.0
repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --depth=1 --git-lfs --no-clone-bundle

# Download local manifest directly using curl
mkdir -p .repo/local_manifests
curl -sL https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/alphaplus-crdroid15/local_manifest.xml -o .repo/local_manifests/alphaplus.xml

# Crave resync and start build
/opt/crave/resync.sh

source build/envsetup.sh

brunch alphaplus
