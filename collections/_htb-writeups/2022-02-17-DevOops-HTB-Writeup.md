---
title: "DevOops - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-17-DevOops-HTB-Writeup/DevOops-HTB-Image.png
  header: /assets/images/2022-02-17-DevOops-HTB-Writeup/DevOops-HTB-Image.png
  og_image: /assets/images/2022-02-17-DevOops-HTB-Writeup/DevOops-HTB-Image.png
excerpt: "DevOops is a web server running a development site that is noted to still be under construction. An XML file upload allows for local file inclusion, revealing files on the server to end users connecting to the web service. After stealing an SSH key, as the web service process can access user files a user session over SSH can be created. The SSH key for root was accidentally committed in a git repository that the user can view. Using the git history to reassemble the root RSA key an end user can SSH into the target server as root."
tags: [htb, writeup, devoops]
---
## DevOops - High Level Summary

DevOops is a web server running a development site that is noted to still be under construction. An XML file upload allows for local file inclusion, revealing files on the server to end users connecting to the web service. After stealing an SSH key, as the web service process can access user files a user session over SSH can be created. The SSH key for root was accidentally committed in a git repository that the user can view. Using the git history to reassemble the root RSA key an end user can SSH into the target server as root.

### Recommendations

- Audit Git repositories and perform clean and a rebase on any sensitive data.

- Remove SSH keys from repositories and use environment variables and local files at runtime.

- Lockdown development sites from end users and the local network.

- Remove insecure XML file uploads from sites exposed to end users.

- Use a web service account to run the web server instead of a user account. Limit privileges on the web service account to strictly necessary.

---

## DevOops - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs automated scanning to identify available ports and services on the target machine that are running on the local network. Port 22 is the default port for SSH the encrypted remote management that allows system administrators to log into the target server for their management. The only other port that is open is TCP port 5000 which is not immediately identifiable.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220221_140848.png)

#### Nmap Script Scan

Using a script scan to fingerprint the services running on port 22 and port 5000 allows us to find version information and more for each port. Port 22 confirms that SSH is being run with OpenSSH version 7.2 on the Ubuntu server, revealing that the target is on a Linux operating system. Port 5000 is running a web server on the HTTP protocol. Fingerprinting returns Gunicorn 19.7.1 as the software being served.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220221_140910.png)

#### Nmap Full Port Scan

Nmap performs a port scan on all 65535 to ensure that higher ports are not open on the target possibly running out of band services that are not on the top 1000 port list that is normally scanned by Nmap. No other ports are found to be open on the local network.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220221_140925.png)

### Service Enumeration

#### Nikto Web Service Enumeration

Nikto performs automated web security application testing to identify common vulnerabilities and weak configurations in web applications. Running this tool against the HTTP service on port 5000 returns some basic findings. Anti-clickjacking and cross-site scripting security headers are not present which can leave end users vulnerable to cross-site scripting attacks as well as other common web security attacks.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220221_140947.png)

#### HTTP Service Enumeration

Visiting the web service on port 5000 shows a basic site that only has a few lines of text and an image. This site has very limited functionality but it states that the site is under construction and there is a feed.py endpoint on the server. This shows end users that the web server is some sort of Python server.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_180213.png)

#### /feed Web Endpoint

The /feed web endpoint is valid on the server and it is simply the image that is shown on the front page. It was noted that this would soon be replaced by an actual web feed that is functional on the site, but at the moment this is merely a static image with no functionality to exploit.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_180451.png)

#### /upload Web Endpoint

The /upload web endpoint is a static page that has a file upload feature on the site. While any file can be uploaded as there is no input validation the page states that the file upload should be an XML file. Sample XML elements are given: Author, Subject, and Content. It's noted that this is a test API that will not be used in the final project. This API may have additional functionality due to its testing nature that we can exploit. Test sites such as this should not be exposed to end users on the local network.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_180520.png)

### Penetration

#### File Disclosure - /upload XML File Upload

Since the upload specifies that XML documents can be uploaded to the server we can craft our XML payload to upload onto the server. There are many options for XML payload injection on the site. The simple option is shown below which allows for a local file read on the site through a file to include the parameter in the XML code. This basic proof of concept below shows the XML file loading in /etc/passwd on the target Linux file system as well as the output redirected upon uploading the file.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_184836.png)

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_184910.png)

#### SSH Key - /upload File Disclosure

Moving this XML attack into BurpSuite after we intercept the traffic we can easily enumerate the file system with the repeater. The /etc/passwd file was pulled down in the previous step which shows all valid users on the target machine. The home directory of these users can also be shown but this is typically located at /home for any users that have shells assigned to them. The Roosa user's home directory is readable by the web service user which is most likely being run under the Roosa user context. Navigating into the standard `~/.ssh/id_rsa` file shows the SSH private key for the Roosa user. After downloading this key to a file on the attacking machine and setting the appropriate file permissions we can remote into the target machine as the Roosa user over the SSH protocol as shown below.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_191734.png)

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_191720.png)

#### Roosa User Shell

Within the Roosa user shell, we can enumerate the local file system and exfiltrate any data that is within this user context. An SSH key is found in the ~/deploy/resources/integration/authcredentials.key but it does not appear to work when used to impersonate the identities of other users on the target machine. The /etc/passwd file does indicate a user titled Blogfeed but using the found SSH key against this user account does not allow for a remote management session.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_192347.png)

### Privilege Escalation

The Roosa user has a git repository hosted in their home folder (as indicated by the .git directory present in the project) that appears to be for web development. Searching through the commit history of this repository there is a notable commit comment stating that a key has to be revoked with a new one committed. Since it states that this key was accidental instead of a replacement we can assume that this key is worth finding to try against other users on the target.

`roosa@gitter:~/work/blogfeed$ git log`

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_192503.png)

By using the git log command we can enumerate changes to the git repository on the target machine. Within the git log, there are changes noted and it appears that the authcredentials.key was part of the changes. Using the previously used RSA key we can exfiltrate it to the attacking machine, set the appropriate file permissions, and then use it to impersonate users over SSH on the target machine. This RSA key works for the root system-level account which has completely unauthenticated read, write, and execute permissions over the target machine.

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_192821.png)

![Screenshot](/assets/images/2022-02-17-DevOops-HTB-Writeup/Screenshot_20220213_193438.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- :|
| Root SSH Key in Git Repository | Critical | 0 | The root RSA key for the SSH key was committed into the Git repository in the user control. |
| XML File Upload LFI | High | 0 | The XML upload feature at /upload can allow for remote file reads on the target server. |
