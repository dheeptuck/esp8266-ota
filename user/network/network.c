#include "network.h"



void ICACHE_FLASH_ATTR networkInit()
{

    wifi_set_opmode_current(0x01);     //station mode
    wifi_set_event_handler_cb(wifi_callback);
    struct station_config stationConf;
    stationConf.bssid_set = 0; 
    os_memcpy(&stationConf.ssid, AP_NAME, 32); 
    os_memcpy(&stationConf.password, AP_PWD, 64); 
    wifi_station_set_config(&stationConf);
    wifi_station_connect();
}


void ICACHE_FLASH_ATTR wifi_callback( System_Event_t *evt )
{
    
    switch ( evt->event )
    {
        case EVENT_STAMODE_CONNECTED:
        {
            os_printf("connect to ssid %s, channel %d\n",
                        evt->event_info.connected.ssid,
                        evt->event_info.connected.channel);
            break;
        }
        case EVENT_STAMODE_DISCONNECTED:
        {
            os_printf("disconnect from ssid %s, reason %d\n",
                        evt->event_info.disconnected.ssid,
                        evt->event_info.disconnected.reason);
           
            break;
        }
        case EVENT_STAMODE_GOT_IP:
        {
            os_printf("ip:" IPSTR ",mask:" IPSTR ",gw:" IPSTR,
                        IP2STR(&evt->event_info.got_ip.ip),
                        IP2STR(&evt->event_info.got_ip.mask),
                        IP2STR(&evt->event_info.got_ip.gw));
            os_printf("\n");
            
           break;
        }
        case EVENT_SOFTAPMODE_STACONNECTED:
        {
            os_printf("station: " MACSTR "join, AID = %d\n",
            MAC2STR(evt->event_info.sta_connected.mac),
            evt->event_info.sta_connected.aid);
            break;
        }
        case EVENT_SOFTAPMODE_STADISCONNECTED:
        {
            os_printf("station: " MACSTR "leave, AID = %d\n",
            MAC2STR(evt->event_info.sta_disconnected.mac),
            evt->event_info.sta_disconnected.aid);
            break;
        }
        
        default:
        {
            break;
        }
    }
}







void ICACHE_FLASH_ATTR networkUpdate()
{


}





