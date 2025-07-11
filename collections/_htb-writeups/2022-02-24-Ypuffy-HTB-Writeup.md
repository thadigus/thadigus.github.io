---
title: "Ypuffy - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-24-Ypuffy-HTB-Writeup/Ypuffy-HTB-Image.png
  header: /assets/images/2022-02-24-Ypuffy-HTB-Writeup/Ypuffy-HTB-Image.png
  og_image: /assets/images/2022-02-24-Ypuffy-HTB-Writeup/Ypuffy-HTB-Image.png
excerpt: "Nmap performs automated port scanning against the target server to identify open ports and services. After an initial scan, it appears that there are several ports on the target that are open. Given the TTL response and the open ports, the target server appears to be an OpenBSD server with SMB, LDAP, and NetBIOS exposed to the local network."
tags: [htb, writeup, ypuffy]
---
## Ypuffy

### Information Gathering

#### Nmap Port Scan

Nmap performs automated port scanning against the target server to identify open ports and services. After an initial scan, it appears that there are several ports on the target that are open. Given the TTL response and the open ports, the target server appears to be an OpenBSD server with SMB, LDAP, and NetBIOS exposed to the local network.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_142542.png)

#### Script Scan

Nmap performs a script scan against the target host to perform automated enumeration on the target ports and services. SSH is identified as an OpenSSH 7.7 server and the HTTP service confirms OpenBSD as the operating system. SMB automated enumeration shows the hostname of ypuffy and FQDN of ypuffy.hackthebox.htb.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_142601.png)

### Service Enumeration

#### SMB Script Scan

More enumeration on SMB is done, but since the host is OpenBSD instead of Windows it does not show any common Windows vulnerabilities such as Zero-Logon, EternalBlue, and more.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_142632.png)

#### Nikto Web Scan

Nikto performs an automated web scan against the target to identify common security vulnerabilities and configuration issues. The service running on port 80 of the target server did not participate with a valid response to the scanner and therefore a web server was not found, even though there is a service responding on this default port. Further enumeration by hand will be done to identify the services on this port.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_142428.png)

#### FFuF Directory Enumeration

FFuF performs automated directory enumeration by sending requests and reading response codes given by the server to identify files that may be on the server and whether or not they are functional or accessible. This tool can also be used for Nginx configuration enumeration by identifying patterns in the output. Since the service on port 80 does not appear to return valid responses to HTTP requests it appears that FFuF was not able to identify anything about the server.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_142452.png)

#### LDAP Search

LDAP Search is a standard tool for enumerating LDAP services that are open to the local network. By using the options set below we can enumerate the LDAP service as an anonymous bind is enabled on the target service. Because of this usernames and password hashes are revealed to all participants on the local network.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_142404.png)

#### Password Hashes

Attempting to use rainbow table attacks to un-hash the target passwords does not yield any results on the publicly accessible service CrackStation.net. These passwords will have to be cracked with a strong dictionary or brute force offline password-cracking techniques.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_143000.png)

#### Alice NTLM Password Hash

One password hash remains that is noted as a SambaNTPassword which means that it is being utilized for SMB authentication. The target server is hosting an SMB service so it is reasonable to assume that this password may work to authenticate against that service.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_143132.png)

### Penetration

#### Pass the Hash - SMB

While we were not able to crack any of the user password hashes the SMB service is vulnerable to a Pass the Hash attack because of the way that it handles its user password authentication. By supplying the user name and password hash to the pth-smbclient we can authenticate against the service and view any files available to this user.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_143626.png)

#### PuTTY Private Key File

A PuTTY private key file is found on the SMB server, because of our read privileges we can download it to the attacking machine for further exploitation.

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_143641.png)

#### SSH User Shell

Using the puttygen tool we can generate a standard RSA SSH key to use the key for SSH authentication from our attacking machine. By simply applying the appropriate file permissions to this key and authenticating against SSH on the target server with the Alice username we can spawn a user SSH shell as the Alice user on the target server.

`sudo apt install putty-tools -y`

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_143857.png)

### Privilege Escalation

#### XORG X11 Server Privilege Escalation

Privilege escalation to root is very simple on this server as it appears to be running a vulnerable version of Xorg-X11 Server 1.20.3. By using the following linked script we can elevate our privileges and spawn a shell as the root user on the target machine. From here we can perform any actions on the server at a system level.

<https://www.exploit-db.com/exploits/45742>

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_144720.png)

![Screenshot](/assets/images/2022-02-24-Ypuffy-HTB-Writeup/Screenshot_20220225_144653.png)
