#!/bin/bash

mkdir -p SCONE/deps
pushd SCONE/deps

git clone https://github.com/openssl/openssl.git
pushd openssl
git checkout OpenSSL_1_0_2g
CC=/usr/local/bin/scone-gcc ./config --prefix=$(readlink -f ../local) no-shared
make -j8
make install
popd

git clone https://github.com/madler/zlib.git
pushd zlib
CC=/usr/local/bin/scone-gcc ./configure --prefix=$(readlink -f ../local) --static
make install
popd

git clone https://github.com/curl/curl.git
pushd curl
# This curl version seems to work in combination with Intel's HTTPS proxy ...
git checkout curl-7_47_0
./buildconf
CC=/usr/local/bin/scone-gcc ./configure --prefix=$(readlink -f ../local) --without-libidn --without-librtmp --without-libssh2 --without-libmetalink --without-libpsl --with-ssl=$(readlink -f ../local) --disable-shared
make -j8
make install
popd

git clone https://github.com/protobuf-c/protobuf-c.git
pushd protobuf-c
./autogen.sh
CC=/usr/local/bin/scone-gcc ./configure --prefix=$(readlink -f ../local) --disable-shared
make protobuf-c/libprotobuf-c.la
cp protobuf-c/.libs/libprotobuf-c.a ../local/lib
mkdir ../local/include/protobuf-c
cp protobuf-c/protobuf-c.h ../local/include/protobuf-c
popd

git clone https://github.com/wolfSSL/wolfssl || exit 1
pushd wolfssl
git checkout 57e5648a5dd734d1c219d385705498ad12941dd0
patch -p1 < ../../../wolfssl-sgx-attestation.patch || exit 1
[ ! -f ./configure ] && ./autogen.sh
WOLFSSL_CFLAGS="-DWOLFSSL_SGX_ATTESTATION -DWOLFSSL_ALWAYS_VERIFY_CB -DKEEP_PEER_CERT"
CFLAGS="$WOLFSSL_CFLAGS" CC=/usr/local/bin/scone-gcc ./configure --prefix=$(readlink -f ../local) --enable-writedup --enable-static --disable-shared --enable-keygen --enable-certgen --enable-certext || exit 1 # --enable-debug
make install || exit 1

popd # SCONE/deps
