#!/bin/bash
# Build a universal (arm64 + x86_64) libmecab (mecab-ko) and install it into
# /usr/local. Invoked by cibuildwheel as `before-all` (see pyproject.toml).
set -eou pipefail

FLAGS="--enable-utf8-only"
X86_TRIPLET=x86_64-apple-macos10.9
ARM_TRIPLET=arm64-apple-macos11

WORK="$(mktemp -d)"
cd "$WORK"
git clone --depth=1 https://github.com/NoUnique/mecab-ko.git mecab
cd mecab/mecab

rm -rf src/.libs-arm64 src/.libs-x86_64 src/.libs.combined

./configure $FLAGS --host="arm-apple-darwin22.1.0 " CXX="clang++ -target $ARM_TRIPLET" CC="clang"

make clean
# nproc doesnt exist on the runner
make -j$(sysctl -n hw.logicalcpu_max)

mv src/.libs src/.libs-arm64

./configure $FLAGS --host="x86_64-apple-darwin22.1.0 " CXX="clang++ -target $X86_TRIPLET" CC="clang"

make clean
make -j$(sysctl -n hw.logicalcpu_max)

mv src/.libs src/.libs-x86_64

rm -rf src/.libs.combined
mkdir src/.libs.combined

# lipo is an osx utility to create universal binaries
lipo -create src/.libs-arm64/libmecab.2.dylib src/.libs-x86_64/libmecab.2.dylib -output src/.libs.combined/libmecab.2.dylib

lipo -create src/.libs-arm64/libmecab.a src/.libs-x86_64/libmecab.a -output src/.libs.combined/libmecab.a

cp src/.libs-arm64/libmecab.lai src/.libs.combined/libmecab.lai

ls src/.libs-arm64/*.o src/.libs-arm64/mecab* | while read line; do
    echo $line
    lipo -create $line src/.libs-x86_64/$(basename $line) -output src/.libs.combined/$(basename $line)
done

cd src/.libs.combined
ln -s ../libmecab.la libmecab.la
ln -s libmecab.2.dylib libmecab.dylib
cd ../..
mv src/.libs.combined src/.libs

sudo make install
