#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
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
    return buf_pos;
}

DLLEXPORT size_t
packing_pack_array (void** array, size_t array_len, uint8_t* buf, size_t buf_len, int8_t* vec) {
    size_t buf_pos = 0;
    size_t n;
    for (n = 0; n < array_len && buf_pos < buf_len; n++) {
        size_t avail_len = buf_len - buf_pos;
        if (array[n] != NULL) {
            buf_pos += packing_pack(array[n], buf + buf_pos, avail_len, vec);
        }
    }
    return n;
}

DLLEXPORT size_t
packing_unpack_array (void** array, size_t array_len, uint8_t* buf, size_t buf_len, int8_t*vec) {
    size_t buf_pos = 0;
    size_t n;
    for (n = 0; n < array_len && buf_pos < buf_len; n++) {
        size_t avail_len = buf_len - buf_pos;
        if (array[n] != NULL) {
            buf_pos += packing_unpack(array[n], buf + buf_pos, avail_len, vec);
        }
    }
    return n;
}

DLLEXPORT size_t
packing_mempack (uint8_t* dest, uint8_t* src, size_t n, uint8_t of_size) {
    size_t offset = 0;
    size_t i;
    uint8_t j;

    assert(word_size > 0);

    for (i = 0; i < n; i++) {
        // endian inversion on each element
        size_t end = offset + of_size - 1;
        for (j = 0; j < of_size; j++) {
            dest[offset++] = src[end - j];
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

// This should be the same as nativesizeof on the struct
DLLEXPORT size_t
packing_struct_size (int8_t* vec, int8_t align) {
    int struct_size = 0;

    for (;;) {
        uint8_t pad = *(vec++);
        uint8_t size = *vec > 0 ? *vec : -*vec;
        struct_size += pad + size;
        if (size == 0) break;
        ++vec;
    }
    while (align && struct_size % align) {
        struct_size++;
    }
    return struct_size;
}
