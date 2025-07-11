---
title: "Querier - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-17-Querier-HTB-Writeup/Querier-HTB-Image.png
  header: /assets/images/2022-03-17-Querier-HTB-Writeup/Querier-HTB-Image.png
  og_image: /assets/images/2022-03-17-Querier-HTB-Writeup/Querier-HTB-Image.png
excerpt: "After performing basic enumeration on the SMB service an Excel file is stored in a guest-accessible share. Downloading this Excel file and investigating it shows that there is an MS SQL macro being used against the target server. There are stored credentials to the macro code for the SQL server."
tags: [htb, writeup, querier]
---
## Querier

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_121044.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_121109.png)

#### Nmap Full Port Scan

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_121030.png)

#### Nmap Vulnerability Scan

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_121016.png)

### Service Enumeration

#### Nikto Web Scan on Port 47001

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_130750.png)

#### Nikto Web Scan on Port 5985

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_130815.png)

#### Nmap SMB Scan

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_131100.png)

#### SMB Enumeration

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_121521.png)

### Penetration

#### Spreadsheet Macro Enumeration

After performing basic enumeration on the SMB service an Excel file is stored in a guest-accessible share. Downloading this Excel file and investigating it shows that there is an MS SQL macro being used against the target server. There are stored credentials to the macro code for the SQL server.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_121834.png)

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_121920.png)

#### MS SQL Server Enumeration

Using Impact's MS SQL client with the stored credentials allows us to connect to the SQL server from our attacking machine.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_122402.png)

#### Responder SMB Credentials Stealing

Responder is a tool that listens on the network for credentials for common services such as SMB. By sending a specially crafted command to the MS SQL Server instance we can force it to authenticate against our attacking machine and capture the username and password hash of the service account.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_122520.png)

#### mssql-svc User Password Cracking

While Pass-The-Hash options typically exist for Windows authentication, we can crack the password for the mssql-svc user on the target machine with an offline dictionary attack using JohnTheRipper. The credentials found are `mssql-svc:corporate568`.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_122813.png)

#### mssql-svc SQL Login

With the credentials of the service account in hand, we can connect to the MS SQL Server once again with the Impacket client. This account appears to have more advanced permissions on the server including executing arbitrary commands on the target server.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_123020.png)

#### mssql-svc User Shell

Using a Metasploit Web Delivery module we can deliver a 64-bit Meterpreter shell and easily create a reverse shell as the mssql-svc user on the target server.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_123612.png)

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_123641.png)

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_123722.png)

### Privilege Escalation

#### mssql-svc User Enumeration

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_123950.png)

#### Stored Administrator Credentials

Cached GPP Passwords

Using an automated privilege escalation enumeration script such as WinPEAS reveals that there are stored GPP passwords on the target machine. The Administrator user has their credentials saved in a locally accessible method that allows the mssql-svc user to read them easily.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_124610.png)

#### Administrator Shell PSExec

Using the found credentials for the Administrator user we can use PSExec to create a user shell on the target server as the Administrator user.

![Screenshot](/assets/images/2022-03-17-Querier-HTB-Writeup/Screenshot_20220320_124852.png)
