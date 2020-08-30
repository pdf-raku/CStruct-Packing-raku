#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
/* Get prototype. */
#include "packing.h"

DLLEXPORT size_t
packing_pack (uint8_t* cstruct, uint8_t* buf, int8_t* vec) {
    size_t offset = 0;
    int i;
    uint8_t* start = buf;

    for (;;) {
        uint8_t pad = *(vec++);
        int8_t size = *(vec++);

        // alignment padding
        offset += pad;

        if (size == 0) {
            break;
        }
        else if (size > 0) {
            // direct copy
            for (i = 0; i < size; i++) {
                *(buf++) = *(cstruct + offset++);
            }
        }
        else {
            // endian inversion
            size = -size;
            offset += size;
            for (i = 1; i <= size; i++) {
                *(buf++) = *(cstruct + offset - i);
            }
        }
    }
    return buf - start;
}

DLLEXPORT size_t
packing_unpack (uint8_t* cstruct, uint8_t* buf, int8_t* vec) {
    size_t offset = 0;
    int i;

    for (;;) {
        uint8_t pad = *(vec++);
        int8_t size = *(vec++);

        offset += pad;

        if (size == 0) {
            break;
        }
        else if (size > 0) {
            // direct copy
            for (i = 0; i < size; i++) {
                *(cstruct + offset++) = *(buf++);
            }   
        }
        else {
            // endian inversion
            size = -size;
            offset += size;
            for (i = 1; i <= size; i++) {
                *(cstruct + offset - i) = *(buf++);
            }
        }
    }
    return offset;
}

DLLEXPORT size_t
packing_packed_size (int8_t* vec) {
    size_t packed_size = 0;
    uint8_t size;
    for (;;) {
        vec++; // skip padding
        size = *vec > 0 ? *vec : -*vec;
        if (size == 0) break;
        packed_size += size;
        vec++;
    }
    return packed_size;
}

// Sanity check. This should be the same as nativesizeof on the struct
DLLEXPORT size_t
packing_struct_size (int8_t* vec) {
    int unpacked_size = 0;

    for (;;) {
        uint8_t pad = *(vec++);
        uint8_t size = *vec > 0 ? *vec : -*vec;
        unpacked_size += pad + size;
        if (size == 0) break;
        ++vec;
    }
    return unpacked_size;
}
