#!/bin/bash
git pull
cd zlib
git checkout develop
git pull
git checkout .
cd ../busybox
git checkout master
git pull
git checkout .
cd ../openssl
git checkout master
git pull
git checkout .
cd ../curl
git checkout master
git pull
git checkout .
cd ..

