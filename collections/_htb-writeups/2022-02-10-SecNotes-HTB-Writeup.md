---
title: "SecNotes - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-10-SecNotes-HTB-Writeup/SecNotes-HTB-Image.png
  header: /assets/images/2022-02-10-SecNotes-HTB-Writeup/SecNotes-HTB-Image.png
  og_image: /assets/images/2022-02-10-SecNotes-HTB-Writeup/SecNotes-HTB-Image.png
excerpt: "SecNotes is a custom web application server that hosts a note-taking web application. The custom application is vulnerable to SQL injection that allows a remote user to view all notes. A note contains the user credentials for limited file system access to another web application on the target. The low-privilege user has the Administrator user credentials stored in a Linux virtual machine within their access."
tags: [htb, writeup, secnotes]
---
## SecNotes - High Level Summary

SecNotes is a custom web application server that hosts a note-taking web application. The custom application is vulnerable to SQL injection that allows a remote user to view all notes. A note contains the user credentials for limited file system access to another web application on the target. The low-privilege user has the Administrator user credentials stored in a Linux virtual machine within their access.

### Recommendations

- Change the custom web application to not reveal positive usernames in login returns.

- Change administrative credentials and secure any instances that they are being used.

- Fix SQL Injection to the custom web application that allows users to view all notes in the database.

- Store passwords in a secure database such as a password manager.

---

## SecNotes - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs port scanning against the target to identify open ports and services to which we can connect. Nmap locates port 80 which indicates that the server is running an HTTP web service on the local network. Port 445 is open, allowing for SMB services like SMB File Shares to be accessed on the local network.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_201321.png)

#### Nmap Full Port Scan

A full port scan reveals another service running on port 8808 which is running Microsoft IIS HTTP Web server 10.0. This service is similar to the web service running on port 80 but may not contain the same files and applications.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_201333.png)

#### Nikto Web Scan on Port 80

Nikto performs basic web service enumeration to identify default files, configurations, and security vulnerabilities. On port 80 IIS 10.0 is also being run with PHP 7.2.7 running behind the code of the site. Nikto see's that the PHP session ID cookie is created without the HTTP only flag which means that the site could be vulnerable to cross-site scripting and cross-site request forgery.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_201349.png)

#### Nikto Web Scan on Port 8808

Nikto is also run against port 8808 because it is hosting a web server as well. It confirms IIS 10.0 as well but it does not return any PHP pages. Assuming that these two services are running on the same host (not being port forwarded over to docker containers) we can assume that this service is also PHP 7.2.7 capable. No other notable discoveries are made.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_201358.png)

#### Nmap SMB Scan

Nmap can also perform automated scanning on port 445 to enumerate the three most common SMB vulnerabilities. No new vulnerabilities are found, and it appears that the SMB service does not allow for anonymous login.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_201415.png)

### Service Enumeration

#### HTTP Server Enumeration

After enumerating the site running on port 80 we can see that the login page is found at login.php. The site will return the string "No account found with that username" if a user does not exist. Using this returned string we can enumerate users with Wfuzz.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_172557.png)

The site also features a signup form that allows unverified end users to create accounts on the site. Creating an account and then using the wrong password allowed us to verify that the site returns a different message of "The password you entered was not valid" if the user does exist.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_172617.png)

After using a standard word list with Wfuzz we were able to enumerate the Tyler user but no other user's existed. After signing in using the created account from the signup page there is a note that refers to Personally Identifiable Information (PII). The email tyler@secnotes.htb is revealed as the contact for system administration.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_173443.png)

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_171850.png)

#### SQL Injection Enumeration

After attempting an SQL injection on the exposed forms on the site it does not appear that there are any SQL injections, cross-site scripting injection points, or template injections. Fuzzing all inputs and running traffic through BurpSuite doesn't reveal any additional functionality to the web application.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_172117.png)

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_172140.png)

### Penetration

#### SQL Injection on User Creation Form

When creating a user name it is possible to perform a basic SQL injection by inputting the `test' or 1=1 -- -` string into the username field. This bypasses the user's control of the database. Since this string returns true when evaluated against the database it returns all notes instead of the notes limited to that particular user.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_175345.png)

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_175403.png)

#### SMB User Access Credentials

 After logging in with this new user we can see all notes that are in the database. Many of the notes are not relevant but it appears that the Tyler user has recorded credentials in their notes for an SMB share titled new-site.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_175440.png)

With the SMB credentials leaked from the web application database, we can connect to the SMB share with standard user read and write permissions. The user account does not have permission to view the whole file system but read and write access to the new-site share is granted.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_175550.png)

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_175628.png)

#### Web Service File Exploitation

It appears that files uploaded to this SMB share are on the web service running on port 8808. By uploading a test file and then browsing to the file name on the HTTP service running on port 8808 we see our PHP code rendered on the target site. While PHP reverse shell payloads have limited compatibility with the Windows platform this server is running on a simple PHP backdoor that enables command line access is all that is required to spawn a reverse shell on the target machine.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_175957.png)

After uploading a PHP backdoor we can browse the malicious file on the server and utilize our command line functionality to make system calls. Using this functionality that we installed as a back door to the web server we can perform basic enumeration of the file system and user permissions.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_180039.png)

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_180057.png)

#### Web Delivery Reverse Shell

Using the Metasploit framework's web delivery module allows us to generate a simple command that, when ran, will download and execute a reverse shell for the target platform. Using a Powershell one-liner in the web shell allows us to spawn a reverse shell Meterpreter session on the target host as the Tyler user, which appears to be running the web server processes instead of a service account.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_180410.png)

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_180500.png)

### Privilege Escalation

Some basic enumeration of the user files on the target machine shows that the user uses WSL or some other way of virtualizing Linux. We can find that there is a basic Linux file system and executable. We have read permissions on the virtual machine image as they are within the user account.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_180653.png)

While the virtualized Linux instance can be executed and we are given a root shell within the virtual machine sandbox. After some basic testing, it does not appear that we have any permissions over the target host file system. A .bash_history file is found in the /root directory. Within this file, a bash command is recorded which mounts an SMB share with administrative credentials. We can repeat these commands to obtain administrative access to the file system within the VM.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_180755.png)

Using the found administrative credentials we can obtain access to the target server from within our current user shell. Since port 445 is open (as shown in the initial scan) we can use PSexec with our administrative credentials to create a malicious executable and then create a malicious service running a remote procedure call, creating an administrative reverse shell from the target machine as the Administrator user. From here we have full administrative read, write, and execute permissions on the target.

![Screenshot](/assets/images/2022-02-10-SecNotes-HTB-Writeup/Screenshot_20220207_181220.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- :|
| SQL Injection - Username | Critical | 0 | An SQL injection to the username field can allow for accounts to be created that can view all notes in the application. |
| Administrative Credentials Found in Bash History | High | 0 | The administrator user's credentials are found in the .bash_history of a Linux virtual machine. |
| Username Enumeration in Web Application | Low | 0 | Usernames can be disclosed by the login messages returned by the web application login page.
| SMB Credentials Found in Note Database | Low | 0 | SMB Credentials for another web service file system are being stored in an insecure web application. |
