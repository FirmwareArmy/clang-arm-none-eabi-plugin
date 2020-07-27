INCLUDE(CMakeForceCompiler)

if(NOT DEFINED ENV{toolchain_path})
	message(FATAL_ERROR "'toolchain_path' not defined")
endif()

if(NOT DEFINED ENV{project_path})
	message(FATAL_ERROR "'project_path' not defined")
endif()

if(NOT DEFINED ENV{arm_clang_path})
	message(FATAL_ERROR "arm_clang_path not defined")
endif()

if(NOT DEFINED ENV{arch_path})
	message(FATAL_ERROR "arch_path not defined")
endif()

set(PROJECT_PATH "$ENV{project_path}")
set(TOOLCHAIN_PATH "$ENV{toolchain_path}")
set(ARCH_PATH "$ENV{arch_path}")

set(ARM_CLANG_PATH "${TOOLCHAIN_PATH}/$ENV{arm_clang_path}")

set(COMMON_FLAGS "")
set(C_FLAGS "")
set(CXX_FLAGS "")
set(LINKER_FLAGS "")

# CPU type
include(${ARCH_PATH})

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_CROSSCOMPILING 1)
set(CMAKE_SYSTEM_PROCESSOR arm)

find_program(CCACHE_FOUND ccache)
message("ccache: ${CCACHE_FOUND}")
if(CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)

	set(CCACHE_SKIP "--ccache-skip")	# for options ccache doesn't recognize and should ignore
endif(CCACHE_FOUND)

# specify the cross compiler
# path to the ARM cross compilers, 
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_ASM_COMPILER "${ARM_CLANG_PATH}/bin/llvm-as")
set(CMAKE_C_COMPILER "${ARM_CLANG_PATH}/bin/clang")
set(CMAKE_CXX_COMPILER "${ARM_CLANG_PATH}/bin/clang++")
set(CMAKE_CXX_LINK_EXECUTABLE "${ARM_CLANG_PATH}/bin/clang -fuse-ld=lld <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
# allow activate SSP
set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> rcs -o <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> rcs -o <TARGET> <LINK_FLAGS> <OBJECTS>")

# Recommended build flags
set(COMMON_FLAGS "${COMMON_FLAGS} -D__ARMCC_VERSION=0 --target=armv6m-none-eabi -mcpu=${CPU}")
set(COMMON_FLAGS "${COMMON_FLAGS} -mthumb") # ARM instructions are 32 bits wide, and Thumb instructions are 16 wide. Thumb mode allows for code to be smaller, and can potentially be faster if the target has slow memory.
#set(COMMON_FLAGS "${COMMON_FLAGS} -D${CHIP}")# TODO
set(COMMON_FLAGS "${COMMON_FLAGS} -ffunction-sections")	# generates a separate ELF section for each function in the source file. The unused section elimination feature of the linker can then remove unused functions at link time.
set(COMMON_FLAGS "${COMMON_FLAGS} -fdata-sections")
set(COMMON_FLAGS "${COMMON_FLAGS} --param max-inline-insns-single=500")
set(COMMON_FLAGS "${COMMON_FLAGS} -ffreestanding")	# directs the compiler to not assume that standard functions have their usual definition
set(COMMON_FLAGS "${COMMON_FLAGS} ${CCACHE_SKIP} -save-temps")


if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	# override debug options
	set(CMAKE_CXX_FLAGS_DEBUG "-DDEBUG=1 -g3")
	set(CMAKE_C_FLAGS_DEBUG "-DDEBUG=1 -g3")
 	# add stack protection options
 	set(COMMON_FLAGS "${COMMON_FLAGS} -fstack-protector-all -fstack-protector -fstack-protector-strong")
	set(LINKER_OPTIMISATION_FLAGS "")
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
	set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-Os -DNDEBUG -g3")
	set(CMAKE_C_FLAGS_RELWITHDEBINFO "-Os -DNDEBUG -g3")
	set(LINKER_OPTIMISATION_FLAGS "-Os -DNDEBUG -g3")

	# activate link time optimisations  -flto -fwhole-program -Os
	set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -flto -fuse-linker-plugin")
	set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -flto -fuse-linker-plugin")
	set(LINKER_OPTIMISATION_FLAGS "${LINKER_OPTIMISATION_FLAGS} -flto -fuse-linker-plugin")

 	set(COMMON_FLAGS "${COMMON_FLAGS} -Werror=return-type")	# turn this to an error because missing return can cause bad behavior with optimizations
else()
	set(CMAKE_CXX_FLAGS_RELEASE "-Os -DNDEBUG")
	set(CMAKE_C_FLAGS_RELEASE "-Os -DNDEBUG")
	set(LINKER_OPTIMISATION_FLAGS "")

	# activate link time optimisations  -flto -fwhole-program -Os
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -flto -fuse-linker-plugin")
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -flto -fuse-linker-plugin")
	set(LINKER_OPTIMISATION_FLAGS "${LINKER_OPTIMISATION_FLAGS} -flto -fuse-linker-plugin")

 	set(COMMON_FLAGS "${COMMON_FLAGS} -Werror=return-type")	# turn this to an error because missing return can cause bad behavior with optimizations
endif()


# C flags
set(C_FLAGS "${COMMON_FLAGS} ${C_FLAGS}")
set(C_FLAGS "${C_FLAGS} -std=c11")
set(C_FLAGS "${C_FLAGS} -Wall")		# activate all warnings
set(C_FLAGS "${C_FLAGS} -mno-long-calls")	# long call is needed only if the target function lies outside of the 64-megabyte addressing range of the offset-based version of subroutine call instruction.

# C++ flags
set(CXX_FLAGS "${COMMON_FLAGS} ${CXX_FLAGS}")
set(CXX_FLAGS "${CXX_FLAGS} -std=c++2a")
set(CXX_FLAGS "${CXX_FLAGS} -Wall")				# activate all warnings
set(CXX_FLAGS "${CXX_FLAGS} -fno-exceptions")	# disable exception mechanism, if an exception is thrown it results on a abort  
set(CXX_FLAGS "${CXX_FLAGS} -mno-long-calls")	# long call is needed only if the target function lies outside of the 64-megabyte addressing range of the offset-based version of subroutine call instruction. 
set(CXX_FLAGS "${CXX_FLAGS} -fno-threadsafe-statics") 	# Do not emit the extra code to use the routines specified in the C++ ABI for thread-safe initialization of local statics
set(CXX_FLAGS "${CXX_FLAGS} -fno-rtti")					# Disable generation of information about every class with virtual functions for use by the C++ run-time type identification features (dynamic_cast and typeid)
set(CXX_FLAGS "${CXX_FLAGS} -fno-implement-inlines")	# To save space, do not emit out-of-line copies of inline functions controlled by #pragma implementation. This causes linker errors if these functions are not inlined everywhere they are called. 
set(CXX_FLAGS "${CXX_FLAGS} -include ${TOOLCHAIN_PATH}/include/detect_alloc.h")	# disable memory allocation
set(CXX_FLAGS "${CXX_FLAGS} -I /home/seb/git/gcc-arm-none-eabi-plugin/gcc/arm-none-eabi/include/c++/9.3.1")
set(CXX_FLAGS "${CXX_FLAGS} -I /home/seb/git/gcc-arm-none-eabi-plugin/gcc/arm-none-eabi/include/c++/9.3.1/arm-none-eabi")
set(CXX_FLAGS "${CXX_FLAGS} -I /home/seb/git/gcc-arm-none-eabi-plugin/gcc/arm-none-eabi/include")
set(CXX_FLAGS "${CXX_FLAGS} -I ${TOOLCHAIN_PATH}/include")

# Assembler flags
set(ASM_FLAGS "${COMMON_FLAGS}")
set(ASM_FLAGS "${ASM_FLAGS} -meabi=5")
set(ASM_FLAGS "${ASM_FLAGS} -Wall")

# ROM options
set(OBJCOPY_HEX_FLAGS "")

# Linker flags
set(LINKER_FLAGS "${COMMON_FLAGS} ${LINKER_FLAGS}")
set(LINKER_FLAGS "${LINKER_FLAGS} ${LINKER_OPTIMISATION_FLAGS}")
#set(LINKER_FLAGS "${LINKER_FLAGS} -nostdlib")	# do not use the standard system startup files or libraries when linking, produces smaller code but use carefully as it skips global variables init
# set(LINKER_FLAGS "${LINKER_FLAGS} -specs=nano.specs -specs=nosys.specs")	# use newlib to decrease code size
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--gc-sections")		# garbage collect unused sections
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--check-sections")	# check section addresses for overlaps
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--entry=Reset_Handler")	# code entry point after reset 
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--unresolved-symbols=report-all")
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--warn-common")
# set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--warn-section-align")
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--start-group")
#set(LINKER_FLAGS "${LINKER_FLAGS} -u _sbrk -u link -u _close -u _fstat -u _isatty -u _lseek -u _read -u _write -u _exit -u kill -u _getpid")
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--end-group")
# set(LINKER_FLAGS "${LINKER_FLAGS} -lm -lclang")
# set(LINKER_FLAGS "${LINKER_FLAGS} -lc")
# set(LINKER_FLAGS "${LINKER_FLAGS} -lnosys")
# set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--print-memory-usage")	# print generated firmware size
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--cref -Xlinker -Map=../bin/firmware.map") # generate map file
set(LINKER_FLAGS "${LINKER_FLAGS} -L /home/seb/git/gcc-arm-none-eabi-plugin/gcc/arm-none-eabi/lib/thumb/v6-m/nofp")

# remove leading whitespace to avoid error
string(REGEX REPLACE "^ " "" LINKER_FLAGS "${LINKER_FLAGS}")
