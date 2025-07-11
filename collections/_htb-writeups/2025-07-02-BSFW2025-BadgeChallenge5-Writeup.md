---
title: "BSides Fort Wayne 2025 Conference - Badge Challenge 5 Writeup"
header: 
  teaser: /assets/images/
  header: /assets/images/
  og_image: /assets/images/
excerpt: "The 2025 Fort Wayne BSides badge had another challenge that was intended to be relatively easy for anyone who was able to access the REPL interface, and poke around MicroPython instance. An undocumented method was added to the customer C code user module that contained the other badge challenge code. If a user was able to find this undocumented method they would be rewarded with a flag."
tags: [bsides, writeup, badge, challenge, enumeration]
---
## BSides Fort Wayne 2025 CTF - Documentation Struggles

The 2025 Fort Wayne BSides badge had another challenge that was intended to be relatively easy for anyone who was able to access the REPL interface, and poke around MicroPython instance. An undocumented method was added to the customer C code user module that contained the other badge challenge code. If a user was able to find this undocumented method they would be rewarded with a flag. This entire challenge was mainly about enumeration within the custom firmware.

#### Solve Process

In order to find the flag, a user would need to connect to the REPL interface. The suggested way to do this was in the actual badge firmware [Git Repo](https://github.com/BSidesFortWayne/BSidesFW2025Badge). Once they connected and used `CTRL C` to break out of the currently running code they would be prompted by MicroPython to look into the `help('modules')` command. The output would show the `badgechal` library which is non-standard and should stick out quite a bit. Importing the library and then running `dir(badgechal)` on it will show all of the available methods. Seeing `giveflag` as a method should stick out as well and if the user runs `badgechal.giveflag()` they are rewarded with said flag.

```python
Connected to MicroPython at /dev/ttyUSB0                                                                     
Use Ctrl-] or Ctrl-x to exit this shell                                                                      
Performing initial setup                                                                                     
MicroPython v1.26.0-preview.127.g7a55cb6b3 on 2025-05-19; Generic ESP32 module with SPIRAM with ESP32
Type "help()" for more information. 
>>> help('modules')
__main__          bluetooth         inisetup          ssl
_asyncio          btree             io                struct
_boot             builtins          json              sys
_espnow           cmath             machine           time
_onewire          collections       math              tls
_thread           cryptolib         micropython       uasyncio
_webrepl          deflate           mip/__init__      uctypes
aioespnow         dht               neopixel          umqtt/robust
apa106            ds18x20           network           umqtt/simple
array             errno             ntptime           upysh
asyncio/__init__  esp               onewire           urequests
asyncio/core      esp32             os                vfs
asyncio/event     espnow            platform          webrepl
asyncio/funcs     flashbdev         random            webrepl_setup
asyncio/lock      framebuf          re                websocket
asyncio/stream    gc                requests/__init__
badgechal         hashlib           select
binascii          heapq             socket
Plus any modules on the filesystem
>>> import badgechal
>>> dir(badgechal)
['__class__', '__name__', '__dict__', 'chal1', 'giveflag', 'hello']
>>> badgechal.giveflag()
bsftw{nhwruwaybeqsofrwzhepucizyeiffbia}
>>> 
```

#### C Challenge Code - Compiled into MicroPython

Of course, the C code for this challenge was quite simple. We stored the flag in an encoded format so that it wasn't easily found through simple reversing like the `strings` command. At runtime we had the XOR decoding process load the actual flag string into memory. Then the use of this function would simply print out the flag with a `mp_printf` function. Nothing super interesteing to see here.

```cpp
extern "C" {
#include <stdio.h>
#include <ctype.h>
#include "py/obj.h"
#include "py/runtime.h"
}

// Badge Challenge - Give Me the Flag
extern "C" mp_obj_t badgechal_giveflag_func(void) {
    //mp_printf(&mp_plat_print, "bsftw{nhwruwaybeqsofrwzhepucizyeiffbia}\n");
    // XOR-decode and print flag
    uint8_t encoded_flag[] = {
        72, 89, 76, 94, 93, 81, 68, 66, 93, 88, 95, 93, 75, 83, 72, 79, 91, 89, 69, 76, 88, 93, 80, 66, 79, 90, 95, 73, 67, 80, 83, 79, 67, 76, 76, 72, 67, 75, 87
    };
    size_t flag_len = sizeof(encoded_flag);
    char decoded_flag[flag_len + 1];

    for (size_t i = 0; i < flag_len; i++) {
        decoded_flag[i] = encoded_flag[i] ^ 0x2A;
    }
    decoded_flag[flag_len] = '\0';

    mp_printf(&mp_plat_print, "%s\n", decoded_flag);
    return mp_const_none;
}
extern "C" MP_DEFINE_CONST_FUN_OBJ_0(badgechal_giveflag_obj, badgechal_giveflag_func);

// All of the MicroPython implemention stuff to get the library to work
// Module globals table
extern "C" const mp_rom_map_elem_t badgechal_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR___name__), MP_ROM_QSTR(MP_QSTR_badgechal) },
    { MP_ROM_QSTR(MP_QSTR_giveflag), MP_ROM_PTR(&badgechal_giveflag_obj) },
};

// Create the global dictionary
extern "C" MP_DEFINE_CONST_DICT(badgechal_module_globals, badgechal_module_globals_table);

// Define the module object
extern "C" const mp_obj_module_t badgechal_user_cmodule = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t *)&badgechal_module_globals,
};

// Register the module with MicroPython
MP_REGISTER_MODULE(MP_QSTR_badgechal, badgechal_user_cmodule);
```