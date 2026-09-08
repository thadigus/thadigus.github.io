---
title: "Reel - HTB Writeup"
header: 
  teaser: /assets/images/2022-01-20-Reel-HTB-Writeup/Reel-HTB-Image.png
  header: /assets/images/2022-01-20-Reel-HTB-Writeup/Reel-HTB-Image.png
  og_image: /assets/images/2022-01-20-Reel-HTB-Writeup/Reel-HTB-Image.png
excerpt: "Reel is a small business FTP and Mail server that has remote management over SSH. After phishing a user and creating a shell session on the target, attackers were able to escalate up to the domain administrator due to a privilege creep that has taken place across the domain. The domain will require a privilege audit and privilege/service accounts to be used for critical permission workloads."
tags: [htb, writeup, reel]
---
## Reel - High Level Summary

Reel is a small business FTP and Mail server that has remote management over SSH. After phishing a user and creating a shell session on the target, attackers were able to escalate up to the domain administrator due to a privilege creep that has taken place across the domain. The domain will require a privilege audit and privilege/service accounts to be used for critical permission workloads.

### Recommendations

- Configure FTP for authenticated access.

- Educate users against email phishing.

- Do not statically store credentials.

- Perform a privilege audit on the domain.

- Implement privilege and service accounts separate from standard user accounts on the domain.

---

## Reel - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs basic port scanning to show open services on the server. Three ports appear to be open on the server:

- Port 21 - File Transfer Protocol

- Port 22 - Secure Shell (Remote Management)

- Port 25 - Simple Mail Transfer Protocol (Email)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_133219.png)

An nmap script scan detects the software versions running on the server and also interacts with the mail server to perform some basic banner grabbing and initial reconnaissance.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_133233.png)

#### SMTP User Enumeration

Mail servers typically have common usernames and due to the protocol we can enumerate common email addresses to quickly return any valid emails on the server. The scan did not return any names.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_133312.png)

### Service Enumeration

#### FTP Enumeration

Using wget we can efficiently pull all files off of the server to work on them offline. Three files are returned and one is a text file that asks the recipient to email an RTF file to them so they can convert it to a docx file format.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_214716.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_133353.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_133421.png)

#### Metadata Scraping

There are two docx files already on the server that have been converted. While they don't appear to contain any relevant data, using exiftool to scrape the metadata off of them shows a valid email for the domain.

`nico@megabank.com`

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_133635.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_133704.png)

### Penetration

#### Malicious RTF File

The account asking for RTF files is converting them to docx. This means that they must be opening and rendering their RTF files to, most likely, save them as docx by hand. We can create a malicious RTF file using the following exploit to generate a reverse shell as they open it.

[CVE-2017-0199 Exploit Code](https://github.com/bhdresh/CVE-2017-0199)

Above is a link to the source code to perform this file generation by hand, but a [Metasploit module](https://www.rapid7.com/db/modules/exploit/windows/fileformat/office_word_hta/) has been made to perform this automatically.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_215320.png)

#### Sending Malicious RTF File

Once the malicious file has been generate we simply have to email it to `nico@megabank.com` so they will open it in an attempt to convert it to docx. Using `sendemail`, a command line in Kali, we can email this attachment to the SMTP server on the target.

[sendemail Tool Documentation](https://www.kali.org/tools/sendemail/)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_215331.png)

#### Reverse Shell Callback

After a few seconds the user opens the file and a reverse shell callback executes providing the attacker with shell level access to the system as the nico user.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_215354.png)

### Privilege Escalation

#### User Enumeration

The user nico appears to just be a standard user with their own home folder and documents. The user does not have any special privileges on the box other than to simply read and write to the file system.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_215354 1.png)

After trying to upload an automated enumeration script it was deleted and flagged by Windows Defender. This indicates that anti virus is running on the machine and will significantly limit user level enumeration.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_221222.png)

#### Credentials Stored in XML

After enumerating the file system a stored credentials file is found. This XML file stores encrypted credentials for the Tom user. The intention of these files is to be able to run scripts with stored credentials but, by using PowerShell, we can dump these credentials in clear text, revealing the credentials for the Tom user.

`tom:1ts-mag1c!!!`

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_220210.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_220955.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_221515.png)

#### SSH as Tom User

The Tom user is another user account on the box with their own home directory and permissions. In Tom's home directory a report regarding BloodHound is found and a note indicates that there is a way to escalate privileges to Domain Admin within the data.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_221606.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_221703.png)

#### BloodHound  & Exfiltrating Data

After uploading the Powershell script for BloodHound data collection to the machine we can download the results in a zip folder.

[BloodHound Source Code](https://github.com/BloodHoundAD/BloodHound)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_135449.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_135500.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_135828.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_135828 1.png)

#### Analyzing BloodHound Results

Install BloodHound

`sudo apt install bloodhound`

Setup BloodHound with Databases

`sudo neo4j console`

Then go to `http://localhost:7474` to configure. Close it out then just run `bloodhound`.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_140637.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_142509.png)

Tom has `WriteOwner` AD rights. This means that the Tom user has the ability to take ownership of other objects in the AD. They cannot transfer ownership but simply take it. Since we can do this against the Claire user we can assume ownership of their permissions and perform actions against them. Below we will use PowerSploit to perform this exploitation. Once we take ownership of the Claire user object we can change their password and login as them.

[PowerSploit Source Code](https://github.com/PowerShellMafia/PowerSploit)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_225658.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_225944.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_230250.png)

#### SSH as Claire User

The Claire user is yet another standard user on the machine that has a home directory and set of permissions.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_230338.png)

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220122_143024.png)

Claire has `GenericWrite` and `WriteDacl` permissions over the `backup_admins` group. The `backup_admins` can read inside of the backups folder in the Administrator home directory on the box. There is an administrator password stored in this file.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_230542.png)

#### SSH as Administrator

Using the stored Administrator password to SSH in we have managed to gain full system level access to the target.

![Screenshot](/assets/images/2022-01-20-Reel-HTB-Writeup/Screenshot_20220121_230703.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- :|
| Stored Credentials - Tom User | High | - | Stored credentials should not be readable or decryptable by standard users. |
| WriteOwner AD Privileges  - Tom User | High | - | Standard users should not have WriteOwner privileges. |
| WriteDacl AD Privileges - Claire User | High | - | Standard users should not have WriteDacl privileges. |
| Stored Credentials - Administrator | High | - | Administrator credentials should never be stored in clear text in scripting files. |
| Anonymous FTP Access | Medium | - | No authentication is required to access FTP on the target server. |
| Use of RTF Files | Informational | - | Rich Text Format files are common practice, but users must be educated on email phishing. |
