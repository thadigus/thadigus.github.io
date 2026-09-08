---
title: "BSides Fort Wayne 2025 Conference - Badge Challenge 6 Writeup"
header: 
  teaser: /assets/images/
  header: /assets/images/
  og_image: /assets/images/
excerpt: "The first and most easy flag for the BSides Fort Wayne CTF badge category would be the simple enumeration step of looking in the public GitHub repo for the flag.txt. Additionally, this flag.txt is provided on every single device handed out. Simply breaking out of the running program into the REPL interface and exploring around with the OS library is enough to find the flag."
tags: [bsides, writeup, badge]
---
## BSides Fort Wayne 2025 CTF - Badge Gimmie

The first and most easy flag for the BSides Fort Wayne CTF badge category would be the simple enumeration step of looking in the public GitHub repo for the flag.txt. Additionally, this flag.txt is provided on every single device handed out. Simply breaking out of the running program into the REPL interface and exploring around with the OS library is enough to find the flag.

The following repo was provided for the users the conference in case they needed to reference the [badge firmware](https://github.com/BSidesFortWayne/BSidesFW2025Badge/tree/main). From here you can find the `flag.txt` file that's inside of the `/src` located at the following:

[flag.txt](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/src/flag.txt)

#### Solve on the Badge Devie

Additionally, the users can find this flag quite easily completely offline. This `flag.txt` file was provided on every single badge that was given to the contestants. Below are the steps for breaking out in REPL and finding the flag:

```python
λ archlaptop BadgeFirmware → λ git main* → uv run mpremote 
Connected to MicroPython at /dev/ttyUSB0
Use Ctrl-] or Ctrl-x to exit this shell

>>> import os
>>> os.listdir()
['boot.py', 'flag.txt']
>>> file = open('flag.txt', 'r')
>>> file.readline()
'bsftw{zV7UKP9Upc74yF5nzPpajWIvjGdbX8c4}'
>>> 
```
