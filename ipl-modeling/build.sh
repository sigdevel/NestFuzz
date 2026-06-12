#!/bin/bash

BIN_PATH=$(readlink -f "$0")
ROOT_DIR=$(dirname $BIN_PATH)

set -euxo pipefail

if [ -z "${LLVM_CONFIG+x}" ]; then
    for candidate in llvm-config-10 llvm-config-18 llvm-config-19 llvm-config-21 llvm-config; do
        if [ -x "$(command -v ${candidate})" ]; then
            LLVM_CONFIG="$(command -v ${candidate})"
            break
        fi
    done
fi

if [ -z "${LLVM_CONFIG+x}" ] || [ ! -x "${LLVM_CONFIG}" ]; then
    exit 1
fi

echo "Find ${LLVM_CONFIG}"
LLVM_PREFIX="$(${LLVM_CONFIG} --prefix)"

PREFIX=${PREFIX:-${ROOT_DIR}/install/}

[ -z ${DEBUG+x} ]&&DEBUG=0

if [ $DEBUG -eq 0 ]; then
    cargo build --release
else
    cargo build
fi

rm -rf ${PREFIX}
mkdir -p ${PREFIX}
mkdir -p ${PREFIX}/lib

if [ $DEBUG -eq 0 ]; then
    cp target/release/*.so ${PREFIX}/lib
    # cp target/release/*.a ${PREFIX}/lib
else
    cp target/debug/*.so ${PREFIX}/lib
    # cp target/debug/*.a ${PREFIX}/lib
fi

rm -rf build
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_BUILD_TYPE=Release -DLT_LLVM_INSTALL_DIR=${LLVM_PREFIX} ..
make # VERBOSE=1 
make install # VERBOSE=1
