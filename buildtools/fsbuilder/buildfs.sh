#!/bin/bash
echo "--------------------------------------------------------------------------------------"
if [ $# -lt 2 ];
then
	echo -e "\x1b[31m\x1b[1mexpected parameter: [Size of filesystem] [output file] [file or path to include] {file or path to include} ...\x1b[0m";
	exit;
fi

echo -e "\x1b[32m\x1b[1mBuilding filesystem\x1b[0m"

if test -f $2;
then
	echo -e "deleting old romfs.bin";
	rm $2;
fi
touch $2
if ! test -f $2;
then
	echo -e "\x1b[32m\x1b[1mCould not create output file\x1b[0m";
	exit;
fi

if [ $1 -gt 0 ];
then
	dd if=/dev/zero count=$1 of=$2
	mkfs -t fat -F 12 $2
	LOOP_PATH=$(udisksctl loop-setup --file $2 | awk '{t=length($5)}END{print substr($5,0,t-1)}')
	echo -e "\x1b[32m\x1b[1mNew loop device path is: "${LOOP_PATH}"\x1b[0m"
	udisksctl mount --block-device ${LOOP_PATH}
	MOUNT_PATH=$(udisksctl info --block-device ${LOOP_PATH} | awk '/MountPoints:/ {print $2}')
	echo -e "\x1b[32m\x1b[1mMount point of filesystem is: "${MOUNT_PATH}"\x1b[0m"

	for ((i=3; i<=$#; i++));
	do
		if test -d ${!i};
		then
			echo "Copying from path: "${!i};
			cp -r ${!i}/* ${MOUNT_PATH};
		fi
		if test -f ${!i};
		then
			echo "Copying file: "${!i};
			cp ${!i} ${MOUNT_PATH};
		fi
		if ! test -e ${!i};
		then
			echo "File not found: "${!i};
		fi
	done
else
	echo -e "\x1b[35m\x1b[1mFilesystem size determened automaticly\x1b[0m"
	#hacky solution to get the actually used size if size parameter is 0
	#create a disk image that is definitly large enough to fit the files (4096 sectors @ 512 bytes = 2Mb, maximum for fat12)
	dd if=/dev/zero	count=4096 of=$2
	mkfs -t fat -F 12 $2
	echo -e "\x1b[35m\x1b[1mDummy filesystem created\x1b[0m"
        LOOP_PATH=$(udisksctl loop-setup --file $2 | awk '{t=length($5)}END{print substr($5,0,t-1)}')
        echo -e "\x1b[32m\x1b[1mNew loop device path is: "${LOOP_PATH}"\x1b[0m"
        udisksctl mount --block-device ${LOOP_PATH}
        MOUNT_PATH=$(udisksctl info --block-device ${LOOP_PATH} | awk '/MountPoints:/ {print $2}')
        echo -e "\x1b[32m\x1b[1mMount point of filesystem is: "${MOUNT_PATH}"\x1b[0m"

	#copy all the files to it
        for ((i=3; i<=$#; i++));
        do
                if test -d ${!i};
                then
                        echo "Copying from path: "${!i};
                        cp -r ${!i}/* ${MOUNT_PATH};
		fi
                if test -f ${!i};
                then
                        echo "Copying file: "${!i};
                        cp ${!i} ${MOUNT_PATH};
                fi
                if ! test -e ${!i};
                then
                        echo "File not found: "${!i};
                fi
        done

	#get the actually used space of the image (including MBR, FAT and directory tables)
	RAW_SIZE=$(($(lsblk --bytes ${LOOP_PATH} | awk 'END{print $4}') / 512));
	SIZE_FREE=$(df ${LOOP_PATH} --block-size=512 | awk 'END{print $4}')
	SIZE_USED=$((RAW_SIZE - SIZE_FREE + 4))
	#SIZE_USED=$(($(du ${MOUNT_PATH} --block-size=512 | awk 'END{print $1}') + $EXTRACLUSTERS))

	echo "RAW_SIZE: "${RAW_SIZE}
	echo "SIZE_FREE: "${SIZE_FREE}
	echo -e "\x1b[35m\x1b[1mMinimal filesystem size: "${SIZE_USED}" Sectors ("$((($SIZE_USED * 512) / 1024))" Kb)\x1b[0m"
	if [ ${SIZE_USED} -lt 100 ];
	then
		#mkfs will not format a disk image smaller than 100 Sectors even if it doesnt need that extra space
		echo -e "\x1b[35m\x1b[1mTo small for mkfs, using 100 Sectors (50 Kb)\x1b[0m";
		SIZE_USED=100
	fi

	#then delete that image
	udisksctl unmount --block-device ${LOOP_PATH}
	udisksctl loop-delete --block-device ${LOOP_PATH}
	rm $2

	#and then create a new image with the size that is actually used
	touch $2
	dd if=/dev/zero count=${SIZE_USED} of=$2
        mkfs -t fat -F 12 $2
        LOOP_PATH=$(udisksctl loop-setup --file $2 | awk '{t=length($5)}END{print substr($5,0,t-1)}')
        echo -e "\x1b[32m\x1b[1mNew loop device path is: "${LOOP_PATH}"\x1b[0m"
        udisksctl mount --block-device ${LOOP_PATH}
        MOUNT_PATH=$(udisksctl info --block-device ${LOOP_PATH} | awk '/MountPoints:/ {print $2}')
        echo -e "\x1b[32m\x1b[1mMount point of filesystem is: "${MOUNT_PATH}"\x1b[0m"

	#and also copy all files to it again
	#not very efficient but it works
        for ((i=3; i<=$#; i++));
        do
                if test -d ${!i};
                then
                        echo "Copying from path: "${!i};
                        cp -r ${!i}/* ${MOUNT_PATH};
                fi
                if test -f ${!i};
                then
                        echo "Copying file: "${!i};
                        cp ${!i} ${MOUNT_PATH};
                fi
                if ! test -e ${!i};
                then
                        echo "File not found: "${!i};
                fi
        done
fi

udisksctl unmount --block-device ${LOOP_PATH}
echo -e "\x1b[32m\x1b[1mFilesystem unmounted\x1b[0m"
udisksctl loop-delete --block-device ${LOOP_PATH}
echo -e "\x1b[32m\x1b[1mLoop device closed\x1b[0m"
echo "--------------------------------------------------------------------------------------"
