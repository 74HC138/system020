;handler for romfs
;struct FILE {
    uint16_t MountDevice;
    uint32_t currentPosition
    uint32_t currentBlockIndex
}


RomfsInit:
        rts

RomfsMount:
    ;desciption: mounts a romfs filesystem
    ;parameters: void* rootblock of romfs (first block)
    ;returns: int error
    ;preserves registers

FileNewHandle


