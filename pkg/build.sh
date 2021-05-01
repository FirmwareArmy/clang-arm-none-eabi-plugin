#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

cd ${xpl_path}/..

compiler_rt_path=${xpl_path}/../compiler-rt

# created from https://interrupt.memfault.com/blog/arm-cortexm-with-llvm-clang

export ARM_SYSROOT=$(readlink -f $(gcc/bin/arm-none-eabi-gcc -print-sysroot))
export LLVM_BIN_PATH=$(readlink -f clang/bin)

# Only Soft Float ABI seems to work
export NONE_EABI_TARGET_FLAGS="-mthumb -mfloat-abi=soft -mfpu=none"

echo $ARM_SYSROOT
echo $LLVM_BIN_PATH

# This needs to be a complete ARM target triple to pick up
# architecture specific optimizations
#   Cortex M0, M0+: armv6m-none-eabi
#   Cortex M3: armv7m-none-eabi
#   Cortex M4, M7: armv7em-none-eabi
#   Cortex M33: armv8m-none-eabi
for NONE_EABI_TARGET in 'armv6m-none-eabi' 'armv7m-none-eabi' 'armv7em-none-eabi' #'armv8m-none-eabi'
do
	echo
	echo "==== $NONE_EABI_TARGET ===="
	echo
	
	cd ${compiler_rt_path}
	rm -rf build
	mkdir build
	cd build

	cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
	-DCOMPILER_RT_OS_DIR="baremetal" \
	-DCOMPILER_RT_BUILD_BUILTINS=ON \
	-DCOMPILER_RT_BUILD_SANITIZERS=OFF \
	-DCOMPILER_RT_BUILD_XRAY=OFF \
	-DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
	-DCOMPILER_RT_BUILD_PROFILE=OFF \
	-DCMAKE_C_COMPILER=${LLVM_BIN_PATH}/clang \
	-DCMAKE_C_COMPILER_TARGET=${NONE_EABI_TARGET} \
	-DCMAKE_ASM_COMPILER_TARGET=${NONE_EABI_TARGET} \
	-DCMAKE_AR=${LLVM_BIN_PATH}/llvm-ar \
	-DCMAKE_NM=${LLVM_BIN_PATH}/llvm-nm \
	-DCMAKE_LINKER=${LLVM_BIN_PATH}/ld.lld \
	-DCMAKE_RANLIB=${LLVM_BIN_PATH}/llvm-ranlib \
	-DCOMPILER_RT_BAREMETAL_BUILD=ON \
	-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
	-DLLVM_CONFIG_PATH=${LLVM_BIN_PATH}/llvm-config \
	-DCMAKE_C_FLAGS= ${NONE_EABI_TARGET_FLAGS} \
	-DCMAKE_ASM_FLAGS=${NONE_EABI_TARGET_FLAGS} \
	-DCOMPILER_RT_INCLUDE_TESTS=OFF \
	-DCMAKE_SYSROOT=${ARM_SYSROOT} ..
	
	make clean
	make -j8
	
	cp -f ${compiler_rt_path}/build/lib/baremetal/*.a ${xpl_path}/../clang/lib/
done
