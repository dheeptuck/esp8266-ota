//////////////////////////////////////////////////
// FOTA sample
// Copyright 2017 Sudeep Chandrasekaran
// dheeptuck@gmail.com
// See license.txt for license terms.
// OTA code based on SDK sample from Espressif.
// Changelog:
// @Sudeep on 20th March 2017
//////////////////////////////////////////////////

#ifndef NETWORK_H
#define NETWORK_H

#include "ets_sys.h"
#include "osapi.h"
#include "gpio.h"
#include "os_type.h"
#include "ip_addr.h"
#include "espconn.h"
#include "user_interface.h"
#include "user_config.h"

//standard libraries
#include <string.h>



/**
  * The initialization function for the WiFi network
  **/
void ICACHE_FLASH_ATTR networkInit();


void ICACHE_FLASH_ATTR wifi_callback( System_Event_t *evt );


void ICACHE_FLASH_ATTR networkUpdate();



#endif