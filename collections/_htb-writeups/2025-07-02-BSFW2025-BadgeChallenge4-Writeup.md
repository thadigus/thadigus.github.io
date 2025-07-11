---
title: "BSides Fort Wayne 2025 Conference - Badge Challenge 4 Writeup"
header: 
  teaser: /assets/images/
  header: /assets/images/
  og_image: /assets/images/
excerpt: "Badge challenge number 4 was the challenge to seriously differentiate the contenders that would perform well on the badge challenges. This challenge was not actually solved at any point, so I'm happy to provide my solution here. An app was placed on the badges that would start `badgechal.chal4()` as a thread and during execution it would also monitor a global variable. The user would see the badge begin to flash lights and start beeping out morse code."
tags: [bsides, writeup, badge, challenge, morse, code]
---
## BSides Fort Wayne 2025 CTF - Beeping Badges

Badge challenge number 4 was the challenge to seriously differentiate the contenders that would perform well on the badge challenges. This challenge was not actually solved at any point, so I'm happy to provide my solution here. An app was placed on the badges that would start `badgechal.chal4()` as a thread and during execution it would also monitor a global variable. The user would see the badge begin to flash lights and start beeping out morse code. For those quick enough with morse, one could decrypt this into the flag, but a more tractful solution existed.

#### Challenge Code

Below is the challenge code on the device. We start by blanking the displays, displaying the text "Beeping Badges", and then starting up a NeoPixel instance with the LEDs. Upon launching the app two threads are started. The `badgechal.chal4()` thread is started and then the `led_sync` thread as well. The C code for challenge 4 is hidden, but we can see that the LED sync code is just a simple script that is constantly checking the `buzzer_state` variable and flashing the LEDs when it is true. Additionally, the badge starts beeping, but there is no buzzer code in this app, so we know that the beeping is coming from the C code. The application simply starts the buzzer code, and then monitors a global variable in the background to tell teh LEDs when to turn on and off, so they match the morse beeping.

[/apps/badgechal4.py](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/src/apps/badgechal4.py)

```python
from lib.smart_config import Config
from icontroller import IController
import badgechal
from apps.app import BaseApp
import vga1_bold_16x32
import _thread, time
import machine, neopixel

class BadgeChal4(BaseApp):
    name = "CTF Challenge 4"
    def __init__(self, controller):
        super().__init__(controller)
        self.controller = controller
        self.display1 = self.controller.bsp.displays.display1
        self.display2 = self.controller.bsp.displays.display2
        self.np = neopixel.NeoPixel(machine.Pin(26), 7)
        self.running_threads = []
        self.running = False

    # LED thread
    def led_sync(self):
        print("[*] LED sync started")
        np = self.np
        while self.running:
            if badgechal.buzzer_state():
                np.fill((0, 0, 10))  # dim blue
            else:
                np.fill((0, 0, 0))
            np.write()
            time.sleep(0.01)  # Check every 10ms

    # Buzzer thread
    def start_challenge(self):
        print("[*] Starting chal4")
        badgechal.chal4()
        print("[*] chal4 complete")

    async def teardown(self):
        self.running = True
        self.np.fill((0, 0, 0))  # Turn off LEDs
        self.np.write()

    async def setup(self):
        self.running = True
        self.display1.text(vga1_bold_16x32, "Beeping", 70, 100)
        self.display2.text(vga1_bold_16x32, "Badges", 70, 100)
        print("Running Badge Challenge 4")
        # Start both threads
        _thread.start_new_thread(self.led_sync, ())
        _thread.start_new_thread(self.start_challenge, ())
        return None
```

#### Solve Code

The solve code for this challenge can actually be generated mostly with ChatGPT. We already have a fairly simple example of code to import the challenge code, start up the beeping thread, and then actively monitor the buzzer state for LED syncing. Instead we can modify that code to decrypt the morse code using the buzzer state variable. The code below is a working example of this. We had to tweak the timing quite a bit but once you get the thread timing correct, it would properly decode the morse challenge as it beeped out the characters.

```python
import _thread
import time
from badgechal import chal4, buzzer_state

# Morse code lookup
morse_dict = {
    '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
    '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
    '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
    '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
    '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
    '--..': 'Z', '-----': '0', '.----': '1', '..---': '2',
    '...--': '3', '....-': '4', '.....': '5', '-....': '6',
    '--...': '7', '---..': '8', '----.': '9'
}

# Timing constants
SAMPLE_INTERVAL = 0.009
DOT_DASH_THRESHOLD = 0.1
CHAR_GAP_THRESHOLD = 0.2
WORD_GAP_THRESHOLD = 0.6

# Launch chal4 in background
_thread.start_new_thread(chal4, ())

print("[*] chal4() running in background")
print("[*] Starting Morse decoder")

# Run decoder on main thread
current_symbol = ""
decoded_message = ""
last_state = False
last_change = time.ticks_ms()
last_activity = time.ticks_ms()

try:
    while True:
        state = buzzer_state()
        now = time.ticks_ms()
        delta = time.ticks_diff(now, last_change) / 1000.0  # in seconds

        if state != last_state:
            last_change = now
            last_activity = now

            if state:  # Buzzer just turned on
                if delta >= WORD_GAP_THRESHOLD:
                    if current_symbol:
                        decoded_message += morse_dict.get(current_symbol, '?')
                        current_symbol = ""
                    decoded_message += " "
                elif delta >= CHAR_GAP_THRESHOLD:
                    if current_symbol:
                        decoded_message += morse_dict.get(current_symbol, '?')
                        current_symbol = ""

            else:  # Buzzer just turned off
                if delta >= DOT_DASH_THRESHOLD:
                    current_symbol += "-"
                else:
                    current_symbol += "."

            print(f"[+] Decoding: {decoded_message}{current_symbol}")

        last_state = state
        time.sleep(SAMPLE_INTERVAL)

        # Auto-exit after 2 seconds of silence
        if not state and time.ticks_diff(now, last_activity) > 2000:
            if current_symbol:
                decoded_message += morse_dict.get(current_symbol, '?')
                current_symbol = ""
            break

except KeyboardInterrupt:
    print("\n[!] Stopped decoding manually")

# Final result
print("\n[✓] Decoded message:")
print(decoded_message.strip())
print("bsftw{" + decoded_message.strip()[5:] + "}")
```

In order to prove that this will work, here is a snipped example of what that code looks like when it runs. You can see the characters being beeped out, and eventually the characters are assembled to provide a flag.

```python
[*] chal4() running in background
[*] Starting Morse decoder
[+] Decoding: 
[+] Decoding: -
[+] Decoding: -
[+] Decoding: -.
[+] Decoding: -.
[+] Decoding: -..
[+] Decoding: -..
[+] Decoding: -...
[+] Decoding: B
[+] Decoding: B.
[+] Decoding: B.
[+] Decoding: B..
[+] Decoding: B..
[+] Decoding: B...
[+] Decoding: BS
[+] Decoding: BS.
### SNIP ###
[+] Decoding: BSFTWWTQSY91SCA4YX79P5KOO1NCZ3Q87V3U
[+] Decoding: BSFTWWTQSY91SCA4YX79P5KOO1NCZ3Q87V3U.
[+] Decoding: BSFTWWTQSY91SCA4YX79P5KOO1NCZ3Q87V3U.
[+] Decoding: BSFTWWTQSY91SCA4YX79P5KOO1NCZ3Q87V3U..

[✓] Decoded message:
BSFTWWTQSY91SCA4YX79P5KOO1NCZ3Q87V3UI
bsftw{WTQSY91SCA4YX79P5KOO1NCZ3Q87V3UI}
```

#### C Challenge Code - Compiled into MicroPython

The C code for this challenge took forever to write and much of this was helped along with ChatGPT. First, we define a static table for morse characters to map the dits and dahs to the correct letter. Then, during runtime, the flag is decoded from the XOR encoded we used to not allow for basic reversing, and each letter is beeped out one at a time. For each letter we find the corresponding dits and dahs from the table, and then the code uses a series of complicated timers to beep out the buzzer for the correct amount of time. Anytime the buzzer turns on or off, we update the global `buzzer_state` variable. Because of this, you can check that variable at any time to determine if the buzzer is making noise or not.

```cpp
extern "C" {
#include <stdio.h>
#include <ctype.h>
#include "py/obj.h"
#include "py/runtime.h"
#include "py/mphal.h"
#include "driver/ledc.h"
}

// Challenge 4 - Beeping Badges
// Constants
#define BUZZER_GPIO 15
#define TONE_HZ 700
#define WPM_UNIT_MS 10
// Morse code lookup table
const char *morse_table[36] = {
    ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..",  // A-I
    ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", // J-R
    "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--..",        // S-Z
    "-----", ".----", "..---", "...--", "....-", ".....", "-....", "--...", "---..", "----." // 0-9
};

// Setup PWM
extern "C" void buzzer_setup() {
    
    ledc_timer_config_t timer = {
        LEDC_HIGH_SPEED_MODE,
        LEDC_TIMER_10_BIT,
        LEDC_TIMER_0,
        TONE_HZ,
        LEDC_AUTO_CLK
    };
    ledc_timer_config(&timer);
    
    ledc_channel_config_t channel = {
        BUZZER_GPIO,
        LEDC_HIGH_SPEED_MODE,
        LEDC_CHANNEL_0,
        LEDC_INTR_DISABLE,
        LEDC_TIMER_0,
        0,
        0
    };
    ledc_channel_config(&channel);
}

volatile bool buzzer_active = false;

extern "C" void buzzer_on() {
    buzzer_active = true;
    ledc_set_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0, 512); // 50%
    ledc_update_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0);
}

extern "C" void buzzer_off() {
    buzzer_active = false;
    ledc_set_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0, 0);
    ledc_update_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0);
}

// Expose to MicroPython
extern "C" mp_obj_t badgechal_buzzer_state(void) {
    return mp_obj_new_bool(buzzer_active);
}

extern "C" void delay_ms(int ms) {
    for (int i = 0; i < ms; i++) {
        mp_hal_delay_ms(1);  // This yields to the scheduler
    }
}

extern "C" void play_symbol(char symbol) {
    if (symbol == '.') {
        buzzer_on();
        delay_ms(WPM_UNIT_MS);
        buzzer_off();
    } else if (symbol == '-') {
        buzzer_on();
        delay_ms(WPM_UNIT_MS * 3);
        buzzer_off();
    }
    delay_ms(WPM_UNIT_MS); // Inter-symbol space
}

extern "C" void play_morse(const char *text) {
    buzzer_setup();

    for (int i = 0; text[i]; ++i) {
        char c = toupper((unsigned char)text[i]);
        if (c >= 'A' && c <= 'Z') {
            const char *morse = morse_table[c - 'A'];
            for (int j = 0; morse[j]; ++j) {
                play_symbol(morse[j]);
            }
            delay_ms(WPM_UNIT_MS * 2); // 3-unit space between characters (1 already done)
        } else if (c >= '0' && c <= '9') {
            const char *morse = morse_table[c - '0' + 26];
            for (int j = 0; morse[j]; ++j) {
                play_symbol(morse[j]);
            }
            delay_ms(WPM_UNIT_MS * 2);
        } else if (c == ' ') {
            delay_ms(WPM_UNIT_MS * 4); // 7-unit word space (1 already done)
        }
        mp_hal_delay_ms(1);
    }
}

extern "C" mp_obj_t badgechal_chal4(void) {
    // mp_printf(&mp_plat_print, "bsftwWTQSY91SCA4YX79P5KOO1NCZ3Q87V3UI\n");
    // XOR-decode and print flag
    uint8_t encoded_flag[] = {
        72, 89, 76, 94, 93, 125, 126, 123, 121, 115, 19, 27, 121, 105, 107, 30, 115, 114, 29, 19, 122, 31, 97, 101, 101, 27, 100, 105, 112, 25, 123, 18, 29, 124, 25, 127, 99
    };
    size_t flag_len = sizeof(encoded_flag);
    char decoded_flag[flag_len + 1];

    for (size_t i = 0; i < flag_len; i++) {
        decoded_flag[i] = encoded_flag[i] ^ 0x2A;
    }
    decoded_flag[flag_len] = '\0';

    play_morse(decoded_flag);
    return mp_const_none;
}

extern "C" MP_DEFINE_CONST_FUN_OBJ_0(badgechal_chal4_obj, badgechal_chal4);
extern "C" MP_DEFINE_CONST_FUN_OBJ_0(badgechal_buzzer_state_obj, badgechal_buzzer_state);


// All of the MicroPython implemention stuff to get the library to work
// Module globals table
extern "C" const mp_rom_map_elem_t badgechal_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR___name__), MP_ROM_QSTR(MP_QSTR_badgechal) },
    { MP_ROM_QSTR(MP_QSTR_chal4), MP_ROM_PTR(&badgechal_chal4_obj) },
    { MP_ROM_QSTR(MP_QSTR_buzzer_state), MP_ROM_PTR(&badgechal_buzzer_state_obj) },
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
