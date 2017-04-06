# @Author : Sudeep
# Date    : 3rd March 2017
# The makefile is a port from https://github.com/tuanpmt/esp_mqtt
# The makefile generates two binaries needed for firmware upgrade


# Base directory for the compiler. Needs a / at the end; if not set it'll use the tools that are in
# the PATH.
XTENSA_TOOLS_ROOT ?=~/Software/esp-open-sdk/xtensa-lx106-elf/bin
# base directory of the ESP8266 SDK package, absolute
SDK_BASE	?= /opt/Espressif/ESP8266_NONOS_SDK



#Esptool.py path and port
ESPTOOL		?= /usr/local/bin/esptool.py
ESPPORT		?= /dev/ttyUSB0
ESPBAUD		?= 460800


# rboot binary location
OTA_BOOTLOADER_PATH = user/fota/rboot.bin
LD_SCRIPT_1 = -T user/fota/rom0.ld
LD_SCRIPT_2	= -T user/fota/rom1.ld
BIN_ADDRESS_1 = 0x02000
BIN_ADDRESS_2 = 0x82000
BOOTLOADER_ADDRESS = 0x00000

THISDIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# 40m 26m 20m 80m
ESP_FREQ = 40m
# qio qout dio dout
ESP_MODE = dio
#4m 2m 8m 16m 32m
ESP_SIZE = 8m


VERBOSE = yes
FLAVOR = debug
# name for the target project
TARGET     ?= fota_sample
# name for the target when compiling as library
TARGET_LIB ?= libmqtt.a

# which modules (subdirectories) of the project to include in compiling
USER_MODULES		    = user user/network user/fota
USER_INC				= include
USER_LIB				=

# which modules (subdirectories) of the project to include when compiling as library
LIB_MODULES			= mqtt

SDK_LIBDIR = lib
SDK_LIBS = c gcc phy pp net80211 wpa main lwip crypto ssl json driver
SDK_INC = include include/json
#SDK_INC = /opt/Espressif/ESP8266_NONOS_SDK/include /opt/Espressif/ESP8266_NONOS_SDK/include/json


# Output directors to store intermediate compiled files
# relative to the project directory
BUILD_BASE			= build
FIRMWARE_BASE		= firmware

# Opensdk patches stdint.h when compiled with an internal SDK. If you run into compile problems pertaining to
# redefinition of int types, try setting this to 'yes'.
USE_OPENSDK ?= no

DATETIME := $(shell date "+%Y-%b-%d_%H:%M:%S_%Z")

# select which tools to use as compiler, librarian and linker
CC		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
AR		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
OBJCOPY	:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-objcopy



####
#### no user configurable options below here
####
SRC_DIR				:= $(USER_MODULES)
SRC_DIR_LIB		:= $(LIB_MODULES)
BUILD_DIR			:= $(addprefix $(BUILD_BASE)/,$(USER_MODULES))

INCDIR	:= $(addprefix -I,$(SRC_DIR))
EXTRA_INCDIR	:= $(addprefix -I,$(USER_INC))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))

SDK_LIBDIR	:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_LIBS 		:= $(addprefix -l,$(SDK_LIBS))

SDK_INCDIR	:= $(addprefix -I$(SDK_BASE)/,$(SDK_INC))

SRC		:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
SRC_LIB	:= $(foreach sdir,$(SRC_DIR_LIB),$(wildcard $(sdir)/*.c))
ASMSRC		= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.S))
ASMSRC_LIB = $(foreach sdir,$(SRC_DIR_LIB),$(wildcard $(sdir)/*.S))

OBJ		= $(patsubst %.c,$(BUILD_BASE)/%.o,$(SRC))
OBJ_LIB	= $(patsubst %.c,$(BUILD_BASE)/%.o,$(SRC_LIB))
OBJ		+= $(patsubst %.S,$(BUILD_BASE)/%.o,$(ASMSRC))
OBJ_LIB	+= $(patsubst %.c,$(BUILD_BASE)/%.o,$(ASMSRC_LIB))

APP_AR		:= $(addprefix $(BUILD_BASE)/,$(TARGET).a)
TARGET_OUT_1	:= $(addprefix $(BUILD_BASE)/,$(TARGET)_1.out)
TARGET_OUT_2	:= $(addprefix $(BUILD_BASE)/,$(TARGET)_2.out)



# compiler flags using during compilation of source files
CFLAGS		= -g			\
						-Wpointer-arith		\
						-Wundef			\
						-Wl,-EL			\
						-Wno-implicit-function-declaration \
						-fno-inline-functions	\
						-nostdlib       \
						-mlongcalls	\
						-mtext-section-literals \
						-ffunction-sections \
						-fdata-sections	\
						-fno-builtin-printf\
						-DICACHE_FLASH \
						-DBUID_TIME=\"$(DATETIME)\"

# linker flags used to generate the main object file
LDFLAGS		= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static

ifeq ($(FLAVOR),debug)
    LDFLAGS += -g -O2
    CFLAGS += -DMQTT_DEBUG_ON -DDEBUG_ON
endif

ifeq ($(FLAVOR),release)
    LDFLAGS += -g -O0
endif

V ?= $(VERBOSE)
ifeq ("$(V)","yes")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

ifeq ("$(USE_OPENSDK)","yes")
CFLAGS		+= -DUSE_OPENSDK
else
CFLAGS		+= -D_STDINT_H
endif

ifneq ("$(wildcard $(THISDIR)/include/user_config.local.h)","")
CFLAGS += -DLOCAL_CONFIG_AVAILABLE
endif


ESPTOOL_OPTS=--port $(ESPPORT) --baud $(ESPBAUD)

#32m
ESP_INIT_DATA_DEFAULT_ADDR = 0xfc000

ifeq ("$(ESP_SIZE)","16m")
	ESP_INIT_DATA_DEFAULT_ADDR = 0x1fc000
else ifeq ("$(ESP_SIZE)","32m")
	ESP_INIT_DATA_DEFAULT_ADDR = 0x3fc000
endif

OUTPUT_1 = $(addprefix $(FIRMWARE_BASE)/,$(TARGET)_$(BIN_ADDRESS_1).bin)
OUTPUT_2 = $(addprefix $(FIRMWARE_BASE)/,$(TARGET)_$(BIN_ADDRESS_2).bin)
OUTPUT_LIB := $(addprefix $(FIRMWARE_BASE)/,$(TARGET_LIB))
ESPTOOL_FLASHDEF=--version=2


ESPTOOL_WRITE = write_flash --flash_freq $(ESP_FREQ) --flash_mode $(ESP_MODE) --flash_size $(ESP_SIZE) \
									0x00000 $(OTA_BOOTLOADER_PATH)\
									$(BIN_ADDRESS_1) $(OUTPUT_1) \
									$(BIN_ADDRESS_2) $(OUTPUT_2) \
									$(ESP_INIT_DATA_DEFAULT_ADDR) $(SDK_BASE)/bin/esp_init_data_default.bin


vpath %.c $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS)  -c $$< -o $$@
endef



.PHONY: all lib checkdirs clean

all: touch checkdirs $(OUTPUT_1) $(OUTPUT_2)

lib: checkdirs $(OUTPUT_LIB)

touch:
	$(vecho) "-------------------------------------------\n"
	$(vecho) "BUID TIME $(DATETIME)"
	$(vecho) "-------------------------------------------\n"
	$(Q) touch user/user_main.c

checkdirs: $(BUILD_DIR) $(FIRMWARE_BASE)

$(OUTPUT_1): $(TARGET_OUT_1)
	$(vecho) "FW $@"
	$(Q) $(ESPTOOL) elf2image $(ESPTOOL_FLASHDEF) $< -o $@

$(OUTPUT_2): $(TARGET_OUT_1)
	$(vecho) "FW $@"
	$(vecho) "FW $<"
	$(Q) $(ESPTOOL) elf2image $(ESPTOOL_FLASHDEF) $< -o $@

$(OUTPUT_LIB): $(OBJ_LIB)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

$(BUILD_DIR):
	$(Q) mkdir -p $@

$(FIRMWARE_BASE):
	$(Q) mkdir -p $@

$(TARGET_OUT_1): $(APP_AR)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT_1) $(LDFLAGS) -Wl,--start-group $(SDK_LIBS) $(APP_AR) -Wl,--end-group -o $@

$(TARGET_OUT_2): $(APP_AR)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT_2) $(LDFLAGS) -Wl,--start-group $(SDK_LIBS) $(APP_AR) -Wl,--end-group -o $@

$(APP_AR): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

flash:
	$(ESPTOOL) $(ESPTOOL_OPTS) $(ESPTOOL_WRITE)

fast: clean all flash openport

openport:
	$(vecho) "After flash, terminal will enter serial port screen"
	$(vecho) "Please exit with command:"
	$(vecho) "\033[0;31m" "Ctrl + A + k" "\033[0m"

	#@read -p "Press any key to continue... " -n1 -s
	@screen $(ESPPORT) 115200

clean:
	$(Q) rm -rf $(BUILD_BASE)
	$(Q) rm -rf $(FIRMWARE_BASE)
$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))