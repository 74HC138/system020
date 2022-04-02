#ifndef DEVICE_H
#define DEVICE_H

#include "glue.h"

#define MAX_DEVS 1024
//common device ioctl commands that all device drivers have to impliment
#define DEV_COMMON_NOP 0x0000 //no opperation (parameters none)
#define DEV_COMMON_GETDISCRIPTOR 0x0001 //get device desciptor (parameter pointer to desciptor struct)
#define DEV_COMMON_ERRORTOSTRING 0x0002 //get human readable string from error code (parameter pointer to conversion struct)

enum DeviceType {
    None = 0, //device does not fit into any catagory
    BlockDev = 1, //harddrive, removable media, etc
    tty = 2, //serial interface, virtual terminal, etc
    hid = 3, //keyboard, mouse, controller, etc
};
struct DeviceDiscriptor {
    enum DeviceType type;
    const char* name;
    const char* vendor;
};
struct DeviceErrorConversion {
    int errorCode;
    const char* errorString;
};
struct Device {
    //open function inits device and should return a status code
    //parameter: pointer to Device structure
    //return value: status or error code
    int (*open)(struct Device*);
    
    //close function deinits device
    //parameter: pointer to Device structure
    //return value: status or error code
    int (*close)(struct Device*);

    //ioctl function sets or reads the device configuration
    //parameters: pointer to Device structure, command, command data
    //return value: status or error code
    int (*ioctl)(struct Device*, int, void*);

    //read function reads data from device
    //parameters: pointer to Device structure, length, pointer to buffer
    //return value: status or error code
    int (*read)(struct Device*, int, void*);

    //write function writes data to device
    //parameters: pointer to Device structre, length of buffer, pointer to buffer
    //return value: status or error code
    int (*write)(struct Device*, int, void*);

    //used internaly for device slot reservation
    //only devices with deviceValid != 0 should be called 
    int deviceValid;
    
    //path to corresponding device file
    const char* mountPath;

    //device specific data
    //should be managed by device functions
    char data[256];
};

struct Device globalDeviceTable[MAX_DEVS];

#endif