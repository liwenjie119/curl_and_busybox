#!/bin/bash
cp .config busybox/.config
gcc_version=7.5.0-2019.12
gcc_versionflie=7.5-2019.12
# Set up gcc
file=gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu
if [ -d "$file" ]; then
    echo $file exist
else
	file=gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu.tar.xz
	if [ -f "$file" ]; then
	    echo $file exit,tar -xvJf
		[ -d "gcc-linaro" ] || tar -xvJf gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu.tar.xz
	else
		echo "no such file,will download"	
		echo "Fetching gcc"
		[ -f "gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu.tar.xz" ] || wget  http://releases.linaro.org/components/toolchain/binaries/$gcc_versionflie/aarch64-linux-gnu/gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu.tar.xz
		[ -d "gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu" ] || tar -xvJf gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu.tar.xz
	fi
fi

export CROSS_COMPILE=$PWD/gcc-linaro-$gcc_version-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
cd busybox
git checkout master
git pull
make oldconfig
make -j8 ARCH=arm64  &&make -j8 ARCH=arm64  install
cd ..
