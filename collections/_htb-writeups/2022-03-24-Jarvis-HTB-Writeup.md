---
title: "Jarvis - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-24-Jarvis-HTB-Writeup/Jarvis-HTB-Image.png
  header: /assets/images/2022-03-24-Jarvis-HTB-Writeup/Jarvis-HTB-Image.png
  og_image: /assets/images/2022-03-24-Jarvis-HTB-Writeup/Jarvis-HTB-Image.png
excerpt: "The SQL parameter that is used to load bedroom options on the site appears to be SQL injectable. The service simply shows the room number and then renders the price on the form. Moving this request to SQLmap allows us to automate SQL injection and exploitation. After a quick scan, it is confirmed that the parameter is SQL injectable and the method is shown on the screen."
tags: [htb, writeup, jarvis]
---
## Jarvis

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210240.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210246.png)

#### Nmap Full Scan

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210301.png)

### Service Enumeration

#### Nikto Web Scan on port 64999

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210327.png)

#### FFuF Web Enumeration on Port 64999

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210346.png)

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210403.png)

#### FFuF Web Scan on Port 80

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210418.png)

#### Apache Web Enumeration on Port 80

`supersecurehotel.htb`

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210532.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210644.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210656.png)

### Penetration

#### SQL Parameter Injection

The SQL parameter that is used to load bedroom options on the site appears to be SQL injectable. The service simply shows the room number and then renders the price on the form. Moving this request to SQLmap allows us to automate SQL injection and exploitation. After a quick scan, it is confirmed that the parameter is SQL injectable and the method is shown on the screen.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210724.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_210913.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_211012.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_211120.png)

#### SQL Injection Load File

Further enumeration by hand shows that the database service is confirmed to load files from the server. Below shows the rendering /etc/passwd through the load_file method.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_211225.png)

#### SQL Injection Write Backdoor

Using the file system read/write access that SQL has on the target server allows us to create our PHP backdoor file on the web service.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_211740.png)

#### Reverse Shell as www-data User

By utilizing the installed backdoor we can break into the target machine and spawn a reverse shell as the www-data user.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_211902.png)

#### Shell Upgrade

Performing a standard UNIX shell upgrade in Netcat provides a stable and usable shell on the target system as the www-data user.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_212013.png)

### Privilege Escalation

#### www-data Sudo Permissions

The www-data user has non-standard sudo permissions on the target server that allow it to run the simpler.py Python script as the pepper user.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_212039.png)

#### simpler.py Exploitation

The script does show attempts of stopping injection but the $ isn't blocked. Trying to use environment variables appears to work as the ping command will replace the input with the 'whoami' output as shown below. We can substitute a script here and get a reverse shell as the target user. Creating a basic reverse shell in /tmp and feeding it into this script's sudo session allows us to spawn a reverse shell as the pepper user.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_212343.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_212551.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_212557.png)

#### Pepper User Shell

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_213219.png)

#### SUID Binary Enumeration

The pepper user has access to a SUID binary on the target machine. The /bin/systemctl binary will run as root on the target machine whenever the pepper user runs it.

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_213025.png)

#### Systemctl SUID Binary Exploitation

The /bin/systemctl binary is a 'GTFO Bin' as linked below. Because of this, it is trivial to escalate privileges and spawn a reverse shell as the root user.

<https://gtfobins.github.io/gtfobins/systemctl/#suid>

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_214134.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_214417.png)

![Screenshot](/assets/images/2022-03-24-Jarvis-HTB-Writeup/Screenshot_20220324_214439.png)
