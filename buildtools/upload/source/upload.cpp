#include <iostream>
#include "rs232.h"
#include <string>

void putBuffer(int portnum, char* data) {
    char hex_string[10];
    RS232_SendByte(portnum, 'p');
    for (int i = 0; i < 256; i++) {
        sprintf(hex_string, "%X", data[i]);
        RS232_SendBuf(portnum, (unsigned char*) hex_string, 2);
    }
    RS232_flushRX(portnum);
}
void getBuffer(int portnum, char* data) {
    char hex_string[3];
    hex_string[2] = 0x00;
    RS232_SendByte(portnum, 'g');
    for (int i = 0; i < 256; i++) {
        RS232_PollComport(portnum, (unsigned char *) &hex_string[0], 1);
        RS232_PollComport(portnum, (unsigned char *) &hex_string[1], 1);
        data[i] = std::stoi(&hex_string[0], 0, 16);
    }
    RS232_flushRX(portnum);
}
void readMemory(int portnum, uint32_t address) {
    char hex_string[10];
    sprintf(hex_string, "%X", address);
    RS232_SendByte(portnum, 'r');
    RS232_SendBuf(portnum, (unsigned char *) hex_string, 4);
    char d;
    while (d != 'k') {
        RS232_PollComport(portnum, (unsigned char *) &d, 1);
    }
}
void writeMemory(int portnum, uint32_t address) {
    char hex_string[10];
    sprintf(hex_string, "%X", address);
    RS232_SendByte(portnum, 'w');
    RS232_SendBuf(portnum, (unsigned char *) hex_string, 4);
    char d;
    while (d != 'k') {
        RS232_PollComport(portnum, (unsigned char *) &d, 1);
    }
}

int main(int argc, char** argv) {
    if (argc < 5) {
        std::cout << "Error: expected parameters\n";
        std::cout << "upload [port] [speed] [file] [base address in hex]\n";
        return 1;
    }

    FILE* binFile = fopen(argv[3], "rb");
    if (binFile == NULL) {
        std::cout << "Error: cant open file\n";
        return 1;
    }

    int portnum = RS232_GetPortnr(argv[1]);
    if (portnum == -1) {
        std::cout << "Error: port was not found\n";
        std::cout << "Exspects parameter like \"ttyS0\"\n";
        return 1;
    }
    if (RS232_OpenComport(portnum, std::stoi(argv[2]), "8N1", 0) == 1) {
        std::cout << "Error: could not open port\n";
        RS232_CloseComport(portnum);
        return 1;
    }
    std::cout << "port open\n";
    std::cout << "testing connection\n";

    std::string versionName;

    char d[2];
    d[1] = 0;
    bool stringReached = false;

    RS232_flushRXTX(portnum);
    RS232_SendByte(portnum, 'v');
    while (d[0] != 'k') {
        RS232_PollComport(portnum, (unsigned char *) d, 1);
        if (d[0] == ']') stringReached = false;
        if (stringReached == true) versionName.append(d);
        if (d[0] == '[') stringReached = true;
    }

    std::cout << "updater payload version: " << versionName << "\n";
    std::cout << "connection OK\n";

    fseek(binFile, 0, SEEK_END);
    uint32_t fileLength = ftell(binFile);
    fseek(binFile, 0, SEEK_SET);

    char dataBuffer[256];
    uint32_t startAddress = std::stoi(argv[4], 0, 16);

    std::cout << "writing to memory...\n";

    for (uint32_t i = 0; i <= fileLength; i += 256) {
        fread(dataBuffer, 256, 1, binFile);
        putBuffer(portnum, dataBuffer);
        writeMemory(portnum, startAddress);
        startAddress += 256;
    }

    std::cout << "writing done!\n";

    return 0;

}