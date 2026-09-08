---
title: "FluxCapacitor - HTB Writeup"
header: 
  teaser: /assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/FluxCapacitor-HTB-Image.png
  header: /assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/FluxCapacitor-HTB-Image.png
  og_image: /assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/FluxCapacitor-HTB-Image.png
excerpt: "FluxCapacitor is a web server hosting a web application firewall called SuperWAF on port 80. This service is vulnerable to remote code execution and can create a reverse shell as the web service user. The web service user has a privilege escalation vector to root due to sudo permissions."
tags: [htb, writeup, fluxcapacitor]
---
## FluxCapacitor - High Level Summary

FluxCapacitor is a web server hosting a web application firewall called SuperWAF on port 80. This service is vulnerable to remote code execution and can create a reverse shell as the web service user. The web service user has a privilege escalation vector to root due to sudo permissions.

### Recommendations

- Update SuperWAF or replace with a service that isn't vulnerable.

- Audit sudo permissions.

---

## FluxCapacitor - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a basic port scan on the target. The only port that is found is the standard web port 80. The HTTP service returns a header with a title of SuperWAF indicating that this is a Web Application Firewall.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_215551.png)

#### FFuF Directory Enumeration

FFuF fuzzes directories on the server and returns a few pages, most of which either have 19 characters or 395 which indicates that they are routing to an error page.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_215620.png)

#### Gobuster Directory Enumeration

[Gobuster](https://github.com/OJ/gobuster) is a more advanced tool for directory enumeration. Using a better word list allows attackers to find a detailed list of the pages on the server. This also returns PHP pages which means that the server has PHP installed it can render PHP pages.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_223534.png)

### Service Enumeration

#### Web Service

Connecting to the web service through Firefox results in a page with no functionality.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_213457.png)

#### /sync Page

Visiting the /sync page through Firefox returns a 403 forbidden page, and this appears to be the result no matter what action is taken against the site.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_215753.png)

Curling returns what appears to be a timestamp instead of the 403 page. This indicates that there is a firewall rule against the Firefox User Agent.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_220712.png)

#### PHP Parameter Fuzzing

Since we know that it's running PHP we can fuzz for parameters by excluding the size 19. One parameter is returned: `opt`.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_224605.png)

### Penetration

#### `opt` Parameter Exploitation

Intercepting a curl request through Burp and sending it to the Burp Repeater.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_230913.png)

Adding some spaces and quotes shows a bash shell, there must be a WAF in the way. The firewall must be matching bash commands so we can use methods of firewall evasion to get past it.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_230913_1.png)

After creating a PHP reverse shell page we can host a simple HTTP server and utilize the bash functionality on the firewall to spawn a reverse shell. The WAF is blocking the bash commands but these can be broken up with escape characters.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_235303.png)

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_235439.png)

#### User Shell as Nobody

After successful firewall evasion we are returned a shell as the nobody user on the target host. A quick shell upgrade is documented below. The nobody user is typically a low privileged user in Linux, but it appears that they have access to view other users' files and folder on the machine. Located at `/home/themiddle/user.txt` we find sensitive business information.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_235734.png)

#### Official Stance on Nobody User from Canonical

The nobody user was originally inteded for use with NFS as a service account for specific rights required by NFS servers. This user is often used as a low privileged service account on Ubuntu boxes and **this is wrong**. [Here](https://wiki.ubuntu.com/nobody) is official documentation on the nature of the nobody user for further reference. This user should not be used for anything other than an NFS file service.

### Privilege Escalation

#### Sudo Permission Enumeration

The nobody user has one sudo permission with no passowrd required on this machine. This means that the user can run the following program as root without issuing a password by proceeding our usage with `sudo`.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_235820.png)

#### `.monit` Exploitation

The `.monit` program simply checks for the first parameter as `cmd` and if it exists, it will base64 decode the second parameter and send it into the the bash interpreter.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220120_235916.png)

Exploitation of this program is trivial, we have to base64 encode our command then use it as the second parameter when running the program. Since we can sudo this program, all of the command will be ran as root. Using a base64 encoded string for `/bin/bash` spawns a bash session as root. Once a session as root is created we can read and write over any files on the system. This leads to the exposure of more critical business data located at `/root/root.txt`.

![Screenshot](/assets/images/2022-01-20-FluxCapacitor-HTB-Writeup/Screenshot_20220121_000026.png)

### Vulnerability Assessments

|---+---+---+---|
| Vulnerability | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| RCE through SuperWAF | Critical | - | The opt parameter on the /sync page of the SuperWAF service is vulnerable to remote code execution. |
| Privilege Escalation - Sudo Permissions | Critical | - | Web service user has a privilege escalation vector due to sudo permissions. |
