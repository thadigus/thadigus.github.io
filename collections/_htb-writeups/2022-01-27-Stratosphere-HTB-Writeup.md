---
title: "Stratosphere - HTB Writeup"
header: 
  teaser: /assets/images/2022-01-27-Stratosphere-HTB-Writeup/Stratosphere-HTB-Image.png
  header: /assets/images/2022-01-27-Stratosphere-HTB-Writeup/Stratosphere-HTB-Image.png
  og_image: /assets/images/2022-01-27-Stratosphere-HTB-Writeup/Stratosphere-HTB-Image.png
excerpt: "Stratosphere is a web server that is running an out-of-date version of Apache Struts that is vulnerable to remote code execution. The machine is running MySQL locally and the database has the username and password of a local user. Password reuse allows an attacker to SSH into the machine and no Python path defined allows a malicious Python library to be used for privilege escalation to root on the target."
tags: [htb, writeup, stratosphere]
---
## Stratosphere - High Level Summary

Stratosphere is a web server that is running an out-of-date version of Apache Struts that is vulnerable to remote code execution. The machine is running MySQL locally and the database has the username and password of a local user. Password reuse allows an attacker to SSH into the machine and no Python path defined allows a malicious Python library to be used for privilege escalation to root on the target.

### Recommendations

- Update Apache Struts

- Set a Python path to now allow writing access to Python libraries by users.

- Audit sudo permissions for users.

- Change passwords so they are not reused across services.

---

## Stratosphere - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a basic port scan on the target to identify open ports and services. On the target, three services appear to be open. Port 22 hosts SSH for remote administration. Port 80 appears to host a web server and the same goes for port 8080.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_101204.png)

#### Nikto Web Scan on Port 8080

Nikto performs a basic web scan on the application running on port 8080. There appear to be several findings that indicate to default Tomcat install on this port.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_101313.png)

#### FFuF Enumeration on Port 8080

FFuf can find three pages. Index.html returns a 200 and can be accessed by the end user, while the manager and host-manager are kept behind authentication returning code 302.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_101330.png)

#### Nikto Web Scan on Port 80

Nikto finds the same findings as port 8080 when ran against port 80. The Tomcat directories are still found.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_101243.png)

#### FFuF Enumeration on Port 80

FFuF has the same findings on port 80 as it did on port 8080.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_101254.png)

### Service Enumeration

#### Website on Port 80

The website running on port 80 is a basic site advertising a credit monitoring service. The site doesn't appear to have any feature present.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_103834.png)

#### Gobuster for Port 80

Gobuster performs a basic directory enumeration on the site. Running this against the site returns /manager and /monitoring. The other findings show that the site does not respond well when % is used in the request.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_103738.png)

#### Gobuster for Port 8080

Gobuster returns the same content on port 8080 as if the sites are the same.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_103627.png)

#### Site Enumeration

Port 80 and 8080 are the same sites except that the port 8080 site has more content. We are assuming that port 8080 is a dev site not meant for end users. Development sites are instant targets for attackers as they are typically running custom and untested code.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_100724.png)

#### /monitoring Web Page

The /monitoring page resolves to a site that ends with .actions. The actions extension is typically used on Apache Struts.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_101050.png)

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_101127.png)

### Penetration

#### Apache Struts Exploitation

Below is an article detailing the effects of exploiting Apache Struts. In 2017 the Equifax breach was caused by this same exploit. The exploit that will be used to attack this box is registered under CVE-2017-5638

<https://www.intezer.com/blog/cloud-security/exploiting-a-vulnerable-version-of-apache-struts/>

<https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-5638>

The following link to ExploitDB shows a PoC code entry for the vulnerability being used. Using the Welcome.action site that we found in discovery to create remote code execution we can execute commands as the tomcat8 user. A reverse shell is not easily possible as it appears that no interactive commands can be run. We can still work our way around the file system.

<https://www.exploit-db.com/exploits/41570>

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_102440.png)

#### MySQL Enumeration

The db_connect file shows the credentials that are being used for the MySQL server on the back end of the web application. While we cannot run the MySQL application since it is interactive, we can use the -e option to run an ad-hoc command against the database.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_102655.png)

In the users' table, we can see a username and password combination. Looking in the /home directory we can see that Richard is a valid user on the machine. Using this username and password on the SSH service we can create a remote shell session as the Richard user.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_102728.png)

#### SSH as Richard User

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_102829.png)

### Privilege Escalation

#### Sudo Enumeration Richard User

The Richard user has sudo rights on the target machine with no password but these are limited to the use of Python against a particular file in the test.py file in the user's directory.

While we cannot write to the Python file, it appears that it calls the hashlib.py library. We possess write permissions to the folder that we are executing in so we can create our haslib.py library which will be locally included. The screenshots below show creating the Hashlib library that simply spawns the /bin/bash process. A root shell can be easily obtained by running the test.py as root with sudo, including the library upon execution, and creating a root shell on the target.

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_102921.png)

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_103018.png)

![Screenshot](/assets/images/2022-01-27-Stratosphere-HTB-Writeup/Screenshot_20220125_103439.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- :|
| Apache Struts RCE | Critical | 0 | Apache Struts is running a version that is vulnerable to remote code execution. |
| Python Path Allows for Privilege Escalation | Critical | 0 | No Python path is set allowing overwritten libraries to be run as root. |
