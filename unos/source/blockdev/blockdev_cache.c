//includes
#include <stdint.h>
#include <kernel/call.h>

//defines
#define CACHESIZE_MAX 1024
#define CACHESTARTLIFETIME 50
#define CACHELIFETIMEINC 10
//enumerations

//structures
struct BlockdevCacheEntry {
    void* Cache;
    uint32_t LBA;
    uint8_t Device;
    uint8_t Lifetime;
};
//constants

//variables
uint32_t CacheSize;
struct BlockdevCacheEntry cacheTable[CACHESIZE_MAX];
uint16_t lock;
//functions
void cacheMutexLock() {
    while (lock > 0) {
        kernelCall(ForceTaskSwitch);
    }
    lock = 1;
    return;
}
void cacheMutexClear() {
    lock = 0;
    return;
}
uint32_t checkIfCached(uint32_t LBA, uint8_t device) {
    cacheMutexLock();
    uint32_t crc = getCRC32uint32(LBA);
    uint32_t entry = ((crc << 2) | (LBA & 0x03)) % CacheSize;
    if (cacheTable[entry].LBA == LBA && cacheTable[entry].Device == device && cacheTable[entry].Lifetime > 0 && cacheTable[entry].Cache != (void*) 0) {
        cacheMutexClear();
        return entry;
    }
    cacheMutexClear();
    return -1;
}
void* getCache(uint32_t entry) {
    cacheMutexLock();
    if (cacheTable[entry].Lifetime < 0) {
        cacheMutexClear();
        return (void*) 0;
    }
    uint16_t lifetime = cacheTable[entry].Lifetime + CACHELIFETIMEINC;
    if (lifetime > UINT8_MAX) {
        cacheTable[entry].Lifetime = UINT8_MAX;
    }
    cacheTable[entry].Lifetime = lifetime;
    cacheMutexClear();
    return cacheTable[entry].Cache;
}
uint32_t addCache(uint32_t LBA, uint8_t Device, void* Data) {
    cacheMutexLock();
    uint32_t crc = getCRC32uint32(LBA);
    uint32_t entry = ((crc << 2) | (LBA & 0x03)) % CacheSize;
    if (cacheTable[entry].Lifetime > 0) {
        //cache entry is taken
        if (cacheTable[entry].LBA == LBA && cacheTable[entry].Device == Device) {
            //allready in cache
            if (cacheTable[entry].Cache == (void*) 0) {
                //cache is not allocated
                void* cachePointer = allocateCache();
                if (cachePointer == (void*) 0) {
                    cacheMutexClear();
                    return -1; //cache cannot be allocated
                }
                cacheTable[entry].Cache = cachePointer;
            }
            //update cache
            uint32_t* source = (uint32_t*) Data;
            uint32_t* dest = (uint32_t*) cacheTable[entry].Cache;
            for (int i = 0; i < 128; i++) dest[i] = source[i]; //copy data to cache
            cacheTable[entry].Lifetime = CACHESTARTLIFETIME;
            cacheMutexClear();
            return entry; //block is updated and in cache
        }
        cacheMutexClear();
        return -1; //cache is taken by other block/device
    }
    void* cachePointer = allocateCache();
    if (cachePointer == (void*) 0) { 
        return -1; //cache cannot be allocated
        cacheMutexClear();
    }
    cacheTable[entry].Cache = cachePointer;
    uint32_t* source = (uint32_t*) Data;
    uint32_t* dest = (uint32_t*) cachePointer;
    for (int i = 0; i < 128; i++) dest[i] = source[i]; //copy data to cache
    cacheTable[entry].Lifetime = CACHESTARTLIFETIME;
    cacheMutexClear();
    return entry; //cache is allocated and written
}




