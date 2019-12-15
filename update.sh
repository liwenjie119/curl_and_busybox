#!/bin/bash
git pull
cd zlib
git checkout develop
git pull
cd ../busybox
git checkout master
git pull
cd ../openssl
git checkout master
git pull
cd ../curl
git checkout master
git pull
cd ..

