<div>
    <image src="https://raw.githubusercontent.com/74HC138/system020/dev/images/logo_bb.png" alt="logo" style="width:15%;height:15%;display:block;margin-left:auto;margin-right:auto">
</div>

# System020

## What is it

System020 is a collection of software and tools for the megasystem020. All the software is written in motorola 68020 assembly with madmac syntax and gets assembled by vasmm68k.

## What does it

System020 contains a BIOS with bootloader and OS with preemtive multitasking, as well as some tools to build and upload roms to the megasystem020 SBC.

More informations about the components can be found in their respective paths

## Instalation

For a basic system without extra programms:

1. Clone and go to the path of the repo
2. `make tools`
3. `make fs`
4. `make compost`
5. `make bios`
6. `make essentials`
7. `make assemble`
8. Take the rom in `build/ROM_bundle.bin`and write it to the EEPROM(s) of the megasystem020
   or
   `make upload` (Note: for this there has to be a bootloader allready on the system. To enter bootloader mode press the UserInt button while reseting)
9. open/connect your favorite serial terminal and enjoy

To add your own files you can:
  * mount the file `build/FS.bin` and add the file there
  * upload the file via zmodem when the system is running
  * write it directly on the system
  * use a harddrive with the system020, enable automounting and use that

## Disclaimer

My code including the makefiles has no garante to actually work properly. If any demage should occour due to my code thats on you. Especially if you run it as root (dont).

## License

All of my code is licensed under GPL3. Do with it what you want as long as you dont sell it.