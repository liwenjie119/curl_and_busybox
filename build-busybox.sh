#!/bin/bash
cp .config busybox/.config
gcc_version=gcc-linaro-7.5.0-2019.12

# Set up gcc
file=$gcc_version-x86_64_aarch64-linux-gnu
if [ -d "$file" ]; then
    echo $file exist
else
	file=$gcc_version-x86_64_aarch64-linux-gnu.tar.xz
	if [ -f "$file" ]; then
	    echo $file exit,tar -xvJf
		[ -d "gcc-linaro" ] || tar -xvJf $gcc_version-x86_64_aarch64-linux-gnu.tar.xz
	else
		echo "no such file,will download"	
		echo "Fetching gcc"
		[ -f "$gcc_version-x86_64_aarch64-linux-gnu.tar.xz" ] || wget  http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/$gcc_version-x86_64_aarch64-linux-gnu.tar.xz
		[ -d "$gcc_version-x86_64_aarch64-linux-gnu" ] || tar -xvJf $gcc_version-x86_64_aarch64-linux-gnu.tar.xz
	fi
fi

export CROSS_COMPILE=$PWD/$gcc_version-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
cd busybox
git checkout master
git pull
make -j8 ARCH=arm64  &&make -j8 ARCH=arm64  install
cd ..
