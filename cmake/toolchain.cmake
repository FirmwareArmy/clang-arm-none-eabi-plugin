if(NOT DEFINED ENV{toolchain_path})
	message(FATAL_ERROR "'toolchain_path' not defined")
endif()
set(toolchain_path $ENV{toolchain_path} CACHE PATH "Toolchain path")


if(NOT DEFINED ENV{project_path})
	message(FATAL_ERROR "'project_path' not defined")
endif()
set(project_path $ENV{project_path} CACHE PATH "Project path")

# if(NOT DEFINED arm_gcc_path)
# 	message(FATAL_ERROR "arm_gcc_path not defined")
# endif()
# 
# if(NOT DEFINED arm_gcc_eabi)
# 	message(FATAL_ERROR "arm_gcc_eabi not defined")
# endif()
# 
# if(NOT DEFINED arch_path)
# 	message(FATAL_ERROR "arch_path not defined")
# endif()

if(NOT DEFINED ENV{c_path})
	message(FATAL_ERROR "c_path not defined")
endif()
set(c_path $ENV{c_path} CACHE PATH "C compiler path")

if(NOT DEFINED ENV{cxx_path})
	message(FATAL_ERROR "cxx_path not defined")
endif()
set(cxx_path $ENV{cxx_path} CACHE PATH "C++ compiler path")

if(NOT DEFINED ENV{asm_path})
	message(FATAL_ERROR "asm_path not defined")
endif()
set(asm_path $ENV{asm_path} CACHE PATH "ASM compiler path")

if(NOT DEFINED ENV{ar_path})
	message(FATAL_ERROR "ar_path not defined")
endif()
set(ar_path $ENV{ar_path} CACHE PATH "Archive compiler path")

if(NOT DEFINED ENV{ld_path})
	message(FATAL_ERROR "ld_path not defined")
endif()
set(ld_path $ENV{ld_path} CACHE PATH "Linker path")

if(NOT DEFINED ENV{cpu})
	message(FATAL_ERROR "cpu not defined")
endif()
set(cpu $ENV{cpu} CACHE PATH "CPU")

# ignore unused variable warning
set(ignoreMe "${CMAKE_TOOLCHAIN_FILE}")

set(COMMON_FLAGS "")
set(C_FLAGS "")
set(CXX_FLAGS "")
set(LINKER_FLAGS "")

# enable cmake cross compiling
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_CROSSCOMPILING 1)
set(CMAKE_SYSTEM_PROCESSOR arm)

# force cmake to link static libraries for test to avoid linker errors
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# set compiler path
set(CMAKE_C_COMPILER ${c_path})
set(CMAKE_CXX_COMPILER ${cxx_path})
set(CMAKE_ASM_COMPILER ${asm_path})
set(CMAKE_AR ${ar_path} CACHE FILEPATH "" FORCE)	# needs to be cached (bug?) 
set(CMAKE_LINKER ${ld_path} CACHE FILEPATH "" FORCE)	# needs to be cached (bug?) 
# set linker
set(CMAKE_CXX_LINK_EXECUTABLE "$ENV{ld_path} <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
# allow activate SSP
set(CMAKE_CXX_ARCHIVE_CREATE "$ENV{ar_path} rcs -o <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_C_ARCHIVE_CREATE "$ENV{ar_path} rcs -o <TARGET> <LINK_FLAGS> <OBJECTS>")

