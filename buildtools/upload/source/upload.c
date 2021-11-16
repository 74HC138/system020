#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <unistd.h>

struct termios tty;
int serial_port;
unsigned char buffer[512];
unsigned char* hexTable = "0123456789ABCDEF";

int openPort(char* portname, int baudrate) {
    serial_port = open(portname, O_RDWR);
    if (serial_port < 0) {
        printf("Error %i from open: %s\n", errno, strerror(errno));
        return -1;
    }
    if (tcgetattr(serial_port, &tty) != 0) {
        printf("Error %i from tcgetattr: %s\n", errno, strerror(errno));
        return -1;
    }
    tty.c_cflag &= ~PARENB & ~CSTOPB & ~CRTSCTS;
    tty.c_cflag |= CS8 | CREAD | CLOCAL;
    tty.c_lflag &= ~ICANON & ~ECHO & ~ECHOE & ~ECHONL & ~ISIG;
    tty.c_iflag &= ~IXON & ~IXOFF & ~IXANY & ~IGNBRK & ~BRKINT & ~PARMRK & ~ISTRIP & ~INLCR & ~IGNCR & ~ICRNL;
    tty.c_oflag &= ~OPOST & ~ONLCR;
    tty.c_cc[VTIME] = 10; //timeout after 10 seconds
    tty.c_cc[VMIN] = 0;
    cfsetispeed(&tty, baudrate);
    cfsetospeed(&tty, baudrate);
    if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
        printf("Error %i from tcsetattr: %s\n", errno, strerror(errno));
        return -1;
    }
    return serial_port;
}

int uploadPutBuffer(unsigned char* binBuffer) {
    write(serial_port, "p", 1);
    unsigned char uploadBuffer[2];
    for (int i = 0; i < 256; i++) {
        uploadBuffer[0] = hexTable[(binBuffer[i] & 0x0f)];
        uploadBuffer[1] = hexTable[((binBuffer[i] & 0xf0) >> 4)];
        write(serial_port, uploadBuffer, 2);
    }
    int timeoutCount = 0;
    while (42) {
        int n = read(serial_port, &buffer, sizeof(buffer));
        if (n == 0) {
            printf("Connection timeout!\n");
            timeoutCount++;
            if (timeoutCount > 3) {
                printf("Connection failed\n");
                return -1;
            }
        } else {
            for (int i = 0; i < n; i++) {
                if (buffer[i] == 'k') return 0;
            }
        }
    }
}

int main(int argc, char** argv) {
    if (argc < 5) {
        printf("Expected parameters: [port] [baudrate] [file] [base address]\n");
        return -1;
    }
    if (openPort(argv[1], atoi(argv[2])) < 0) {
        printf("Error could not open port %s\n", argv[1]);
        return -1;
    }
    printf("Port opened\n");
    printf("Testing connection...\n");
    write(serial_port, "v", 1);

    unsigned char versionBuffer[100];
    int versionPos = 0;
    int endFound = 0;
    int timeoutCount = 0;
    int startVersionString = 0;
    while (endFound == 0) {
        int n = read(serial_port, &buffer, sizeof(buffer));
        if (n == 0) {
            timeoutCount++;
            printf("Connection timeout!\n");
            if (timeoutCount >= 3) {
                printf("Error could not connect to board\n");
                close(serial_port);
                return -1;
            }
        } else {
            for (int i = 0; i < n; i++) {
                if (buffer[i] == ']') startVersionString = 0;
                if (startVersionString != 0) {
                    versionBuffer[versionPos] = buffer[i];
                    versionPos++;
                }
                if (buffer[i] == '[') startVersionString = 1;
                if (buffer[i] == 'k') endFound = 1;
            }
        }
    }
    versionBuffer[versionPos] = 0;

    printf("Connection astablished\n");
    printf("Upload payload version: %s\n", versionBuffer);
    printf("Timeout count: %d\n", timeoutCount);

    uploadPutBuffer(buffer);
    printf("Buffer uploaded\n");

    close(serial_port);
    printf("closed port\n");

}