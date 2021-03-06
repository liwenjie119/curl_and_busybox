#!/bin/bash

# Get latest certs
[ -f "cacert.pm" ] || curl --remote-name --time-cond cacert.pem https://curl.haxx.se/ca/cacert.pem
cp cacert.pem curl/cacert.pem
NDK=r21b
export ANDROID_NDK_HOME=`pwd`/android-ndk-$NDK
export ANDROID_NDK_ROOT=`pwd`/android-ndk-$NDK
export HOST_TAG=linux-x86_64
export MIN_SDK_VERSION=29

# Set up Android NDK
file=android-ndk-$NDK
if [ -d "$file" ]; then
    echo $file exist
else
	file=android-ndk-$NDK-$HOST_TAG.zip
	if [ -f "$file" ]; then
	    echo $file exit,unzip
		[ -d "android-ndk-$NDK" ] || unzip -qo android-ndk-$NDK-$HOST_TAG.zip
	else
		echo "no such zip,will download"	
		echo "Fetching Android NDK $NDK"
		[ -f "android-ndk-$NDK-$HOST_TAG.zip" ] || wget  https://dl.google.com/android/repository/android-ndk-$NDK-$HOST_TAG.zip
		[ -d "android-ndk-$NDK" ] || unzip -qo android-ndk-$NDK-$HOST_TAG.zip
	fi
fi


if [ -f /proc/cpuinfo ]; then
  export JOBS=$(grep flags /proc/cpuinfo | wc -l)
elif [ ! -z $(which sysctl) ]; then
  export JOBS=$(sysctl -n hw.ncpu)
else
  export JOBS=2
fi

export CFLAGS="-Os -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables"
export LDFLAGS="-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"

chmod +x build-zlib.sh build-openssl.sh build-curl.sh build-busybox.sh

#./build-busybox.sh
./build-zlib.sh
./build-openssl.sh
./build-curl.sh
