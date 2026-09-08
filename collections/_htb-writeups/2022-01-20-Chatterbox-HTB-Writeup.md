---
title: "Chatterbox - HTB Writeup"
header: 
  teaser: /assets/images/2022-01-20-Chatterbox-HTB-Writeup/Chatterbox-HTB-Image.png
  header: /assets/images/2022-01-20-Chatterbox-HTB-Writeup/Chatterbox-HTB-Image.png
  og_image: /assets/images/2022-01-20-Chatterbox-HTB-Writeup/Chatterbox-HTB-Image.png
excerpt: "Chatterbox is a Windows 7 server running an application called Achat. Achat and Windows are both significantly out of date which leaves the machine at risk. A remote buffer overflow against Achat provides remote code execution on the machine and then MS16-032 provides privilege escalation to system."
tags: [htb, writeup, chatterbox]
---
## Chatterbox - High Level Summary

Chatterbox is a Windows 7 server running an application called Achat. Achat and Windows are both significantly out of date which leaves the machine at risk. A remote buffer overflow against Achat provides remote code execution on the machine and then MS16-032 provides privilege escalation to system.

### Recommendations

- Update Windows 7 immediately as the patch for MS16-032 is released and readily available.

- Update from Windows 7 to a non EOL operating system.

- Update Achat to the latest version.

---

## Chatterbox - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a basic network port scan and identifies that the target is a Windows server with two ports open. On ports 9255 and 9256 the Achat application is being hosted.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220123_213238.png)

#### Nmap Vuln Scan

Nmap performs basic software enumeration and web vulnerability enumeration, but does not find anything notable.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220123_213303.png)

### Service Enumeration

#### Achat Application

Achat is the only application that is exposed to the local network. It is a simple chatting app that allows users to connect to a central server and chat in rooms with each other.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/20220123213930.png)

[Image Source: sourceforge.net](https://sourceforge.net/projects/achat/)

#### Exploitation Research

It appears that there is a remote buffer overflow vulnerability for the Achat application found on Exploit-DB. The exploitation takes advantage of CVE-2015-1577 and CVE-2015-1578, which include open redirects in u5CMS and directory traversal u5CMS to write arbitrary files causing a buffer overflow on the Achat application.

This shows the impact of a supply chain vulnerabilities as the buffer overflow is not directly accessible over the network, but the vulnerabilities in the used libraries create the network vulnerability for this version of Achat.

While the service version has not been confirmed, performing this buffer overflow will either produce the exploitation desired or do nothing at all, so testing it is benign.

[Exploit Code](https://www.exploit-db.com/exploits/36025)

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_000826.png)

### Penetration

#### Metasploit Module (exploit/windows/misc/achat_bof)

A [Metasploit module](https://www.rapid7.com/db/modules/exploit/windows/misc/achat_bof/) has been created to automate the testing and exploitation of this vulnerability. Use of this module is documented below and a shell is returned.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_001303.png)

While the shell does return a call back, it does appear to instantly die when there is any user interaction. This is most likely because the crashed process (due to the buffer overflow) is quickly killed and restarted. Since the exploitation is happening on a Windows machine we can utilize Metasploit Framework scripting to perform an automated migration within the session to another process before it is killed. The process for doing so is outlined below.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_001848.png)

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_002213.png)

Once the shell has been stabilized with the automated process migration we have a shell as the Alfred user on the target machine. This user has access to sensitive data stored in `user.txt`.

### Privilege Escalation

#### WinPEAS Automated Enumeration

Using WinPEAS, an automated post exploitation enumeration script, we quickly find stored credentials on the machine for our current user. The credentials can be revealed using PowerShell to decrypt them from their secure string state. Once these credentials are found they can be used to exploit other targets on the domain or establish persistence on the target machine.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_002420.png)

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_002756.png)

#### Secondary Logon Handle Exploitation

[Local Exploit Suggester](https://www.rapid7.com/db/modules/post/multi/recon/local_exploit_suggester/) is a Metasploit module to automate privilege escalation enumeration. While the tool identified multiple possible vulnerabilities only one was exploitable in the current state of the system.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220123_220053.png)

[MS16-032](https://docs.microsoft.com/en-us/security-updates/SecurityBulletins/2016/ms16-032) is a vulnerability that can effect all versions of Windows and was discovered in 2016. Below is the security bulletin detailing the vulnerability. This must be patched immediately. Using the Metasploit module for this exploit we are given a shell as NT AUTHORITY\SYSTEM.

[More MS16-032 Information Here](https://support.microsoft.com/en-us/topic/ms16-032-description-of-the-security-update-for-the-windows-secondary-logon-service-march-8-2016-72fb6be7-a7c7-1600-a875-4fce0cad8eed)

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_004343.png)

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_004408.png)

#### Data Exfiltration

In the NT AUTHORITY\SYSTEM shell we could not exfiltrate the critical business data, as it appears that the file permissions have been edited so that even the system user cannot read them. Since we are the administrative user, though, we can simply give ourselves the permission and read the data. After editing our file permissions on the sensitive data in `root.txt` we are able to read out the file.

![Screenshot](/assets/images/2022-01-20-Chatterbox-HTB-Writeup/Screenshot_20220121_004900.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- :|
| MS16-032 Secondary Logon | High | 7.2 | The operating system is not fully patched, standard users can elevate to system. |
| Windows 7 EOL | High | - | The target is running Windows 7 which is an EOL operating system. The server must be upgraded. |
| Achat Insecure Version | Medium | 6.4 | Achat is running significantly out of date on the machine and leaves it vulnerable to a remote buffer overflow attack. |
