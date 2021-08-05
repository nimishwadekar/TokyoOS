#pragma once
#include <stdint.h>

#define FS_INVALID 0
#define FS_VALID 1
#define FS_FILE (1 << 1)
#define FS_DIRECTORY (1 << 2)
#define FS_WRITE (1 << 3)
#define FS_APPEND (1 << 4)

// Including null terminator.
#define FILENAME_MAX_NULL 255
//#define DIRECTORY_MAX_NEST (FILENAME_MAX_NULL >> 1)

struct FILE
{
    char Name[FILENAME_MAX_NULL + 1];
    uint32_t Flags;
    uint8_t Device; // Volume, 'A' to 'Z'.
    uint64_t Length;
    uint64_t CurrentBlock;
    uint64_t Position; // Offset in current block.
};