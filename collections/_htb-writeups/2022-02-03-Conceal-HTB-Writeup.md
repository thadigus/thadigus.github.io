---
title: "Conceal - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-03-Conceal-HTB-Writeup/Conceal-HTB-Image.png
  header: /assets/images/2022-02-03-Conceal-HTB-Writeup/Conceal-HTB-Image.png
  og_image: /assets/images/2022-02-03-Conceal-HTB-Writeup/Conceal-HTB-Image.png
excerpt: "Conceal is a web server running behind an IPsec VPN connection with IPsec and SNMP exposed to the public. The SNMP community string is default set to 'public' revealing the weak password hash of the VPN server. After connecting an anonymous login allows for remote code execution on the web server granting a user shell on the target. The web service user has the standard SEImpersonatePrivilege which is easily exploited to SYSTEM-level access with the common 'JuicyPotato' exploit."
tags: [htb, writeup, conceal]
---

## Conceal - High Level Summary

Conceal is a web server running behind an IPsec VPN connection with IPsec and SNMP exposed to the public. The SNMP community string is default set to 'public' revealing the weak password hash of the VPN server. After connecting an anonymous login allows for remote code execution on the web server granting a user shell on the target. The web service user has the standard SEImpersonatePrivilege which is easily exploited to SYSTEM-level access with the common "JuicyPotato" exploit.

### Recommendations

- Configure firewalls, SNMP should not be visible to the public.

- Password audit, create strong SNMP community strings and VPN passwords.

- Disable Anonymous access for FTP, and utilize LDAP.

- Do not allow for web server file upload through FTP without proper hardening.

---

## Conceal - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a TCP port scan to identify open ports and services on the target. After running a scan against the server no results are returned for the entire TCP port range.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_215921.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220206_085846.png)

#### UDP Port Scan

Since no information was returned on the full port TCP scan we can turn to UDP and check the top 1000 ports to see if there is any connectivity on the box. Doing so shows two services currently exposed to the local network. SNMP provides simple network management for the target and the other service appears to be an IPsec VPN service.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_131719.png)

### Service Enumeration

#### SNMP Enumeration

SNMP appears to use the default community string "public" which allows us to enumerate relevant data from the SNMP service. Multiple ports are found and a lot of system information is disclosed. A string for the IKE VPN password PSK exists. Considering this is the only other service on the box we can assume that this is the password to connect to the VPN service and enumerate what is behind it. Hash ID identified this as an NTLM hash and CrackStation has an entry for "Dudecake1!"

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_131909.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_132128.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_132042.png)

#### IPsec VPN Configuration

After adding the found password to the secrets file for the IPsec client on the attacking machine and then adding the connection profile to IPsec we can start the VPN service to enumerate behind the VPN firewall.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_141507.png)

#### VPN Enumeration

Automated port scanning and enumeration do not like the VPN so we will have to enumerate by hand. We can see that FTP is running on the target along with an HTTP server and the standard SMB and NetBIOS services for Windows.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_141708.png)

#### FTP Enumeration

FTP is configured for anonymous access, but nothing appears to be stored on the server.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_141822.png)

#### Web Server Enumeration

The web service appears to be a default installation of IIS. After the use of common enumeration tools such as gobuster, we can find the /upload directory which also has nothing stored on it. The web service has detailed error messages turned on which allows us to enumerate a lot of information such as file paths from a 404 error page.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_141943.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_142005.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_143709.png)

### Penetration

#### FTP Upload to Server

It appears that we can upload files to the FTP server under our anonymous access and these files show up in the /upload directory on the server.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_142110.png)

#### Web Service Exploitation - Reverse Shell

With this information, we can place an ASP file on the server to execute the code. We can upload a PowerShell reverse shell and an ASP file that will run as the web service account. Doing so grants a reverse shell as the destitute user.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_143912.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_143925.png)

### Privilege Escalation

#### User Privilege Enumeration

As most web service users have, the destitute user has SeImpersonatePrivilege. This is referred to as one of the golden privileges because it typically makes privilege escalation easy using an exploit called JuicyPotato.

After successfully identifying that the target is Windows 10 Enterprise we can enumerate a common list of CLSIDs on the target to find one that will work. The JuicyPotato GitHub repository has CLSID lists for all compatible operating systems. Using test.bat to test this list will identify the CLSIDs that will work for valid privilege escalation.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_200511.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_201217.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_201228.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_201318.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_201409.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_202344.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_205418.png)

Now that the files have been uploaded to the server we set up a listener on the attacking machine for the Meterpreter reverse shell. We then identify the administrative CLSID by using the testing batch script provided in the GitHub repository.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_212055.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_212639.png)

After identifying a correct CLSID, we can upload a reverse shell through the FTP server in binary mode, and then utilize the CLSID with the JuicyPotato exploit to run the shell in the administrative user context.

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_213400.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_213838.png)

![Screenshot](/assets/images/2022-02-03-Conceal-HTB-Writeup/Screenshot_20220205_213904.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| FTP Server Allows for Web Service File Upload and RCE | Critical | 0 | Files uploaded to the FTP server under anonymous access are rendered on the IIS web server. |
| SEImpersonatePrivilege Allows for Privilege Escalation to System | Critical | 0 | User permissions allow escalation to the system with SEImpersonatePrivilege through JuicyPotato. |
| Weak SNMP Community String | Critical | 0 | The SNMP service exposed to the local network is using the default "public" community string. |
| Weak IPsec Password String | Critical | 0 | The IPsec VPN service uses a weak password found in SNMP. |
| FTP Allows for Anonymous Login | High | 0 | The FTP service running on the server allows for Anonymous Login. |
| Error Page Detailed Information Enabled | Informational | 0 | The error pages on IIS show detailed information about the system. |
