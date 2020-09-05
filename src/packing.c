#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
/* Get prototype. */
#include "packing.h"

DLLEXPORT size_t
packing_pack (uint8_t* cstruct, uint8_t* buf, size_t buf_len, int8_t* vec) {
    size_t offset = 0;
    size_t buf_pos = 0;
    int i;

    for (;;) {
        uint8_t pad = *(vec++);
        int8_t sign = *vec < 0 ? -1 : 1;
        int8_t size = *(vec++) * sign;

        // alignment padding
        offset += pad;

        if (size == 0 || (buf_pos + size > buf_len)) {
            break;
        }
        else if (sign > 0) {
            // direct copy
            for (i = 0; i < size; i++) {
                buf[buf_pos++] = *(cstruct + offset++);
            }
        }
        else {
            // endian inversion
            offset += size;
            for (i = 1; i <= size; i++) {
                buf[buf_pos++] = *(cstruct + offset - i);
            }
        }
    }
    return buf_pos;
}

DLLEXPORT size_t
packing_unpack (uint8_t* cstruct, uint8_t* buf, size_t buf_len, int8_t* vec) {
    size_t offset = 0;
    size_t buf_pos = 0;
    int i;

    for (;;) {
        uint8_t pad = *(vec++);
        int8_t sign = *vec < 0 ? -1 : 1;
        int8_t size = *(vec++) * sign;

        offset += pad;

        if (size == 0 || (buf_pos + size > buf_len)) {
            break;
        }
        else if (sign > 0) {
            // direct copy
            for (i = 0; i < size; i++) {
                cstruct[offset++] = buf[buf_pos++];
            }   
        }
        else {
            // endian inversion
            offset += size;
            for (i = 1; i <= size; i++) {
                cstruct[offset - i] = buf[buf_pos++];
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
