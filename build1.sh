#!/bin/bash
echored () {
	echo "${TEXTRED}$1${TEXTRESET}"
}
echogreen () {
	echo "${TEXTGREEN}$1${TEXTRESET}"
}
usage () {
  echo " "
  echored "USAGE:"
  echogreen "ARCH=     (Default: all) (Valid Arch values: all, arm, arm64, aarch64, x86, i686, x64, x86_64)"
  echogreen "           Note that you can put as many of these as you want together as long as they're comma separated"
  echogreen "           Ex: ARCH=arm,x86"
  echo " "
  exit 1
}
OIFS=$IFS; IFS=\|; 
while true; do
  case "$1" in
    -h|--help) usage;;
    "") shift; break;;
    ARCH=*) eval $(echo "$1" | sed -e 's/=/="/' -e 's/$/"/' -e 's/,/ /g'); shift;;
    *) echo "Invalid option: $1!"; usage;;
  esac
done
IFS=$OIFS

TEXTRESET=$(tput sgr0)
TEXTGREEN=$(tput setaf 2)
TEXTRED=$(tput setaf 1)



# Get latest certs
[ -f "cacert.pm" ] || curl --remote-name --time-cond cacert.pem https://curl.haxx.se/ca/cacert.pem
cp cacert.pem curl/cacert.pem
NDK=r21
export ANDROID_NDK_HOME=`pwd`/android-ndk-$NDK
export ANDROID_NDK_ROOT=`pwd`/android-ndk-$NDK
export HOST_TAG=linux-x86_64
export MIN_SDK_VERSION=29
mkdir -p build/zlib
mkdir -p build/openssl
mkdir -p build/curl

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
export ANDROID_TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin
PATH=$ANDROID_TOOLCHAIN:$PATH
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

[ -z "$ARCH" -o "$ARCH" == "all" ] && ARCH="arm arm64 x86 x64"

for LARCH in $ARCH; do
  case $LARCH in
    arm64|aarch64) LARCH=aarch64; ARCHOS=android-arm64;;
    arm) LARCH=arm; ARCHOS=android-arm;;
    x64|x86_64) LARCH=x86_64; ARCHOS=android-x86_64;;
    x86) LARCH=i686; ARCHOS=android-x86;;
      *) echo "Invalid ARCH entered!"; usage;;
  esac

  export AR=$ANDROID_TOOLCHAIN/$LARCH-linux-android-ar
  export AS=$ANDROID_TOOLCHAIN/$LARCH-linux-android-as
  export LD=$ANDROID_TOOLCHAIN/$LARCH-linux-android-ld
  export CC=$ANDROID_TOOLCHAIN/$LARCH-linux-android$MIN_SDK_VERSION-clang
  export CXX=$ANDROID_TOOLCHAIN/$LARCH-linux-android$MIN_SDK_VERSION-clang++
  export RANLIB=$ANDROID_TOOLCHAIN/$LARCH-linux-android-ranlib
  export STRIP=$ANDROID_TOOLCHAIN/$LARCH-linux-android-strip

  # make symlink of clang to gcc
  if [ "$LARCH" == "arm" ]; then
    export AR=$ANDROID_TOOLCHAIN/$LARCH-linux-androideabi-ar
    export AS=$ANDROID_TOOLCHAIN/$LARCH-linux-androideabi-as
    export LD=$ANDROID_TOOLCHAIN/$LARCH-linux-androideabi-ld
    export CC=$ANDROID_TOOLCHAIN/$LARCH-linux-android$MIN_SDK_VERSIONeabi-clang
    export CXX=$ANDROID_TOOLCHAIN/$LARCH-linux-android$MIN_SDK_VERSIONeabi-clang++
    export RANLIB=$ANDROID_TOOLCHAIN/$LARCH-linux-androideabi-ranlib
    export STRIP=$ANDROID_TOOLCHAIN/$LARCH-linux-androideabi-strip
    export CC=$ANDROID_TOOLCHAIN/armv7a-linux-androideabi$MIN_SDK_VERSION-clang
    export CXX=$ANDROID_TOOLCHAIN/armv7a-linux-androideabi$MIN_SDK_VERSION-clang++
    ln -sf $CC `echo $CC | sed -e "s|armv7a|arm|" -e "s|$MIN_SDK_VERSION-clang|-gcc|"`
    ln -sf $CXX `echo $CXX | sed -e "s|armv7a|arm|" -e "s|$MIN_SDK_VERSION-clang|-gcc|"`
  else
    ln -sf $CC `echo $CC | sed "s|$MIN_SDK_VERSION-clang|-gcc|"`
    ln -sf $CXX `echo $CXX | sed "s|$MIN_SDK_VERSION-clang|-gcc|"`
  fi


  echogreen "Building Zlib..."
  cd zlib
  ./configure --static --archs="-arch $LARCH" --prefix=$PWD/build/$LARCH
  make -j$JOBS
  make install
  make clean
  [ $? -eq 0 ] || continue
  mkdir -p ../build/zlib/$LARCH
  cp -R $PWD/build/$LARCH ../build/zlib/
  cd ..

  echogreen "Building Openssl..."
  cd openssl
  export ZLIB_DIR=$PWD/../zlib/build/$LARCH
  ./Configure --prefix=$PWD/build/$LARCH $ARCHOS enable-md2 enable-rc5 enable-tls enable-tls1_3 enable-tls1_2 enable-tls1_1 no-shared zlib  -D__ANDROID_API__=$MIN_SDK_VERSION  --with-zlib-include=$ZLIB_DIR/include --with-zlib-lib=$ZLIB_DIR/lib
  make depend && make -j$JOBS
  make install_sw
  make clean
  [ $? -eq 0 ] || continue
  mkdir -p ../build/openssl/$LARCH
  cp -R $PWD/build/$LARCH ../build/openssl/
  cd ..

  echogreen "Building CURL..."
  cd curl
  export SSL_DIR=$PWD/../openssl/build/$LARCH
  ./buildconf
  ./configure --enable-static --disable-shared --enable-cross-compile  --with-zlib=$ZLIB_DIR/usr --host=$LARCH-linux-android --target=$LARCH-linux-android --prefix=$PWD/build/$LARCH --with-ssl=$SSL_DIR --with-ca-bundle=cacert.pem --disable-ldap --disable-ldaps --enable-ipv6 --enable-versioned-symbols --enable-threaded-resolver
  make curl_LDFLAGS=-all-static -j$JOBS
  make install
  make clean
  [ $? -eq 0 ] || continue
  mkdir -p ../build/curl/$LARCH
  cp -R $PWD/build/$LARCH ../build/curl/
  cd ..
  echogreen "curl-$LARCH built successfully!"
done

echogreen "Building complete!"
exit 0