#ifndef __PACKING_H
#define __PACKING_H

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

DLLEXPORT size_t packing_pack (uint8_t*, uint8_t*, size_t, int8_t*);
DLLEXPORT size_t packing_unpack (uint8_t*, uint8_t*, size_t, int8_t*);

DLLEXPORT size_t packing_pack_array (void**, size_t, uint8_t*, size_t, int8_t*);
DLLEXPORT size_t packing_unpack_array (void**, size_t, uint8_t*, size_t, int8_t*);

DLLEXPORT size_t packing_mempack (uint8_t*, uint8_t*, size_t, uint8_t);

DLLEXPORT size_t packing_packed_size (int8_t*);
DLLEXPORT size_t packing_struct_size (int8_t*, int8_t);

#endif /* __PACKING_H */
