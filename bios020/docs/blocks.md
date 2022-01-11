<div>
    <image src="https://raw.githubusercontent.com/74HC138/system020/dev/images/logo_bb.png" alt="logo" style="width:15%;height:15%;display:block;margin-left:auto;margin-right:auto">
</div>

# Blocks
Blocks are chunks of ROM that can house filesystems or raw programms. The BIOS trys to mount the first block as a FAT filesystem automaticly.

## Format
A single block is 256 bytes (depends on the pagesize of the ROM (on the megasystem020 256 bytes per page)). All block partitions have a header consisting of a single block that contains meta data like the name, type of the partition and some flags.

## Header structure
```C
enum PART_TYPE {
    PART_TYPE_NONE = 0,
    PART_TYPE_FS = 1,
    PART_TYPE_CODE = 2
    PART_TYPE_MAX = 0xffff;
};
enum PART_FLAGS {
    PART_FLAGS_IGNORE = 0x01,
    PART_FLAGS_EXCEC = 0x02,
    PART_FLAGS_MOUNTABLE = 0x04,
    PART_FLAGS_AUTOMOUNT = 0x08
    PART_FLAGS_MAX = 0xffff;
};
struct BLOCK_HEADER {
    BLOCK_HEADER* nextBlock;
    uint16_t type;
    uint16_t flags;
    uint32_t size;
    unsigned char name[0xff - (sizeof(BLOCK_HEADER*) + (2 * sizeof(uint16_t)) + sizeof(uint32_t))];
};
```
The `nextBlock` field in the `BLOCK_HEADER` points to the next block alligned to the block size (the pointer gets forcefully alligned). If this is the last partition then this field must be `NULL`.

The size of the `type` and `flags` fields in `BLOCK_HEADER` struct are fixed 16 bit wide but because the size of an enum cant be enforced they are defined as `uint16_t` and need a type cast to be set with the enumerations.

The `size` field is the size of the partition in bytes.

The rest of the `BLOCK_HEADER` is filled with the name of the partition. The name must be `NULL` terminated

