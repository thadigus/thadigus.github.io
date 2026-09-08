---
title: "Arkham - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-17-Arkham-HTB-Writeup/Arkham-HTB-Image.png
  header: /assets/images/2022-03-17-Arkham-HTB-Writeup/Arkham-HTB-Image.png
  og_image: /assets/images/2022-03-17-Arkham-HTB-Writeup/Arkham-HTB-Image.png
excerpt: "There is a file on the BatShare called appserver.zip but it is too big to pull down over smbclient so we have to mount and then copy it over."
tags: [htb, writeup, arkham]
---
## Arkham

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131201.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131218.png)

#### Nmap Full Port Scan

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131233.png)

### Service Enumeration

#### Nikto Web Scan on port 8080

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131304.png)

#### FFuF Web Enumeration on Port 8080

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131326.png)

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131347.png)

#### SMB Enumeration

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131404.png)

#### Nmap SMB Scan

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_131425.png)

### Penetration

#### SMB File Enumeration

There is a file on the BatShare called appserver.zip but it is too big to pull down over smbclient so we have to mount and then copy it over.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_132000.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_132203.png)

#### Backup.img LUKS Encrypted

The appserver.zip file has an image file titled backup.img. This appears to be a LUKS encrypted image.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_132350.png)

#### LUKS Password Cracking

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_132559.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_132647.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_135353.png)

`batmanforever`

#### Backup Image File Enumeration

With the password for the LUKS encrypted image in hand, we can decrypt and mount the image to the attacking machine. There doesn't appear to be anything interesting in this image aside from Tomcat configuration files.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_140101.png)

#### Web Service Enumeration on Port 8080

Port 8080 is hosting a web server as enumerated earlier. The /userSubscribe.faces endpoint has an extension that indicates that it is running Java Faces. Using the article linked below we can begin to attempt the identification of a Java deserialization vulnerability.

<https://www.alphabot.com/security/blog/2017/java/Misconfigured-JSF-ViewStates-can-lead-to-severe-RCE-vulnerabilities.html>

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_141336.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_141407.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_141448.png)

#### Java Deserialization Vulnerability

Since we have access to the source code we can identify the backend code on this Tomcat instance as well. Java Deserialization vulnerabilities are common and a tool called Ysoserial can be used to generate payloads for this exact purpose. After performing a basic proof of concept we can create a reverse shell as the Alfred user on the target machine.

<https://github.com/frohoff/ysoserial>

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_144108.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_143223.png)

The myfaces.SECRET variable was found in web.xml.bak inside of the LUKS backup image.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_143518.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_143758.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_145454.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_145510.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_145750.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_150018.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_150010.png)

### Privilege Escalation

#### Alfred User Shell Enumeration

In `C:\\User\\Alfred\\Downloads\\backups\\backups.zip` We can download this file to the attacking machine for further enumeration.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_150151.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_150850.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_150832.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_151734.png)

#### Backups.zip

A mailbox is found in the zip file. Enumerating the emails shows a draft that has a picture attached to it. The picture is a screenshot of user credentials for the Batman user.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_151843.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_152040.png)

#### Batman User Shell

We can use the credentials found for the Batman user to create a reverse shell for our attacking machine.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_154734.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_154909.png)

#### Access Administrator Through SMB Privileges

From here the Batman user has administrative privileges on the target machine. While we cannot read the Administrator user's home directory immediately, we can use our administrative rights to mount the drive over SMB and read the Administrator directory from there.

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_154927.png)

![Screenshot](/assets/images/2022-03-17-Arkham-HTB-Writeup/Screenshot_20220320_154936.png)
