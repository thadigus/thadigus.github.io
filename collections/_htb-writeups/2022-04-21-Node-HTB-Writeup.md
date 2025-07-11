---
title: "Node - HTB Writeup"
header: 
  teaser: /assets/images/2022-04-21-Node-HTB-Writeup/Node-HTB-Image.png
  header: /assets/images/2023-04-21-Node-HTB-Writeup/Node-HTB-Image.png
  og_image: /assets/images/2022-04-21-Node-HTB-Writeup/Node-HTB-Image.png
excerpt: "After some enumeration on the HTTP service visiting /api/users on port 3000 shows a list of users and their password hashes.  These can be exfiltrated to the attacking machine for an offline password-cracking attack. One user is marked as an admin on the server so their password hash will be prioritized. After running the SHA256 hash through JohnTheRipper with the `rockyou.txt` word list the following credentials are found."
tags: [htb, writeup, node]
---
## Node

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220414_233227.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220414_233238.png)

#### Nmap HTTP Enumeration on Port 3000

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220414_233133.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220414_233301.png)

### Service Enumeration

#### Nikto Web Scan on Port 3000

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220414_234157.png)

#### FFuF Web Enumeration on Port 3000

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_000139.png)

#### HTTP Service Enumeration

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_135900.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_140004.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_140507.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_140549.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_140646.png)

### Penetration

#### Administrator User Password Cracking

After some enumeration on the HTTP service visiting /api/users on port 3000 shows a list of users and their password hashes.  These can be exfiltrated to the attacking machine for an offline password-cracking attack. One user is marked as an admin on the server so their password hash will be prioritized. After running the SHA256 hash through JohnTheRipper with the `rockyou.txt` word list the following credentials are found.

`myP14ceAdm1nAcc0uNT:manchester`

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_141620.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_141630.png)

#### Downloaded Backup Enumeration

After logging into the target web server as the admin account a backup file is offered for download. The file appears to be base64 encoded. After base64 decoding the backup file to a new file it is recognized as a password-protected zip file. Using fcracksip and the `rockyou.txt` word list we can crack the zip file and unzip it on the attacking machine. At the top of the app.js file, we find credentials for the MongoDB database service running as the back end for the Node.js app running on port 3000.

`mark:5AYRft73VtFpc84k`

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_141837.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_141940.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_142147.png)

#### Mark User Shell

The MongoDB credentials are used on the SSH service and a user shell as the Mark user is returned on the Ubuntu server. The user shell is not privileged on the target host but it provides command-line-level access within the Mark user context on the target server.

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_142255.png)

### Privilege Escalation

#### Mark User Shell Enumeration

Further enumeration of the Mark user on the target server with the automated privilege escalation script LinPEAS shows that the server is vulnerable to CVE-2021-4034 which is a local privilege escalation vulnerability in the Polkit service.

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_143404.png)

#### Polkit Exploitation - CVE-2021-4034

The exploitation of CVE-2021-4034, an exploit also referred to as Pwnkit, is documented below. After cloning the GitHub repository linked below and then using SCP to copy it onto the target server using SSH exploitation can take place. Using GCC to compile the executable and then running the resulting binary will spawn a shell as the root user on the target server, allowing for full enumeration of the file system and unlimited command permissions.

<https://github.com/arthepsy/CVE-2021-4034>

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_143237.png)

![Screenshot](/assets/images/2022-04-21-Node-HTB-Writeup/Screenshot_20220415_143319.png)
