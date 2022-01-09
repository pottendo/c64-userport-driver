# c64-userport-driver

- [c64-userport-driver](#c64-userport-driver)
  - [Introduction](#introduction)
  - [Credits](#credits)
  - [Build](#build)
  - [Features](#features)
    - [userport driver](#userport-driver)
    - [CCGMS integration](#ccgms-integration)
    - [IRC](#irc)
    - [Mandelbrot Zoomer](#mandelbrot-zoomer)
  - [Bugs / Features needed](#bugs--features-needed)
  - [License](#license)

## Introduction
This project is closely connected to its counterpart, the *ESP32 userport driver* (https://github.com/pottendo/esp32-userport-driver)

It enables the C64 to communicate via its user-port connector to a ESP32 uController for various functions.
Communcation in 8-bit parallel mode, enabling *high speed* transfer rates. Depending on data-junk sizes, in asynchronous (NMI interrupt driven) mode ~60k+ Baud can be reached, in synchronous mode, up to ~110k+ Baud.

A driver to enable support for CCGMS has been added - along with an 80 columns driver to enjoy BBS-surfing in nice 80cols-widescreen.

A tiny IRC client to chat along the internet with your C64 is there for your communication with the internet on your beloved breadbox!

**DISCLAIMER - Use at your own risk, especially when following the HW module as suggested in the ESP32 userport driver**

## Credits

Being connected to the VICE Emulator (https://vice-emu.sourceforge.io/) developer community I owe **@groepaz, @tlr, @blacky_stardust, @compyx** a great deal of thanks for listening, commenting and giving the right advises. You guys rock the Commodore retro-community!

*@groepaz* provided the great 80 columns console driver, as maintained within the *CC65 project* (https://github.com/cc65/cc65), which I managed to intergrate into this project (IRC support, CCGMS support)

Big thanks to *Alwyz* for maintaining and releasing source-code of *CCGMS* - a great terminal program for the C64. (https://csdb.dk/release/index.php?id=198392)

Valuable support has been provided by members of the *WiC64* project (https://www.wic64.de/) - a great project, check it out!

Without the *Corona Virus*, this project never would have received the time to progress to the current stage. Regardless of this fact, we *hate* it... 

## Build

In general Kick-Assembler (http://www.theweb.dk/KickAssembler/Main.html#frontpage) is used for assembling my source-code.
CCGMS uses 64tass (https://sourceforge.net/projects/tass64/)
To make this compatible I had to provide a little helper script as assembler-driver - see src/64tass.sh<br>
I drive all of this within VS Code, using the respective extensions to support Kick-Assembler and 64tass.

This is completed by using c1541 to build .d64 ready for deployment on your favorite media.

[ add how to build different packages ]
- CCGMS (parport + soft80)
- CCGMS (generic + soft80)
- Testprograms for user-port driver

## Features

Find some impressions here: https://photos.app.goo.gl/WtZMvKTRVcTbYcE1A

### userport driver
Communication with its ESP counterpart is driven with the 8-bit parallel interface (PB0-PB7, control lines) of the C64. (Ab-)using the SP2 line in addtion to protect the CIA lines from both sides has been added. The driver optionally (build-time) takes care of memory banking - necessary if used in conjunction with the soft80 console driver.

Read from userport is NMI driven, could be theoretically used in parallel to some computation.

Write is synchronous, providing even higher throughput.

### CCGMS integration
*CCGMS* has been slightly enhanced to support the driver. Flow Control is implemented, ensuring all bytes are received properly, even in soft80 mode, where screen output could lead to character loss, when connected to fast BBSs.

After start, ensure modem function, by resetting the modem (uController) to synchronize the ESP and the C64 with all the control liens.

In CCGMS, pressing *CBM-HOME* in terminal mode, switches back/forth to 80 columns mode.

A separate CCGMS binary only enhanced with Soft80 is provided - note that only the UP9600/EZ232 driver currently supports soft80 - for other modems, the bank-switching needs to be added.

The *Soft80 Console Driver* is highly optimized for a small memory footprint, by still being reasonable performant. It features PETSCII character support with some limits on coloring, following the GFX architectural limits. Together with CCGMS, great 80col-supporting BBSs outthere, it's the best BBS experience ever on a real C64!

### IRC
A (very) basic IRC client is shipped within the test-programs.

### Mandelbrot Zoomer

To show the potential of a uController as CoProcessor *) a small UI for mandelbrot zoom is provided within the test-programs. Note: to activate it:
- switch the ESP into CoRoutine mode (via Web, or MQTT)
- start testdriver UI, select '0' (show screen) and '6' to launch calculation

*) The *CoProcessor* is 2x240MHz @ 32bit incl. FPU. So one may challange, who's the 'Co' vs. the 1Mhz 6502! ;-)

## Bugs / Features needed
- CCGMS sometimes won't start and locks. Run/Stop - Restore can help und just 'run' again. 
- sometimes CCGMS locks up when surfing. Can be a driver issue, soft80 issue or just a bug in CCGMS.
- IRC is very rudimentary
- CCGMS soft80 support only for pottendos parport and UP9600/EZ232 modems. No protection/error checking is done
- CCGMS settings page is a bit weird in 80cols mode. Switch back to 40cols (CBM-HOME) in terminal mode.
- Better sanity checking if HW is there and in proper state
- Better error recovery
- Request uController mode from C64
- Add reboot commant for uController

## License

Refer to: https://github.com/pottendo/c64-userport-driver/blob/master/LICENSE

This is a fun project - don't expect any *real* support if you need any help. I'll do my best to respond, though, as my time permits.
(C) 2022, pottendo productions