---
title: "Resolute - HTB Writeup"
header: 
  teaser: /assets/images/2022-04-14-Resolute-HTB-Writeup/Resolute-HTB-Image.png
  header: /assets/images/2022-04-14-Resolute-HTB-Writeup/Resolute-HTB-Image.png
  og_image: /assets/images/2022-04-14-Resolute-HTB-Writeup/Resolute-HTB-Image.png
excerpt: "Using Impacket's GetADUsers.py program we can enumerate the Active Directory server for anonymous binding. It appears that anonymous binding is enabled which means that a great deal of information about the domain can be enumerated. Below shows a basic username list in the domain."
tags: [htb, writeup, resolute]
---
## Resolute

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_111726.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_111757.png)

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_111845.png)

#### Nmap Full Port Scan

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_111824.png)

#### Nmap UDP Port Scan

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_111907.png)

#### Nmap UDP Script Scan

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_111931_1.png)

### Service Enumeration

#### Nmap SMB Enumeration

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_112110.png)

#### Nmap LDAP Enumeration

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220412_112905.png)

#### Active Directory Anonymous Binding

Using Impacket's GetADUsers.py program we can enumerate the Active Directory server for anonymous binding. It appears that anonymous binding is enabled which means that a great deal of information about the domain can be enumerated. Below shows a basic username list in the domain.

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_111306.png)

#### JXplorer Active Directory Client

JXplorer is a GUI program for Debian that allows us to explore the Active Directory LDAP service. Since anonymous binding is allowed we can use the settings below to connect to the LDAP server and enumerate the domain. Looking through the users shows that there is a note on the Marko Novak user saying that their account has been created and the password has been set to `Welcome123!`

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_112634.png)

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_112752.png)

### Penetration

#### Password Spraying - Default Credentials

It appears that the help desk will create accounts and then set their password to `Welcome123!` until the user is fully provisioned. Since the Active Directory instance allows for anonymous binding we can create a user list and then attempt this password across the domain. The following credentials are found: `melanie:Welcome123!`

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_113208.png)

#### Melanie User Shell - Evil-WinRM

Melanie is also part of the Remote Managers group that is allowed to remotely managed servers over WinRM. Using these credentials with Evil-WinRM we can create a user shell as Melanie on the target server.

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_113347.png)

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_113500.png)

### Privilege Escalation

#### Credentials Stored in PSTranscripts

Hidden folders located at C:\\PSTranscripts\\20191203\\ have logs from Powershell sessions as the Ryan user on the target server. Enumeration of these files shows a command that was logged which has passwords specified in a parameter. The credentials for Ryan are found below.

`ryan:Sev3rAdmin4cc123!`

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_114101.png)

#### Ryan User Session

Using the stolen credentials to remote into the target server using Evil-WinRM creates a user shell as the Ryan user. While a flag is not found on the desktop a note that indicates that the server is often reset by a configuration management system every minute is left.

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_114433.png)

#### Ryan User Group Enumeration

It appears that the Ryan user has elevated permissions on the target server due to the groups that they are joined into. The screenshot below shows the enabled groups for this user. Notably, this user is part of the `NT AUTHORITY\NETWORK` and `MEGABANK\DnsAdmins` which have elevated permissions on the target host.

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_123427.png)

#### DNS Server Load DLL over UNC Path

Because of the `MEGABANK\DnsAdmins` membership the Ryan user can edit the `dns` service on the target server using `sc.exe`. The screenshots below indicate the binary path injection steps to set the DNS service to run a remote DLL over SMB when the process is launched. SMB is used for remote DLL injection so that anti-virus does not pick up on the malicious file.

<https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/active-directory-security-groups#bkmk-dnsadmins>

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_123802.png)

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_124101.png)

#### Reverse Shell as Administrator

This attack will cause the DNS service to fail which may alert the defense team. After restarting the service the malicious DLL file is executed and a reverse shell as the `NT AUTHORITY\SYSTEM` user is returned. This user is the system-level account that can perform any file read/write operations and any commands with unlimited permissions.

![Screenshot](/assets/images/2022-04-14-Resolute-HTB-Writeup/Screenshot_20220413_124128.png)
