#include "device.h"

int DeviceInit() {
    for (int i = 0; i < MAX_DEVS; i++) globalDeviceTable[i].deviceValid = 0;
    return 0;
}

struct Device* DeviceAllocate() {
    for (int i = 0; i < MAX_DEVS; i++) {
        if (!globalDeviceTable[i].deviceValid) {
            globalDeviceTable[i].deviceValid = 1;
            return &globalDeviceTable[i];
        }
    }
    return NULL;
}

int DeviceRemove(struct Device* dev) {
    long offset = globalDeviceTable - dev;
    int index = offset / sizeof(struct Device);
    if (index < 0 || index > MAX_DEVS) {
        //device is not part of the global device table
        return -1;
    }
    //clear all device data
    char* ptn = (char*) dev;
    for (int i = 0; i < sizeof(struct Device); i++) {
        ptn[i] = 0;
    }
    return index;
}

int noOpen() {
    return -1;
}
int noClose(struct Device* dev) {
    return -1;
}
int noRead(struct Device* dev, int length, void* buffer) {
    return -1;
}
int noWrite(struct Device* dec, int length, void* buffer) {
    return -1;
}