#pragma once

//#include <stdexcept>
//
//inline void * operator new (std::size_t) throw(std::bad_alloc) {
//    extern void *bare_new_erroneously_called();
//    return bare_new_erroneously_called();
//}

// forbid memory allocation keywords
#pragma GCC poison new delete
#pragma GCC poison malloc free
