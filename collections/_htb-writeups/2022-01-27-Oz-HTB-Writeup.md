---
title: "Oz - HTB Writeup"
header: 
  teaser: /assets/images/2022-01-27-Oz-HTB-Writeup/Oz-HTB-Image.png
  header: /assets/images/2022-01-27-Oz-HTB-Writeup/Oz-HTB-Image.png
  og_image: /assets/images/2022-01-27-Oz-HTB-Writeup/Oz-HTB-Image.png
excerpt: "Oz is a docker host that is running three containers to support a Python web application. The API for the web application is vulnerable to SQL injection. The web application is vulnerable to Server-Side Template Injection. The SQL server reveals an SSH RSA key and password reuse allows for decryption. An unintended firewall configuration leak leads to an SSH shell on the target host as a user. Access to Portainer shows an out-of-date version that allows an attacker to sign in as an administrator. A malicious docker container can be spawned for root-level file system access."
tags: [htb, writeup, oz]
---
## Oz - High Level Summary

Oz is a docker host that is running three containers to support a Python web application. The API for the web application is vulnerable to SQL injection. The web application is vulnerable to Server-Side Template Injection. The SQL server reveals an SSH RSA key and password reuse allows for decryption. An unintended firewall configuration leak leads to an SSH shell on the target host as a user. Access to Portainer shows an out-of-date version that allows an attacker to sign in as an administrator. A malicious docker container can be spawned for root-level file system access.

### Recommendations

- SQLi and SSTI must be patched on the custom web application. Security auditing on the development life cycle will need to be implemented.

- A password audit will be performed to eliminate weak password usage.

- Firewall configuration files must be hardened and not viewable by users.

- Portainer and all other applications must be enrolled in a patch cycle maintenance schedule to keep them from running out of date.

---

## Oz - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a basic port scan on the target host to reveal open ports and services. Two services are found both running HTTP Werkzeug which is a python HTTP server. These will both be enumerated further in the web service enumeration phase.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_163356 1.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_163412.png)

While further automated enumeration with tools such as FuFF, Nikto, Gobuster, and more was tried, they returned non-sense data on their default settings as it appears that the web application may be slightly resistant to automated scanning tools.

### Service Enumeration

#### Web Service Enumeration

Port 80 is running a page that simply returns "Please register a username!" without any option to register.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_163501.png)

Port 8080 is running a service called GBR Support with a login page.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_163518.png)

Enumeration proved to be difficult as the web pages appear to be very elusive. They will often respond with a random length and they always respond with 200 OK. Because of this, it made scanning very difficult.

#### Manual Fuzzing with Wfuzz

We were able to fuzz directories and files on the server by hiding lengths of 0. This allowed us to discover more about the port 80 services. Moving into BurpSuite Repeater to make web requests easier to write, we enumerated the /users feature of the site.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_165505.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_165531.png)

Adding a username such as admin to the end appears to return JSON data. This looks like a typical REST API and the admin field is an SQL query. We can SQL inject this parameter. Using + for space doesn't work but URL encoding spaces with %20 allows for the SQL injection, below shows enumerating the first record.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_165859.png)

#### SQLmap to Automate SQL Injections

Moving this request over to SQLmap will allow the tool to automate the SQL injection through a series of discovery requests. The tool can locate the injectable protocol and even enumerate it in a way that bypasses the possible Web Application Firewall.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_170445.png)

Specifying --dump will begin to dump the databases and user data can be found.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_170608.png)

### Penetration

#### SQL File Inclusion

Within the SQL database, the posts for the site on port 8080 are held. One of the posts indicates that SSH is running and RSA keys have been recently created. The post also notes that an RSA key can be found in /home/dorthi. We can use SQL map to pull the private keys down.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_170938.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_171024.png)

#### User Credential Enumeration

SQLmap was able to download the users' table which has username and password hashes. Using awk to sort out the data we can create a file to send to our password-cracking program.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_173846.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_173923.png)

HashID identifies the hashes as being PBKDF2 HMAC hashes.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_174130.png)

After replacing `$` with `:` and taking off the preamble from the password hashes we have a password hash file that is ready for cracking. We can fire up Hashcat to begin a dictionary attack against this password list using RockYou.txt, a common password list.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_174916.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_174847.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_175554.png)

After a few minutes, Hashcat was able to crack the password hash with a result of wizardofoz22. Using this associated hash we can finally create a valid credential pair.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_175731.png)

wizard.oz:wizardofoz22

#### Logging into the Website

Using the valid credentials on the login page found on port 8080 we can finally access the site behind it. There appears to be a simple site with posts for its users.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_175814.png)

#### Server-Side Template Injection

Since we can post to the site, standard enumeration would have us test for server-side template injection. The diagram below describes the basic enumeration steps to find out which template injection will work on the site. Using PayloadsAllTheThings guide we can create remote code execution on the target.

<https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Template%20Injection>

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/20220128180242.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_180309.png)

While the server does not return any data in the browser after we post, moving the request to BurpSuite shows the server-side rendering of the content.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_180326.png)

The screenshot below shows the validity of the server-side template injection. The post should render exactly what is typed by the user. Since the server responds with the calculated response we know that it is performing code execution on the back end. This specific rendering also identifies the server to be running Python Jinja2.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_180438.png)

Using a simple server-side template injection payload we can create basic code execution on the site and even read files on the local file system.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_180504.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_181400.png)

#### Reverse shell

Once code execution is achieved we can utilize our command functionality to create a full reverse shell on the target. PayloadsAllTheThings has a basic guide on Jinja2 Server-Side Template injection that helps us create the reverse shell we need. Below we are uploading a Python configuration file to the site in the /tmp directory on the target machine. The Python configuration file has a reverse shell payload in it. Loading the Python configuration file into memory executes the Python code to create the call back to the attacking machine.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_182111.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_182216.png)

#### Root Shell Enumeration

The target does not have basic binaries installed such as wget, curl, bash and Python3. We can see that we are most likely running inside of a Docker Container due to the presence of the Dockerfile in the App directory.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_182308.png)

The shell can still be upgraded by performing the following.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_183032.png)

Running ifconfig shows that the target has an IP in 10.100.10.0/29, not the target IP address for the assessment. This further concludes that we are in a virtualization container of some sort. Dumping ARP also indicates another IP address on the network, 10.100.10.4.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_183506.png)

After enumerating the App directory we find the web server source code and a file with SQL credentials in it. These are addressed toward the 10.100.10.4 server that we found in the ARP table as well. 10.100.10.4 appears to be the SQL server for the application, it is assumed that this is also running inside of a docker container. Since we already enumerated this database through the SQL injection no further information can be found here.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_183621.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_183715.png)

#### Docker IP Addresses

10.100.10.2 - Web Server

10.100.10.4 - SQL Server

#### Firewall Configuration Enumeration

In /.secret a file is found called knockd.log. This is a simple port-knocking configuration. This appears to open SSH on the target after a packet on UDP 40809, 50212, and 46969, then close it after 10 seconds. We can create a script to perform this sequence to allow us into SSH once SSH credentials are found.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_183935.png)

#### RSA Decryption

The RSA key that was found in the initial database compromise is encrypted with a password. Using the password for the database found above decrypts the RSA key for the Dorthi user.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_184614.png)

#### SSH onto Target as Dorthi

An initial attempt to SSH into the target simply hangs because port 22 is not open on the target machine. After running a port knock on the sequence found earlier the SSH port is opened for ten seconds allowing the attacker to establish a connection on the target as the Dorthi user. Luckily the port knock does not close off the connection after ten seconds, as it only stops new connections from being made.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_184712.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_191329.png)

### Privilege Escalation

#### Sudo Enumeration

We can run some very limited Docker commands as root with the sudo command. We find yet another docker container running on the instance called portainer-1.11.1 and its address is 172.17.0.2. Portainer runs on port 9000 so we can SSH port forward it to work on it.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_191559.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_191722.png)

#### SSH Port Forwarding

~C on a clean line to print up SSH prompt we can use the following command to forward the port that Portainer is running on. Once this has been completed we can access the Portainer web application on the localhost interface of the attacking machine.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_193429.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_193444.png)

#### Portainer Exploitation

Portainer is a docker orchestration platform that provides a Web UI to create and manage docker containers on a given host. When visiting the Portainer site we are met with a login page but Googling the Portainer version quickly reveals a vulnerability in the Portainer API where the administrator password can be set with a simple curl command.

<https://github.com/portainer/portainer/issues/493>

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_194052.png)

Once we reset the password to something we know we can get into the administrative panel through the login page we found.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_194106.png)

#### Malicious Docker Container

Below is a quick guide to malicious container concerns. Containers are created with root permissions due to the work that needs to be performed. One thing that can be done with this permission is mounting the entire Linux file system to the container. We can spawn a container with this file system and easily enter it with root permissions.

<https://book.hacktricks.xyz/linux-unix/privilege-escalation/interesting-groups-linux-pe/lxd-privilege-escalation>

Below are the settings used to create a malicious container on the target host. Ensure that a TTY interactive is set as well. Once the container is created, we can use the console and /bin/sh to console into the machine as root. We can read the entire target file system with this console.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_194355.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_194601.png)

#### Root Shell

The container does get deleted after a while, I found the action in Crontab that deleted my docker container and deleted the Crontab so I wouldn't have to deal with my container getting deleted.

Arbitrary file writing on the server can easily lead to a root shell through many means. Since we already have a shell as the Dorthi user we can simply add full sudo no pass permissions for the Dorthi user so they can su to root with no password authentication.

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_200624.png)

![Screenshot](/assets/images/2022-01-27-Oz-HTB-Writeup/Screenshot_20220128_200703.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| SQL Injection to User Parameter in API | Critical | 0 | The user parameter in the API on port 80 is vulnerable to SQL Injection. |
| Outdated Portainer Allows for RCE | Critical | 0 | The outdated version of Portainer allows for root-level remote code execution on the target. |
| Server-Side Template Injection | High | 0 | Users can write template content leading to a server-side template injection. |
| Weak Password Usage | High | 0 | Due to the use of a weak password for the wizard.oz administrative access was granted to the web site. |
| User Readable Firewall Configuration | Low | 0 | Container users can view a copy of the host firewall configuration. |
| Password Reuse - RSA Decryption | Low | 0 | The same password was used to encrypt an SSH RSA key as was used in the application. |
| Unauthenticated API Access | Informational | 0 | No authentication is required to use the API on port 80, this may be intended. |
