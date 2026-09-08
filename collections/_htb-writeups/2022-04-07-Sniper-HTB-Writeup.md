---
title: "Sniper - HTB Writeup"
header: 
  teaser: /assets/images/2022-04-07-Sniper-HTB-Writeup/Sniper-HTB-Image.png
  header: /assets/images/2022-04-07-Sniper-HTB-Writeup/Sniper-HTB-Image.png
  og_image: /assets/images/2022-04-07-Sniper-HTB-Writeup/Sniper-HTB-Image.png
excerpt: "The `lang` parameter on the /blog/ endpoint is vulnerable to local file inclusion. The curl request below shows the basic local file inclusion of the win.ini file on the target server."
tags: [htb, writeup, sniper]
---
## Sniper

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135015.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135027.png)

#### Nmap Full Sport Scan

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135054.png)

#### Nmap Vulnerability Scan

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135121.png)

### Service Enumeration

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135140.png)

#### FFuF Web Enumeration on Port 80

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135158.png)

#### Nmap SMB Scan

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135218.png)

#### HTTP Service Enumeration

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_135458.png)

#### Gobuster Web Enumeration

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_144849.png)

#### /blog Web Endpoint

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_144940_1.png)

#### User Account Registration

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_151809.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_151832.png)

### Penetration

#### Local File Inclusion - Lang Parameter

The `lang` parameter on the /blog/ endpoint is vulnerable to local file inclusion. The curl request below shows the basic local file inclusion of the win.ini file on the target server.

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_151623.png)

#### Remote File Inclusion over SMB

After testing local file inclusion we can attempt to utilize an SMB path starting with \\\\ and then our attacking machine IP. Standing up a basic SMB server using the Impacket Python library allows us to confirm the connectivity on the back end. The Impacket library server does not appear to be fully functioning but settings up an SMB share on the attacking Kali machine will allow us to use the RFI vulnerability against the full SMB server. Creating a reverse shell is documented below.

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_155047.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_155224.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_163919.png)

#### iusr User Shell Enumeration

Once remote code execution is achieved and a reverse shell can be easily spawned by copying nc64.exe onto the box and then executing the reverse shell command.

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_164013.png)

### Privilege Escalation

#### SQL Credentials in db.php

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_164141.png)

#### Chris User Shell

The Chris user is the only other interactive user on the target machine. Using the stolen MySQL credentials to create a PowerShell command we can run our reverse shell as the Chris user.

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_164453.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_164512.png)

#### Chris User Shell Enumeration

It appears that C:\\Docs is being used to discuss documentation on a new PHP project and they are expecting files to be placed there so that they can be read. After placing our CHM file in our downloads folder here we can see that it is read and deleted.

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_165220.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_165132.png)

#### Crafting Malicious CHM File

Because this CHM file is being opened and deleted we can craft a malicious file to be read by the end user. A tool has been created to do just that called Out-CHM.ps1 by Nishang. Below illustrates the steps for successful exploitation. A second Windows VM was used to compile the particular file.

<http://web.archive.org/web/20160201063255/http://download.microsoft.com/download/0/A/9/0A939EF6-E31C-430F-A3DF-DFAE7960D564/htmlhelp.exe>

<https://github.com/samratashok/nishang/blob/master/Client/Out-CHM.ps1>

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_202234.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_202244.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_203019.png)

#### Administrator User Shell

By mounting the attacking machine SMB share using net use we can easily access files on the attacking server from the compromised user shell. Simply copying files off of this share to the C:\\Docs location and waiting will return a user shell as the NT AUTHORITY\\SYSTEM user, allowing for infinite control over the target system.

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_203427.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_203606.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_203542.png)

![Screenshot](/assets/images/2022-04-07-Sniper-HTB-Writeup/Screenshot_20220404_203625.png)
