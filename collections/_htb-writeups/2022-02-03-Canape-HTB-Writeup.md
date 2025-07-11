---
title: "Canape - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-03-Canape-HTB-Writeup/Canape-HTB-Image.png
  header: /assets/images/2022-02-03-Canape-HTB-Writeup/Canape-HTB-Image.png
  og_image: /assets/images/2022-02-03-Canape-HTB-Writeup/Canape-HTB-Image.png
excerpt: "Canape is a web server that is running Python Flask. The source code is publicly available on the site which exposes a Python Pickle deserialization vulnerability, creating remote code execution on the server as the web service user. CouchDB is running out of date on localhost but can be exploited to find the Homer user's password, which is reused on the SSH service. Homer has sudo permissions to install Python Pip repositories with an insecure path, allowing for privilege escalation to root."
tags: [htb, writeup, canape]
---
## Canape - High Level Summary

Canape is a web server that is running Python Flask. The source code is publicly available on the site which exposes a Python Pickle deserialization vulnerability, creating remote code execution on the server as the web service user. CouchDB is running out of date on localhost but can be exploited to find the Homer user's password, which is reused on the SSH service. Homer has sudo permissions to install Python Pip repositories with an insecure path, allowing for privilege escalation to root.

### Recommendations

- Store code repositories on a secure service such as GitLab.

- Do not allow for file system writes with Python Pickle implementation.

- Update CouchDB and all other packages on the server.

- Enroll the server into a patch management solution and keep all packages up to date.

- Implement a secure Python Pip path to not allow for user-created pip installs.

- Audit sudo permissions.

---

## Canape - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a port scan of the target to identify open ports and available services on the target machine. Two ports are found to be open on the target. Port 80 is serving an HTTP web server that is running Apache 2.4.18. Nmap also identifies a /.git directory with a git repository in it. Port 65535 is running OpenSSH 7.2p2 revealing an Ubuntu server in its header.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_210726.png)

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_210743.png)

#### Nikto Web Scan

Nikto performs basic web service enumeration on the target to identify vulnerabilities or information. The server appears to respond to junk requests and brought a lot of false positives in the scan. Web Enumeration will have to be performed by hand to get relevant data from this service.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_211115.png)

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_211203.png)

### Service Enumeration

#### Web Enumeration

The website running on port 80 appears to be a simple page with very few features.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_211619.png)

#### WFuzz Enumeration

The site responds 200 to most requests and using the character count as a qualifier allowed us to successfully enumerate the web service directories. This confirmed the existence of the /.git directory and the rest were part of the main site feature set.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_211657.png)

The /.git directory reveals a git repository that is being stored. The basic analysis leads us to assume that this is the source code for the web service we are using on port 80.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_211839.png)

The /config file points to git.canape.htb/simpsons.git, so we can pull that down to analyze the repository after adding this to our hosts file. It appears that this is the source for the site, from here we can analyze it for vulnerabilities.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_213728.png)

#### Pickle Serialization

The site appears to be using Pickle to serialize its input on the /submit endpoint. Pickle is notorious for causing deserialization vulnerabilities when not implemented properly on web servers.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_214055.png)

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_214223.png)

### Penetration

#### Pickle Insecure Deserialization

The source code reveals that the quote upload feature is vulnerable to a pickle deserialization vulnerability. When a quote is posted on the /submit endpoint it is saved to the /tmp directory on the server provided it meets the whitelist constraint. The file name is an md5 hash that can be calculated externally as well. Using the /check endpoint we can call this to be deserialized by pickle and possibly run.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_214235.png)

With this information, we can develop a script to exploit the pickle deserialization. We use echo moe && and then our payload for the Netcat reverse shell. This is then sent into the /submit form which will utilize the pickle deserialization vulnerability and write it to the file system, injecting the command after it's run through the /check endpoint.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_221434.png)

The most difficult part of this exploit is finding its ID parameter for the /check exploitation. As we can see in the source code this is an md5 hash sum of the character name being used and the quote (reverse shell payload) which can be queried at the /check endpoint on the flask server. Doing so results in the running of this bash command since it was injected as the `os.system` module.

#### Utilizing Script for Reverse Shell

The script below was created and resulted in a fully featured reverse shell on the target box.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_220536.png)

#### Shell as www-data

The service is running as www-data, a common web service account used on Linux. Some basic enumeration in the user shell does not reveal any extra privileges this service account has, showing that it has been properly hardened on the machine.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_220557.png)

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_222254.png)

Running netstat on the machine does reveal two services that are only running on localhost. The two highlighted services are not accessible to the local network and will be enumerated by hand. This appears to be running software called CouchDB, a software package written by the Apache Foundation. This is most likely the backend database for the web service being run. There appears to be a known exploit for this out-of-date version of Couch DB.

<https://exploit-db.com/exploits/44913>

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_222356.png)

This doesn't seem to work as it says that it runs the command but nothing happens. This was tested for pinging and remote shell usage. It does succeed in creating an administrative account so we can enumerate the database. The exploit was able to create an administrative user named guest with the password of guest, even though it was not able to create remote code execution. After some database enumeration, we can dump a password table using our administrative privileges.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_224111.png)

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_224347.png)

#### User Shell as Homer

Dumping the passwords returns a password marked as SSH. We saw that SSH is running on port 65535 so we can use this against the Homer user, the only user on the box. Doing so grants a shell as the Homer user.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_224507.png)

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_224526.png)

### Privilege Escalation

#### Sudo Permission Exploitation

It appears that Homer can run sudo while using /usr/bin/pip install. This is very common since they would need administrative privileges to install Python packages for their Python Flask development. When executing pip install on the current directory, pip will run a setup.py file in the current directory. It's common for package developers to add a setup.py into their repositories for easy setup. Since we possess write access to the local directory we can create our setup.py to run the python script as root. Initially, we attempted to use a simple `subprocess.call('/bin/sh')` but it appears that pip does not like to run interactive commands. We instead tried a reverse shell and it worked, granting the attacker a root shell on the target host.

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_230517.png)

![Screenshot](/assets/images/2022-02-03-Canape-HTB-Writeup/Screenshot_20220203_230536.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- :|
| Public Source Code Repository | Critical | 0 | Code is stored in a public repository.|
| Pickle Insecure Deserialization RCE | Critical | 0 | The implementation of Python Pickle can create remote code execution on the target. |
| Sudo Permissions Pip Install | Critical | 0 | The Homer user has sudo permissions to install pip libraries with an insecure path, allowing for privilege escalation to root. |
| CouchDB Out of Date | High | 0 | The CouchDB running on localhost is out of date allowing unauthenticated users to dump data. |
