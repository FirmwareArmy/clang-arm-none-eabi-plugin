find_program(CCACHE_FOUND ccache)
message("ccache: ${CCACHE_FOUND}")
if(CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)

	set(CCACHE_SKIP "--ccache-skip")	# for options ccache doesn't recognize and should ignore
endif(CCACHE_FOUND)

set(COMMON_FLAGS "${COMMON_FLAGS} ${CCACHE_SKIP} -save-temps")
