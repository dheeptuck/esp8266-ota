#ifndef __RBOOT_OTA_H__
#define __RBOOT_OTA_H__

//////////////////////////////////////////////////
// rBoot OTA sample code for ESP8266.
// Copyright 2015 Richard A Burton
// richardaburton@gmail.com
// See license.txt for license terms.
// OTA code based on SDK sample from Espressif.
//////////////////////////////////////////////////

#include "rboot-api.h"
#include "user_config.h"

#ifdef __cplusplus
extern "C" {
#endif

#define OTA_FILE "file.bin"

// general http header
// #define HTTP_HEADER "Connection: keep-alive\r\n\
// Cache-Control: no-cache\r\n\
// User-Agent: rBoot-Sample/1.1\r\n\
// Accept: */*\r\n\r\n"
#define HTTP_HEADER "Connection: keep-alive\r\n\
Cache-Control: no-cache\r\n\
User-Agent: ESP8266\r\n\
Accept: */*\r\n\r\n"

/* this comment to keep notepad++ happy */

// timeout for the initial connect and each recv (in ms)
#define OTA_NETWORK_TIMEOUT  4000

// used to indicate a non-rom flash
#define FLASH_BY_ADDR 0xff

// callback method should take this format
typedef void (*ota_callback)(bool result, uint8 rom_slot);

// function to perform the ota update
bool ICACHE_FLASH_ATTR rboot_ota_start(ota_callback callback);

#ifdef __cplusplus
}
#endif

#endif
