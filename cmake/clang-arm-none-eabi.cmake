INCLUDE(CMakeForceCompiler)

set(CMAKE_CXX_COMPILER_ID "Clang")

# import army macros
include($ENV{tools_path}/cmake/army.cmake)

# include toolchain tools
include($ENV{toolchain_path}/cmake/cmake-tools.cmake)
include($ENV{toolchain_path}/cmake/toolchain.cmake)
include($ENV{toolchain_path}/cmake/ccache.cmake)

# add processor definition
include_army_package_file($ENV{arch_package} $ENV{arch_path})

# Recommended build flags
set(COMMON_FLAGS "${COMMON_FLAGS} --target=armv6m-none-eabi -march=armv6m")
set(COMMON_FLAGS "${COMMON_FLAGS} -D__ARMCC_VERSION=0 -mcpu=${cpu}")
set(COMMON_FLAGS "${COMMON_FLAGS} -mthumb") # ARM instructions are 32 bits wide, and Thumb instructions are 16 wide. Thumb mode allows for code to be smaller, and can potentially be faster if the target has slow memory.
# set(COMMON_FLAGS "${COMMON_FLAGS} -ffunction-sections")	# generates a separate ELF section for each function in the source file. The unused section elimination feature of the linker can then remove unused functions at link time.
# set(COMMON_FLAGS "${COMMON_FLAGS} -fdata-sections")
set(COMMON_FLAGS "${COMMON_FLAGS} -ffreestanding")	# directs the compiler to not assume that standard functions have their usual definition
set(COMMON_FLAGS "${COMMON_FLAGS} -fcolor-diagnostics")	# activate color output


# optimization flags 
set(COMMON_COMPILER_FLAGS "")

# optimisation flags
set(COMMON_OPTIMISATION_FLAGS "")	# for both linker and compiler
set(COMPILER_OPTIMISATION_FLAGS "")	# for compiler only
set(LINKER_OPTIMISATION_FLAGS "")	# for linker only

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -Og")		# no optimizations 
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -DDEBUG=1")	# turn on debug code
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -g3") 		# add debug informations
 	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -fstack-protector-all -fstack-protector -fstack-protector-strong")  	# add stack protection options

	set(CMAKE_CXX_FLAGS_DEBUG "${COMMON_OPTIMISATION_FLAGS} ${COMPILER_OPTIMISATION_FLAGS}")
	set(CMAKE_C_FLAGS_DEBUG "${COMMON_OPTIMISATION_FLAGS} ${COMPILER_OPTIMISATION_FLAGS}")
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -Os") 		# activate size optimizations
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -DNDEBUG")	# no debug code
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -g3") 		# add debug informations
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -flto") 	# activate link time optimisations 
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -moutline") # activate machine outliner
 	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -Werror=return-type")	# turn this to an error because missing return can cause bad behavior with optimizations

	set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${COMMON_OPTIMISATION_FLAGS} ${COMPILER_OPTIMISATION_FLAGS}")
	set(CMAKE_C_FLAGS_RELWITHDEBINFO "${COMMON_OPTIMISATION_FLAGS} ${COMPILER_OPTIMISATION_FLAGS}")
	
else()
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -Oz") 		# activate aggressive size optimizations
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -DNDEBUG")	# no debug code
 	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -Werror=return-type")	# turn this to an error because missing return can cause bad behavior with optimizations
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -flto") 	# activate link time optimisations
	set(COMMON_OPTIMISATION_FLAGS "${COMMON_OPTIMISATION_FLAGS} -moutline") # activate machine outliner

	set(CMAKE_CXX_FLAGS_RELEASE "${COMMON_OPTIMISATION_FLAGS} ${COMPILER_OPTIMISATION_FLAGS}")
	set(CMAKE_C_FLAGS_RELEASE "${COMMON_OPTIMISATION_FLAGS} ${COMPILER_OPTIMISATION_FLAGS}")
endif()


# C flags
set(C_FLAGS "${COMMON_FLAGS} ${C_FLAGS}")
set(C_FLAGS "${C_FLAGS} -std=c2x")
set(C_FLAGS "${C_FLAGS} -Wall")		# activate all warnings
set(C_FLAGS "${C_FLAGS} -mno-long-calls")	# long call is needed only if the target function lies outside of the 64-megabyte addressing range of the offset-based version of subroutine call instruction.
# stubs for missing includes in clang
set(C_FLAGS "${C_FLAGS} -I ${toolchain_path}/include")

# C++ flags
set(CXX_FLAGS "${COMMON_FLAGS} ${CXX_FLAGS}")
set(CXX_FLAGS "${CXX_FLAGS} -std=c++2a")
set(CXX_FLAGS "${CXX_FLAGS} -Wall")				# activate all warnings
set(CXX_FLAGS "${CXX_FLAGS} -fno-exceptions")	# disable exception mechanism, if an exception is thrown it results on a abort  
set(CXX_FLAGS "${CXX_FLAGS} -mno-long-calls")	# long call is needed only if the target function lies outside of the 64-megabyte addressing range of the offset-based version of subroutine call instruction. 
set(CXX_FLAGS "${CXX_FLAGS} -fno-threadsafe-statics") 	# Do not emit the extra code to use the routines specified in the C++ ABI for thread-safe initialization of local statics
set(CXX_FLAGS "${CXX_FLAGS} -fno-rtti")					# Disable generation of information about every class with virtual functions for use by the C++ run-time type identification features (dynamic_cast and typeid)
set(CXX_FLAGS "${CXX_FLAGS} -fno-implement-inlines")	# To save space, do not emit out-of-line copies of inline functions controlled by #pragma implementation. This causes linker errors if these functions are not inlined everywhere they are called. 
set(CXX_FLAGS "${CXX_FLAGS} -include ${toolchain_path}/include/detect_alloc.h")	# disable memory allocation
#TODO: the c++ stdlib compiled for arm-none-eabi is not in clang
set(CXX_FLAGS "${CXX_FLAGS} -I ${toolchain_path}/gcc/arm-none-eabi/include/c++/10.2.1")
set(CXX_FLAGS "${CXX_FLAGS} -I ${toolchain_path}/gcc/arm-none-eabi/include/c++/10.2.1/arm-none-eabi")
set(CXX_FLAGS "${CXX_FLAGS} -I ${toolchain_path}/gcc/arm-none-eabi/include")
# stubs for missing includes in clang
set(CXX_FLAGS "${CXX_FLAGS} -I ${toolchain_path}/include")

# Assembler flags
set(ASM_FLAGS "${COMMON_FLAGS}")
set(ASM_FLAGS "${ASM_FLAGS} -meabi=5")
set(ASM_FLAGS "${ASM_FLAGS} -Wall")

# ROM options
set(OBJCOPY_HEX_FLAGS "")

# Linker flags
set(LINKER_FLAGS "${LINKER_FLAGS} ${COMMON_FLAGS}")
set(LINKER_FLAGS "${LINKER_FLAGS} ${COMMON_OPTIMISATION_FLAGS} ${LINKER_OPTIMISATION_FLAGS}")
set(LINKER_FLAGS "${LINKER_FLAGS} --target=armv6m-none-eabi")
set(LINKER_FLAGS "${LINKER_FLAGS} -mcpu=${cpu} -march=${cpu}")
# set(LINKER_FLAGS "${LINKER_FLAGS} -gcc-toolchain ${toolchain_path}/gcc")	# indicates to linker where to find gcc
# set(LINKER_FLAGS "${LINKER_FLAGS} -nostdlib")	# do not use the standard system startup files or libraries when linking, produces smaller code but use carefully as it skips global variables init
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--gc-sections")		# garbage collect unused sections
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--check-sections")	# check section addresses for overlaps
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--entry=Reset_Handler")	# code entry point after reset 
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--unresolved-symbols=report-all")
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--warn-common")
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--demangle")
set(LINKER_FLAGS "${LINKER_FLAGS} -lc_nano")
set(LINKER_FLAGS "${LINKER_FLAGS} -lnosys")
set(LINKER_FLAGS "${LINKER_FLAGS} -lgcc")
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--no-dynamic-linker")	# inhibit output of an .interp section
set(LINKER_FLAGS "${LINKER_FLAGS} -Wl,--cref -Xlinker -Map=../bin/firmware.map") # generate map file
# set(LINKER_FLAGS "${LINKER_FLAGS} ${toolchain_path}/gcc/lib/gcc/arm-none-eabi/10.2.1/thumb/v6-m/nofp/crti.o")
set(LINKER_FLAGS "${LINKER_FLAGS} -L ${toolchain_path}/clang/lib")
set(LINKER_FLAGS "${LINKER_FLAGS} -L ${toolchain_path}/gcc/arm-none-eabi/lib/thumb/v6-m/nofp")
set(LINKER_FLAGS "${LINKER_FLAGS} -L ${toolchain_path}/gcc/lib/gcc/arm-none-eabi/10.2.1/thumb/v6-m/nofp")
set(LINKER_FLAGS "${LINKER_FLAGS} -L ${toolchain_path}/gcc/lib")

# remove leading whitespace to avoid error with some linkers
string(REGEX REPLACE "^ " "" LINKER_FLAGS "${LINKER_FLAGS}")

# set build options
set(CMAKE_COMMON_FLAGS "${COMMON_FLAGS}") 
set(CMAKE_ASM_FLAGS "${ASM_FLAGS}")
set(CMAKE_C_FLAGS "${C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CXX_FLAGS}")
