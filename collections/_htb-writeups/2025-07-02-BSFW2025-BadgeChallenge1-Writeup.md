---
title: "BSides Fort Wayne 2025 Conference - Badge Challenge 1 Writeup"
header: 
  teaser: /assets/images/
  header: /assets/images/
  og_image: /assets/images/
excerpt: "Challenge 1 hidden inside of the Fort Wayne BSides 2025 Badge was a scripting challenge involving the serial UART port on the device. It is expected that the user connects to the serial port presented by the badge to their laptop."
tags: [bsides, writeup, badge, challenge]
---
## BSides Fort Wayne 2025 CTF - Solve the Problem

Challenge 1 hidden inside of the Fort Wayne BSides 2025 Badge was a scripting challenge involving the serial UART port on the device. It is expected that the user connects to the serial port presented by the badge to their laptop. This would be the standard way of interacting with the badge through tools such as `mpremote`. Instructions on how to connect to the serial port with `mpremote` can be found in the badge [firmware repository](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/README.md)

Once the user connects to the serial port and they run challenge 1 on the badge they are presented with the words "You Art?" on the screens. This is supposed to be a hint to connect to the UART port. If you're connected then you will see the serial port taken over by the custom C code. The user will be presented with the following:

```
[1/100] 1 + 14 = ?                     
The answer is:
```

If you so wish you can simply enter the correct answer to this math problem and you will be presented another one and the counter will increment. If an incorrect answer is submitted the entire counter will reset.

#### Solve Code

In order to solve this challenge in any reasonable amount of time a Python script will need to be developed to systematically process and solve these problems from the serial port and send the correct answer.

My example of this solve code is shown below. It initializes the serial port on `/dev/ttyUSB0` and then send newlines until it processes a `/` in the line (indicating that the line is probably a math equation). From there it will split the line after a bracket and then before the `=`. After that we can split on spaces and actually process out the three parts of the math problem. A simple case statement is used to actually process an answer and send it out the serial port back to the badge. We have to make sure to print out anything that we see on the serial port in case a flag comes across.

```python
import serial
import time

try:
    serialPort = serial.Serial(
        port="/dev/ttyUSB0", baudrate=115200, bytesize=8, timeout=0, stopbits=serial.STOPBITS_ONE
    )
except:
    print("Unable to open serial port! Exiting...")
    exit()

serialString = ""  # Used to hold data coming over UART
serialPort.write('\n'.encode('utf-8'))

while True:
    try:
        # Read data out of the buffer until a carraige return / new line is found
        serialString = serialPort.readline()

        # Print the contents of the serial data
        try:
            # If statement to evaluate and solve math problem
            if "/" in serialString.decode():
                print(serialString.decode("Ascii"), end="")
                math_eq = serialString.decode("Ascii").split("] ", 1)[1].rsplit("=", 1)[0]
                first_num = math_eq.split(" ", 1)[0]
                op_symbol = math_eq.split(" ", 2)[1]
                second_num = math_eq.split(" ", 2)[2]
                match op_symbol:
                    case "+":
                        answer = int(first_num) + int(second_num)
                    case "-":
                        answer = int(first_num) - int(second_num)
                    case "*":
                        answer = int(first_num) * int(second_num)
                print("The answer is: " + str(answer))
                serialPort.write((str(answer)+'\n').encode('utf-8'))
            elif "bsftw" in serialString.decode("Ascii"):
                print("Hey this looks like a flag!!!")
                print(serialString.decode("Ascii"), end="")
                print("Exiting...")
                break
            time.sleep(0.1)
        except KeyboardInterrupt:
            print("Keyboard Interrupt! Exiting...")
            exit()
        except:
           serialPort.write('\n'.encode('utf-8'))

    except KeyboardInterrupt:
        print("Keyboard Interrupt! Exiting...")
        exit()
```

Upon running this code, this is the expected output:

```bash
λ archlaptop BadgeFirmware → λ git main* → python solves/chal1_solve.py                                                
[1/100] 1 + 14 = ?                     
The answer is: 15                        
> [2/100] 3 + 10 = ?  
The answer is: 13                                                                                                      
> [3/100] 9 + 13 = ?
The answer is: 22
### SNIP ###
> [98/100] 15 + 11 = ?
The answer is: 26
> [99/100] 6 + 19 = ?
The answer is: 25
> [100/100] 2 * 10 = ?
The answer is: 20
Hey this looks like a flag!!!
> bsftw{n0FDpMkSTtNsql7kkIgNtrDCYWHPAM3L}
Exiting...
```

#### Challenge Code

The code for the challenge 1 app can be found in the [badge repo](<https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/src/apps/badgechal1.py)

This is a super simple app that just blanks and displays words to the LCD screens. Once it has been initialized it will run `badgechal.chal1()` which starts the C code.

```python
import badgechal
from apps.app import BaseApp

class BadgeChal1(BaseApp):
    name = "CTF Challenge 1"
    def __init__(self, controller):
        super().__init__(controller)
        self.controller = controller
        self.display1 = self.controller.bsp.displays.display1
        self.display2 = self.controller.bsp.displays.display2
        self.display_center_text = self.controller.bsp.displays.display_center_text
        self.display_text = self.controller.bsp.displays.display_text

    async def setup(self):
        self.display_center_text("You Art?")
        print("Running Badge Challenge 1")
        # TODO This is intentionally blocking for the sake of the CTF...
        badgechal.chal1()
        return None
```

#### C Challenge Code - Compiled into MicroPython

Here is the code in the C user module that is compiled into the MicroPython binary. This code is not revealed to the users. The flag is encoded with an XOR rule in order to make it more difficult to reverse. The chal1 function is just a simple random math question generator that will print out to the serial port. This pretty much takes over the entire device.

```cpp
extern "C" {
#include <stdio.h>
#include <ctype.h>
#include "py/obj.h"
#include "py/runtime.h"
}

// Badge Challenge 1 - Solve the Math Problems
extern "C" mp_obj_t badgechal_chal1_func(void) {
    int correct_count = 0;
    const int goal = 100;
    srand((unsigned)time(NULL));

    mp_printf(&mp_plat_print, "Solve 100 math problems in a row. One mistake resets you.\n");

    while (correct_count < goal) {
        int a = rand() % 20 + 1;
        int b = rand() % 20 + 1;
        int op = rand() % 3;
        int answer;
        char question[32];

        switch (op) {
            case 0:
                answer = a + b;
                snprintf(question, sizeof(question), "%d + %d = ?", a, b);
                break;
            case 1:
                answer = a - b;
                snprintf(question, sizeof(question), "%d - %d = ?", a, b);
                break;
            case 2:
                answer = a * b;
                snprintf(question, sizeof(question), "%d * %d = ?", a, b);
                break;
        }

        mp_printf(&mp_plat_print, "[%d/%d] %s\n> ", correct_count + 1, goal, question);

        // Use sys.stdin.readline() for UART-safe input
        mp_obj_t sys_module = mp_import_name(MP_QSTR_sys, mp_const_none, MP_OBJ_NEW_SMALL_INT(0));
        mp_obj_t stdin_obj = mp_load_attr(sys_module, MP_QSTR_stdin);
        mp_obj_t readline_meth = mp_load_attr(stdin_obj, MP_QSTR_readline);
        mp_obj_t line_obj;

        // Call readline with exception handling
        nlr_buf_t nlr;
        const char *line;
        if (nlr_push(&nlr) == 0) {
            line_obj = mp_call_function_0(readline_meth);
            line = mp_obj_str_get_str(line_obj);
            nlr_pop();
        } else {
            mp_printf(&mp_plat_print, "Input error. Starting over.\n\n");
            correct_count = 0;
            continue;
        }

        // Parse string to int
        char *endptr;
        int user_ans = strtol(line, &endptr, 10);
        if (*endptr != '\0' && *endptr != '\n') {
            mp_printf(&mp_plat_print, "Invalid input. Starting over.\n\n");
            correct_count = 0;
            continue;
        }

        if (user_ans == answer) {
            correct_count++;
        } else {
            mp_printf(&mp_plat_print, "Wrong! Starting over.\n\n");
            correct_count = 0;
        }
    }

    // mp_printf(&mp_plat_print, "bsftw{n0FDpMkSTtNsql7kkIgNtrDCYWHPAM3L}\n");
    // XOR-decode and print flag
    uint8_t encoded_flag[] = {
        72, 89, 76, 94, 93, 81, 68, 26, 108, 110, 90, 103, 65, 121, 126, 94, 100, 89, 91, 70, 29, 65, 65, 99, 77, 100, 94, 88, 110, 105, 115, 125, 98, 122, 107, 103, 25, 102, 87
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
extern "C" MP_DEFINE_CONST_FUN_OBJ_0(badgechal_chal1_obj, badgechal_chal1_func);

// Module globals table
extern "C" const mp_rom_map_elem_t badgechal_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR___name__), MP_ROM_QSTR(MP_QSTR_badgechal) },
    { MP_ROM_QSTR(MP_QSTR_chal1), MP_ROM_PTR(&badgechal_chal1_obj) },
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
