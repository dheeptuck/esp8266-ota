//////////////////////////////////////////////////
// FOTA sample
// Copyright 2017 Sudeep Chandrasekaran
// dheeptuck@gmail.com
// See license.txt for license terms.
// OTA code based on SDK sample from Espressif.
// Changelog:
// @Sudeep on 20th March 2017
//////////////////////////////////////////////////

#include "ets_sys.h"
#include "osapi.h"
#include "gpio.h"
#include "os_type.h"
#include "ip_addr.h"
#include "espconn.h"
#include "user_interface.h"


//user modules
#include "user_config.h"
#include "network/network.h"
#include "rboot-ota.h"



static volatile os_timer_t high_priority_poll_timer;
static volatile os_timer_t medium_priority_poll_timer;
static volatile os_timer_t low_priority_poll_timer;

#define user_procTaskPrio        0
#define user_procTaskQueueLen    1
os_event_t    user_procTaskQueue[user_procTaskQueueLen];
static void user_procTask(os_event_t *events);




static void ICACHE_FLASH_ATTR OtaUpdate_CallBack(bool result, uint8 rom_slot) {

  if(result == true) {
    // success
    if (rom_slot == FLASH_BY_ADDR) {
      os_printf("Write successful.\r\n");
    } else {
      // set to boot new rom and then reboot
      char msg[40];
      os_sprintf(msg, "Firmware updated, rebooting to rom %d...\r\n", rom_slot);
      os_printf(msg);
      rboot_set_current_rom(rom_slot);
      system_restart();
    }
  } else {
    // fail
    os_printf("Firmware update failed!\r\n");
  }
}

static void ICACHE_FLASH_ATTR OtaUpdate() {
  
  // start the upgrade process
  if (rboot_ota_start((ota_callback)OtaUpdate_CallBack)) {
    os_printf("Updating...\r\n");
  } else {
    os_printf("Updating failed!\r\n\r\n");
  }
  
}

void user_rf_pre_init( void )
{
}


void highPriorityTaskPoll(void *arg)
{


}

void mediumPriorityTaskPoll(void *arg)
{
     //uiUpdate();
    os_printf("starting......\n");
}

void ICACHE_FLASH_ATTR lowPriorityTaskPoll(void *arg)
{
   OtaUpdate();
}



void ICACHE_FLASH_ATTR pollingTimerInit()
{
    //Disarm timers
    //os_timer_disarm(&high_priority_poll_timer);
    //os_timer_disarm(&medium_priority_poll_timer);
    os_timer_disarm(&low_priority_poll_timer);

    //Setup timers
    os_timer_setfn(&high_priority_poll_timer, (os_timer_func_t *)highPriorityTaskPoll, NULL);
    os_timer_setfn(&medium_priority_poll_timer, (os_timer_func_t *)mediumPriorityTaskPoll, NULL);
    os_timer_setfn(&low_priority_poll_timer, (os_timer_func_t *)lowPriorityTaskPoll, NULL);

    //Arm the timer
    //&some_timer is the pointer
    //1000 is the fire time in ms
    //0 for once and 1 for repeating
    os_timer_arm(&high_priority_poll_timer, 10, 1);
    //Arm the timer
    //&some_timer is the pointer
    //1000 is the fire time in ms
    //0 for once and 1 for repeating
    os_timer_arm(&medium_priority_poll_timer, 4000, 1);
    //Arm the timer
    //&some_timer is the pointer
    //1000 is the fire time in ms
    //0 for once and 1 for repeating
    os_timer_arm(&low_priority_poll_timer, 30000, 1);
}


//Do nothing function
static void ICACHE_FLASH_ATTR
user_procTask(os_event_t *events)
{
    os_delay_us(10);

}


void ICACHE_FLASH_ATTR user_init( void )
{
    os_delay_us(500000);
    //UART configuration for debugg dump
    uart_div_modify( 0, UART_CLK_FREQ / ( 115200 ) );
    os_printf( "%s\n", __FUNCTION__ );

    os_printf("starting......\n");
    pollingTimerInit();
    networkInit();

    //Start os task
    system_os_task(user_procTask, user_procTaskPrio,user_procTaskQueue, user_procTaskQueueLen);

}


uint32 ICACHE_FLASH_ATTR __attribute__((weak))
user_rf_cal_sector_set(void)
{
  enum flash_size_map size_map = system_get_flash_size_map();
  uint32 rf_cal_sec = 0;

  switch (size_map) {
    case FLASH_SIZE_4M_MAP_256_256:
      rf_cal_sec = 128 - 5;
      break;

    case FLASH_SIZE_8M_MAP_512_512:
      rf_cal_sec = 256 - 5;
      break;

    case FLASH_SIZE_16M_MAP_512_512:
    case FLASH_SIZE_16M_MAP_1024_1024:
      rf_cal_sec = 512 - 5;
      break;

    case FLASH_SIZE_32M_MAP_512_512:
    case FLASH_SIZE_32M_MAP_1024_1024:
      rf_cal_sec = 1024 - 5;
      break;

    default:
      rf_cal_sec = 0;
      break;
  }

  return rf_cal_sec;
}