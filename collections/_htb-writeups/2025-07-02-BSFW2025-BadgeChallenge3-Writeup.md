---
title: "BSides Fort Wayne 2025 Conference - Badge Challenge 3 Writeup"
header: 
  teaser: /assets/images/
  header: /assets/images/
  og_image: /assets/images/
excerpt: "The 2025 Fort Wayne BSides badge was used in the CTF for another challenge called 'Blinky Lights'. This was another challenge created as a medium difficutly challenge. The intention is to create a challenge where the user needs to write their own app on the badge that will interact with the hidden C code."
tags: [bsides, writeup, badge, challenge]
---
## BSides Fort Wayne 2025 CTF - Blinky Lights

The 2025 Fort Wayne BSides badge was used in the CTF for another challenge called "Blinky Lights". This was another challenge created as a medium difficutly challenge. The intention is to create a challenge where the user needs to write their own app on the badge that will interact with the hidden C code. We have developed a small app for the badge that should help the user understand how the library is being used.

#### Challenge Code

Below is the challlenge code, created to provide a hint on this challenge. You can see that the app simply runs through a while loop with a counter starting at 0 and then incrementing up each time it runs. Each time it's ran the counter is fed into the challenge C code and integers are returned which are then used to turn LEDs on and off. 

[/apps/badgechal3.py](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/src/apps/badgechal3.py)

```python
from lib.smart_config import Config
from icontroller import IController
import badgechal
from apps.app import BaseApp
import vga1_bold_16x32
import time
import neopixel
import micropython
from machine import Pin
import _thread

class BadgeChal3(BaseApp):
    name = "CTF Challenge 3"
    def __init__(self, controller):
        super().__init__(controller)
        self.controller = controller
        self.display1 = self.controller.bsp.displays.display1
        self.display2 = self.controller.bsp.displays.display2
        self.running = False
        self.NUM_LEDS = 7
        PIN_NUM = 26
        self.np = neopixel.NeoPixel(Pin(PIN_NUM), self.NUM_LEDS)

    async def teardown(self):
        self.running = False
        # Turn off all LEDs
        
        self.np.fill((0, 0, 0))
        
        self.np.write()
    
    async def setup(self):
        self.display1.text(vga1_bold_16x32, "Blinky", 70, 100)
        self.display2.text(vga1_bold_16x32, "Lights", 70, 100)
        print("Running Badge Challenge 3")
        _thread.start_new_thread(self.challenge, ())
    
    def challenge(self):
        pos = 0
        self.running = True
        while self.running:
            try:
                # Setup 7 WS2812B LEDs on GPIO 5
                
                bits = badgechal.chal3(pos)
                for i in range(self.NUM_LEDS):
                    if bits[i] == '1':
                        self.np[i] = (0, 0, 10)  # Blue for '1'
                    else:
                        self.np[i] = (0, 0, 0)    # Off for '0'
                self.np.write()
                time.sleep(1)
                pos += 1
            except ValueError as e:    
                break
        time.sleep(1)
        for i in range(self.NUM_LEDS):
            self.np[i] = (0, 0, 0)    # Off for '0'
        self.np.write()
        time.sleep(0.2)
        for i in range(self.NUM_LEDS):
            self.np[i] = (0, 0, 10)  # Blue for '1'
        self.np.write()
        time.sleep(0.2)
        for i in range(self.NUM_LEDS):
            self.np[i] = (0, 0, 0)    # Off for '0'
        self.np.write()
        time.sleep(0.2)
        for i in range(self.NUM_LEDS):
            self.np[i] = (0, 0, 10)  # Blue for '1'
        self.np.write()
        time.sleep(0.2)
        for i in range(self.NUM_LEDS):
            self.np[i] = (0, 0, 0)    # Off for '0'
        self.np.write()
```

#### Solve Code

The first step in investigating this challenge starts with learning what the C code is returning to the user when it is ran. We can start on the REPL interface of the badge and figure out what that output looks like. Below is what happens when we try different integers as parameters into the challenge code.

```python
>>> import badgechal
>>> badgechal.chal3(2)
'1100110'
>>> badgechal.chal3(0)
'1100010'
>>> badgechal.chal3(32)
'1000111'
```

From here a light bulb should click on. It's obvious that the C code is just returning binary based on the integer provided. These 7 bits of binary are used to determine which lights are on and off. The challenge app simply iterates from 0 until a ValueError is returned, meaning we ran out of results to be returned. Let's programatically iterate through the list and decode the binary instead of displaying it out to the LEDs.

```python
import badgechal

pos = 0
flag = ""
while True:
    try:
        bits = badgechal.chal3(pos)
        ch = chr(int(bits, 2))
        flag += ch
        pos += 1
    except ValueError as e:
        print(flag)
        break
```

As we decrypt each binary set, we reveal the characters in the flag. If a user wanted to decode the binary by hand by looking at the lights they could but the simple script above should dump out the flag as well.

```shell
λ archlaptop BadgeFirmware → λ git main* → uv run mpremote run solves/chal3_solve.py
bsftw{RH0R8N2YCBY91L44KQZF6M64RFGIR8K2}
```

#### C Challenge Code - Compiled into MicroPython

The C code for this challenge is fairly simple. We still store an encoded version of the flag so it is not able to be found with strings, and then we XOR decrypt it in memory. With the full flag string in hand, we can simply use the supplied index parameter to pick the correct character in the string. The character is converted into binary and that set of numbers is what is returned.

```cpp
extern "C" {
#include <stdio.h>
#include <ctype.h>
#include "py/obj.h"
#include "py/runtime.h"
#include "py/mphal.h"
#include "driver/ledc.h"
}

// Challenge 3 - LED Bit Decoding
extern "C" mp_obj_t badgechal_chal3_func(mp_obj_t flag_pos) {
    
    // mp_printf(&mp_plat_print, "bsftw{RH0R8N2YCBY91L44KQZF6M64RFGIR8K2}\n");
    // XOR-decode and print flag
    uint8_t encoded_flag[] = {
        72, 89, 76, 94, 93, 81, 120, 98, 26, 120, 18, 100, 24, 115, 105, 104, 115, 19, 27, 102, 30, 30, 97, 123, 112, 108, 28, 103, 28, 30, 120, 108, 109, 99, 120, 18, 97, 24, 87
    };
    size_t flag_len = sizeof(encoded_flag);
    char decoded_flag[flag_len + 1];

    for (size_t i = 0; i < flag_len; i++) {
        decoded_flag[i] = encoded_flag[i] ^ 0x2A;
    }
    decoded_flag[flag_len] = '\0';

    // Convert input to integer
    mp_int_t index = mp_obj_get_int(flag_pos);
    
    if (index < 0 || index >= strlen(decoded_flag)) {
        mp_raise_ValueError(MP_ERROR_TEXT("Index out of range"));
    }

    char ch = decoded_flag[index];
    uint8_t masked = ch & 0x7F;

    // Convert to 7-bit binary string
    char bin_str[8]; // 7 bits + null terminator
    for (int i = 6; i >= 0; i--) {
        bin_str[6 - i] = ((masked >> i) & 1) ? '1' : '0';
    }
    bin_str[7] = '\0';

    return mp_obj_new_str(bin_str, 7);  // Return as Python string
}
// Create MicroPython object from the function
extern "C" MP_DEFINE_CONST_FUN_OBJ_1(badgechal_chal3_obj, badgechal_chal3_func);

// All of the MicroPython implemention stuff to get the library to work
// Module globals table
extern "C" const mp_rom_map_elem_t badgechal_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR___name__), MP_ROM_QSTR(MP_QSTR_badgechal) },
    { MP_ROM_QSTR(MP_QSTR_chal3), MP_ROM_PTR(&badgechal_chal3_obj) },
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
