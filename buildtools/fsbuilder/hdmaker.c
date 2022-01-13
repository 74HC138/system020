#include <stdio.h>
#include <ctype.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define VERSION "0.1"

enum PART_TYPE {
	PART_TYPE_NONE = 0,
	PART_TYPE_FS = 1,
	PART_TYPE_CODE = 2,
	PART_TYPE_RAW = 3,
	PART_TYPE_MAX = 0xffff
};
enum PART_FLAGS {
	PART_FLAGS_IGNORE = 0x01,
	PART_FLAGS_EXCEC = 0x02,
	PART_FLAGS_MOUNTABLE = 0x04,
	PART_FLAGS_AUTOMOUNT = 0x08,
	PART_FLAGS_MAX = 0xffff
};
struct BLOCK_HEADER {
	uint32_t nextBlock;
	uint16_t type;
	uint16_t flags;
	uint32_t size;
	unsigned char name[243];
};

int verbose = 0;
struct BLOCK_HEADER header;
char* headerName;
char* prevHeaderName;

int doneType = 0;
int doneFlags = 0;
int doneSize = 0;

int main(int argc, char** argv) {
	if (argc <= 1) {
		printf("No parameters given\nUse -h for help\n");
		exit(1);
	}

	header.nextBlock = 0xffffffff;
	header.type = PART_TYPE_NONE;
	header.flags = 0;
	header.size = 0;
	header.name[0] = '\0';

	int i = 1;
	while (i < argc - 1) {
		if (strcmp("-h", argv[i]) == 0) {
			//display help text
			printf("hdmaker [options] [header]\n");
			printf("Options:\n");
			printf("-h          display this help text\n");
			printf("-V          display version information\n");
			printf("-v          verbose output\n");
			printf("-t [type]   set type of partition\n");
			printf("-f [flags]  set partition flags\n");
			printf("-s [size]   set size of partition\n");
			printf("-F [fs]     extract size from partition image\n");
			printf("-p [header] update previous header to make this header follow it\n");
			printf("-n [name]   set name of partition\n");
			printf("Partition types:\n");
			printf("NONE        no type specified\n");
			printf("FS          filesystem (default) [fat12/fat16]\n");
			printf("CODE        single file, no filesystem\n");
			printf("RAW         raw partition, might be used for filesystems of other format (ext3)\n");
			printf("Partition flags:\n");
			printf("I           ignore partition\n");
			printf("E           partition is executable\n");
			printf("M           partition is mountable\n");
			printf("A           partition should get automounted\n");
			exit(0);
		} else if (strcmp("-V", argv[i]) == 0) {
			printf("fsbuilder version %s\n", VERSION);
			printf("Written by Sebastian Groth\n");
			printf("Licensed under GPL3.0, no waranty included\n");
			exit(0);
		} else if (strcmp("-v", argv[i]) == 0) {
			printf("Using verbose output\n");
			verbose = 1;
			i++;
		} else if (strcmp("-t", argv[i]) == 0) {
			//set the type of the partition
			doneType = 1;
			i++;
			if (strcmp("NONE", argv[i]) == 0) {
				//type is NONE
				header.type = PART_TYPE_NONE;
				if (verbose) printf("Using partition type NONE\n");
			} else if (strcmp("FS", argv[i]) == 0) {
				//type is FS
				header.type = PART_TYPE_FS;
				if (verbose) printf("Using partition type FS\n");
			} else if (strcmp("CODE", argv[i]) == 0) {
				//type is CODE
				header.type = PART_TYPE_CODE;
				if (verbose) printf("Using partition type CODE\n");
			} else if (strcmp("RAW", argv[i]) == 0) {
				//type is RAW
				header.type = PART_TYPE_RAW;
				if (verbose) printf("Using partition type RAW\n");
			} else {
				//type not recognised. Using FS
				header.type = PART_TYPE_FS;
				printf("Type %s not recognised. Using FS\n", argv[i]);
			}
			i++;
		} else if (strcmp("-f", argv[i]) == 0) {
			doneFlags = 1;
			i++;
			int j = 0;
			while (argv[i][j] != 0) {
				if (argv[i][j] == 'I' || argv[i][j] == 'i') {
					header.flags |= PART_FLAGS_IGNORE;
					if (verbose) printf("Added flag IGNORE\n");
				} else if (argv[i][j] == 'E' || argv[i][j] == 'e') {
					header.flags |= PART_FLAGS_EXCEC;
					if (verbose) printf("Added flag EXCEC\n");
				} else if (argv[i][j] == 'M' || argv[i][j] == 'm') {
					header.flags |= PART_FLAGS_MOUNTABLE;
					if (verbose) printf("Added flag MOUNTABLE\n");
				} else if (argv[i][j] == 'A' || argv[i][j] == 'a') {
					header.flags |= PART_FLAGS_AUTOMOUNT;
					if (verbose) printf("Added flag AUTOMOUNT\n");
				} else {
					printf("did not recognise flag %c\n", argv[i][j]);
				}
				j++;
			}
			i++;
		} else if (strcmp("-s", argv[i]) == 0) {
			doneSize = 1;
			i++;
			char* endpointer;
			header.size = strtol(argv[i], &endpointer, 0); //base 0 -> autodetect (0x = hex, 123456789 = decimal, 0 = octal)
			if (endpointer != NULL) printf("Parameter %s is not a number!\nInterpreted as %d\n", argv[i], header.size);
			if (verbose) printf("Size of partition set to %d\n", header.size);
			i++;
		} else if (strcmp("-F", argv[i]) == 0) {
			doneSize = 1;
			i++;
			FILE* f = fopen(argv[i], "r");
			if (!f) {
				printf("Could not open file %s\n", argv[i]);
				exit(1);
			}
			if (verbose) printf("Opened file %s\n", argv[i]);
			fseek(f, 0, SEEK_END);
			header.size = ftell(f);
			if (header.size % 256 != 0) {
				header.size &= 0xffffff00;
				header.size += 256;
			}
			if (verbose) printf("Partition size: %d bytes\n", header.size);
			fclose(f);
			i++;
		} else if (strcmp("-p", argv[i]) == 0) {
			i++;
			FILE* f = fopen(argv[i], "rb+");
			if (!f) {
				printf("Could not open file %s\n", argv[i]);
				exit(1);
			}
			if (verbose) printf("Opened file %s\n", argv[i]);
			struct BLOCK_HEADER extHeader;
			fread((void*) &extHeader, sizeof(struct BLOCK_HEADER), 1, f);
			if (verbose) printf("Size of previous partition is %d bytes\n", extHeader.size);
			if (extHeader.nextBlock != 0xffffffff) printf("Warning, previous partition is not last partition!\n");
			uint32_t offset = 256 + extHeader.size;
			if (extHeader.size % 256 == 0) offset += 256;
			offset &= 0xffffff00;
			extHeader.nextBlock = offset;
			fseek(f, 0, SEEK_SET);
			fwrite((const void*) &extHeader, sizeof(struct BLOCK_HEADER), 1, f);
			fclose(f);
			if (verbose) printf("Updated nextBlock of previous partition\n");
			i++;
		} else if (strcmp("-n", argv[i]) == 0) {
			i++;
			if (strlen(argv[i]) > 242) {
				printf("Warning, name chosen is longer than 242 characters\n");
				strncpy(header.name, argv[i], 242);
				header.name[242] = '\0';
			} else {
				if (verbose) printf("Setting name of partition to %s", argv[i]);
				strcpy(header.name, argv[i]);
			}
			i++;
		} else {
			printf("Option %s no recognised\n", argv[i]);
			exit(1);
		}
	}
	if (doneType == 0 || doneFlags == 0 || doneSize == 0) {
		printf("Did not specify needed information\n");
		printf("Specify the Type, Flags and Size of the partition\n");
		exit(1);
	}
	if (verbose) printf("Header generated\n");
	FILE* f = fopen(argv[argc-1], "wb");
	if (!f) {
		printf("Could not create output file %s\n", argv[argc-1]);
		exit(1);
	}
	fwrite((const void*) &header, sizeof(struct BLOCK_HEADER), 1, f);
	fclose(f);
	if (verbose) printf("Written header to output file\n");

	exit(0);
	return 0;
}
