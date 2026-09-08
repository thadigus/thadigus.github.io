---
title: "Zipper - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-01-Zipper-HTB-Writeup/Zipper-HTB-Image.png
  header: /assets/images/2022-02-01-Zipper-HTB-Writeup/Zipper-HTB-Image.png
  og_image: /assets/images/2022-02-01-Zipper-HTB-Writeup/Zipper-HTB-Image.png
excerpt: "Zipper is a Zabbix server orchestrating two other Linux servers, a simple password is used that provides administrative API level access and remote code execution on all of the other servers. Systemctl uses an insecure path in a custom SUID binary that allows for privilege escalation to root."
tags: [htb, writeup, zipper]
---
## Zipper - High Level Summary

Zipper is a Zabbix server orchestrating two other Linux servers, a simple password is used that provides administrative API level access and remote code execution on all of the other servers. Systemctl uses an insecure path in a custom SUID binary that allows for privilege escalation to root.

### Recommendations

- Secure the Zabbix Web UI without using guest access.

- Audit passwords and ensure that complex passphrases are used on all authentication mechanisms.

- Create a secure path for Systemctl usage within SUID contexts.

---

## Zipper - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a port scan to identify open ports and services on the target. Two services are returned upon the initial scan with a third on the full TCP port range scan. SSH is open as well as an HTTP server, and a Zabbix verse is running on port 10050 as well.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_004122.png)

#### Nikto Web Scan

Nikto performs a basic web security scan to identify possible vulnerabilities in the web service. Nothing is noted on this scan aside from the out-of-date Apache service running 2.4.29, as well as some default files.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_004147.png)

#### FFuF Directory Enumeration

FFuF performs basic automated directory enumeration on the target. Only default index pages and hta pages are returned from this enumeration, pointing to a default installation of Apache.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_004209.png)

### Service Enumeration

#### Web Service Enumeration

It appears that port 80 is hosting a default Apache2 instance.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_005646.png)

#### Gobuster Directory Enumeration

Using gobuster for advanced directory enumeration with a better wordlist we find a /zabbix directory.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_021305.png)

#### Gobuster Directory Enumeration /zabbix

Further enumeration on the Zabbix directory shows directories and files for a default installation of Zabbix.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_024046.png)

#### Zabbix Enumeration

Zabbix 3.0.21 is found with a login page. The login page allows for guest login on the host. Zabbix is used to orchestrate servers from a web dashboard. We can see that there is a valid username for Zapper. Three servers exist for the Zabbix platform, two Linux servers, and the Zabbix server that we are targeting.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_010028.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_010045.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_010115.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_010229.png)

### Penetration

#### Zapper User

A script name points to the username Zapper, using the username as the password as well allows us to log in. But GUI access is disabled.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_012530.png)

#### Authenticated RCE on Zabbix

Using the following PoC script from ExploitDB we can use the API access of the Zapper user to create remote code execution on one of the hosts that Zabbix is managing. This will not be the target machine but will create a foothold on the network to further attack the target machine from a different address. We have all of the information except for a host ID, we can go back into the GUI as a guest to find this. Once we fill in all of the required information on the target then we can create a basic non-interactive command shell using the exploit. From here we can upgrade to a reverse shell as the Zabbix user.

<https://exploit-db.com/exploits/39937>

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_012834.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_012848.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_012933.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_012955.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_013204.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_013222.png)

#### Shell upgrade

```bash

SHELL=/bin/bash script -q /dev/null

CTRL + Z

stty raw -echo; fg

reset

xterm

export TERM=xterm

```

### Privilege Escalation

We can use `system.run` to interact with other containers on port 10050 as a part of the Zabbix service. We can see that /backup is shared on both servers since we can see the file that we created on the local server when we ls /backups on the remote server. But attempting to run something out of /backups returns permission denied.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_013534.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_014024.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_014251.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_014715.png)

#### Perl Reverse Shell in Shared Storage

A Perl shell seems to work which might indicate that there are limited privileges for execution on the shared storage. Creating a Perl reverse shell and using Netcat as a listener eventually grants a reverse shell on the 172.17.0.1 machine.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_020036.png)

#### Zabbix User Enumeration

With shell-level access as the Zabbix user, we can enumerate the user permissions on the target. A SUID binary stands out and running strings against the executable shows that it is doing systemctl commands for the Zabbix agent. It does not use a full path, and the systemctl service checks the local directory before proceeding to the rest of the path to find the service file.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_020225.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_020433.png)

#### Systemctl Path Exploitation

The full path is not being used so we can utilize local path exploitation to run the commands as root. By placing a Zabbix-agent service file with a Perl reverse shell in the local directory and then running the executable that starts the service as root, we can execute the reverse shell with the same permissions as the systemctl program under SUID, providing system-level access in the form of a root shell on the target server.

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_020628.png)

![Screenshot](/assets/images/2022-02-01-Zipper-HTB-Writeup/Screenshot_20220204_021158.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| Weak Zabbix API Password | Critical | 0 | A weak administrative password is used, allowing control over all servers. |
| Systemctl Insecure Path | Critical| 0 | An executable does not use a secure path for Systemctl commands allowing for privilege escalation to root. |
| Zabbix Guest Login Enabled | High | 0 | Guest login is allowed on the Zabbix service and is not well restricted. |
| Default Apache Files | Informational | 0 | Default Apache installation files are viewable to end users allowing them to see the Apache version. |
