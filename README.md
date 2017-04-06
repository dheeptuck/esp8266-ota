ESP8266 FOTA Example
====================


## Introduction

The project is aimed at making life of esp8266 enthusiasts simple by providing
a step by step guide to enable firmware over the air feature. The code for the
project has been borrowed from:

1. <https://github.com/raburton/rboot>

2. <https://github.com/raburton/rboot-sample>


Although the project is fully functional. It is aimed as a example for OTA
feature and developers can add their custom modules to it. Following is the
major differences compared to the original project:

1. The linker command file has bee changed to adapt to SDK 2.0
2. Changes in HTTP header parsing logic to accomodate all servers.
3. Esptool for compiling rather than esptool2.
4. Makefile changes to easily add newer modules


## Overview

The bootloader used in the project is rboot developed by Richard Burton. The frimware sends a GET request periodically(configured in user_config.c) to the
specified HTTP server and upgrades itself. The entire program flash is divided
into two 512 KB partitions. One partiton is used to run the current program and
another partition is used to load a newer firmware. If the current program is running from partition 1 then the new program will be loaded into partition 2.
Once the newer firmware is loaded, the module resets to boot from the new program.
Simliarly if the current program is running from partition 2 partition 1 will be
used for loading the newer firmware. This means that the esp needs to atleast have 1MB of flash. Building the project yields to binaries. Both the binaries are almost the same except the way they are linked using the linker. One of them is linked so that they can lie on 0x02000 and another is linked so that it can lie on 0x82000 of the program flash. For any firmware both these binaries needs to be generated. More about the internal working of the bootloader can be found at:

1. <https://richard.burtons.org/2015/05/18/rboot-a-new-boot-loader-for-esp8266/>


## Building




### Dependencies

1. Non-OS SDK 2.0\
   <https://espressif.com/en/support/download/sdks-demos>
2. xtensa toolchain 4.8.2
   The tool chain can be cloned and installed from
   <https://github.com/pfalcon/esp-open-sdk>\
   Non-standalone version needs to be installed.
3. Latest esptool
   pip install esptool



### Configuration
Most of the configuration needs to be done in user/user_config.h. Following are the configurations:
1. **AP_NAME** - The network to which the module needs to connect
2. **AP_PWD**  - The password of the network to which the module needs to connect
3. **OTA_HOST** - IP of the server to which the module will download the firmware.
   You can put the IP address of your computer for testing.
4. **OTA_PORT** - The port through which the firmware will be downloaded.
   Keep the port to be 3000 for testing.
5. Keep the other configurations intact

 Following configurations needs to be updated in the makefile:

 1. **SDK_BASE** - This variable should point to the SDK directory.
    default: /opt/Espressif/ESP8266_NONOS_SDK
 2. **XTENSA_TOOLS_ROOT** - The bin directory of the xtensa toolchain
    default: /opt/Espressif/ESP8266_NONOS_SDK
 3. **ESPTOOL**  - This should point to the esptool (esptool.py)


### Steps for building:

1. Move to the repo
2. do "make clean"
3. do "make all"
   This should generate the following two binaries inside the firmware
   directory:
4. do "make flash"
   This will copy the following binaries to the modules flash:
   1. fota_sample_0x02000.bin
   2. fota_sample_0x82000.bin
   3. rboot.bin
   You might have to change the serial port permissions.

## Running a Simple HTTP Server

For the purpose of testing I used the default python http server called the
simpleHTTPServer. The module comes by default in python 2.7. Running SimpleHTTPServer from a directory hosts all the files in the directory on to
the network. The firmware files can be hosted by running the server on the
firmware directory using the below command:

*python -m SimpleHTTPServer 3000*


You can check the weather the files are hosted by accessing your ip on the browser:

<your_ip_address>:3000
ex: 192.168.1.4:3000

It should list the files in the firmware folder.

Please note that the server might not be accessible over the public IP due
to firewall.


## Building on the project

To add any new module to the project the **USER_MODULES** variable in the makefile
needs to be updated. The **USER_MODULES** specifies a list of folders that would
be searched to find the files that need to be compiled.


## To Do

1. A version check needs to be done before updating a firmware.
2. Firmware retrieval through HTTPS.