---
title: "Waldo - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-10-Waldo-HTB-Writeup/Waldo-HTB-Image.png
  header: /assets/images/2022-02-10-Waldo-HTB-Writeup/Waldo-HTB-Image.png
  og_image: /assets/images/2022-02-10-Waldo-HTB-Writeup/Waldo-HTB-Image.png
excerpt: "Waldo is a web server with limited functionality running inside of a docker container on the target host. The web service is vulnerable to local file inclusion due to a directory traversal method within one of the file read endpoints. The web service is being run as the Waldo user which has access to SSH keys for the Monitor using being run on the target machine. Monitor is running with advanced permissions that allow for a privilege escalation path to root."
tags: [htb, writeup, waldo]
---
## Waldo - High Level Summary

Waldo is a web server with limited functionality running inside of a docker container on the target host. The web service is vulnerable to local file inclusion due to a directory traversal method within one of the file read endpoints. The web service is being run as the Waldo user which has access to SSH keys for the Monitor using being run on the target machine. Monitor is running with advanced permissions that allow for a privilege escalation path to root.

### Recommendations

- Develop a custom web app to not have local file inclusion through directory traversal by using proper web service configuration.

- Create a web service account that does not have access to privileges on the docker container.

- Audit user permissions on the target host including the Monitor group.

---

## Waldo - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs an initial port scan to enumerate open ports and applications on the target. Ports 22 and 80 are returned which indicates that the server is a web server with remote management over SSH. SSH should be locked down and only exposed to the management network, but since it is exposed we can utilize credentials to access the server. SSH is running slightly behind patch but does not have any public vulnerabilities at this time. Port 80 is running Nginx which might indicate that the service is behind a reverse proxy.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_201216.png)

#### Nikto Web Scan

Nikto performs basic web application testing to identify common vulnerabilities and insecure configurations. The page is fingerprinted to be running PHP 7.1.16 on top of Nginx 1.12.2. The root page redirects to list.html instead of an index page.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_201232.png)

#### Gobuster Directory Enumeration

Gobuster performs directory enumeration based on a word list by making requests to the server. After running Gobuster with the medium 2.3 directory word list found on Kali by default no new pages are returned in addition to the list.html page found by Nikto.

### Service Enumeration

#### HTTP Service Enumeration

The HTTP service redirects to list.html which has limited functionality. After analyzing the requests that are sent using BurpSuite we can see that there is only one HTML page that makes calls to four other back-end endpoints. Clicking on a list sends a post request to /fileRead.php with the file parameter. This looks like it could have some directory traversal as it uses the file path ./. After clicking around on the website we find four total PHP endpoints which allow for file manipulation and file system reads. The fileRead.php endpoint blocks basic traversal.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_183832.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_184126.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_184437.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_184212.png)

### Penetration

After basic testing we can confirm that the PHP endpoints are vulnerable to directory traversal as PHP has been misconfigured, allowing for unprotected file system reads. Because of our file system read vector, we can enumerate the source code behind the fileRead.php endpoint.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_184734_2.png)

The fileRead.php endpoint does appear to attempt to block directory traversal with a simple string replacement. This could be fixed by properly configuring PHP to not have access to the whole file system. The PHP page is using a simple string replacement where ../ is replaced with nothing. By using ....// the string replacement will manipulate the request into ../ allowing for actual directory traversal. The code isn't even recursive which means it only has to be bypassed once.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_184858.png)

Now that we understand the directory traversal blocking method from the source code we can bypass the directory traversal protection and increase our file system read vector. We can use this to craft a directory traversal that will bypass the blocking and reveal users and files.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_185056.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_185141.png)

Reading /etc/passwd using the fileRead.php endpoint reveals the Cyrus user on the box. This can be confirmed by the existence of the Cyrus home folder using the readDir.php endpoint. Going into the .ssh folder in the Cyrus home folder we can read the private SSH key and use this to log into the remote management over SSH as the Cryus user.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_185406.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_185714.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_190736.png)

### Privilege Escalation

After enumerating the current user shell it is obvious that we are in a docker container as our IP is not the host that we were attacking but a different subnet. SSH must be port forwarded into the docker subnet from port 22 on the host to port 888 that we are connected to for the remote management session.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_190850.png)

In the .ssh folder, we can find a profile labeled .monitor. There are ssh keys in here for a monitor user on the waldo target as indicated by the end of the public key record. Attempting to login to the target machine from within the docker container allows us to remote into the host machine as the monitor user.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_191545.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_191555.png)

The SSH shell that is returned is quite limited and does not appear to resolve anything outside of its very limited path. We can still edit our path though so most functionality can easily be restored by exporting a typically Linux path for the monitor user.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_191632.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_191718.png)

By using rnano from within our restricted shell we can view critical files on the system. We can utilize /etc/passwd and /etc/groups to enumerate that we are in our group titled monitor.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_191835.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_191849.png)

The monitor group has control over the app-dev directory in the monitor home folder. The /usr/bin/tac binary has cap_dac_read_search capabilities which can drop privileged file system access in the right content. We can use our privileged read access on the tac binary to read the file system and pull the root RSA key allowing for an SSH remote management session on the target as root.

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_195148.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_195254.png)

![Screenshot](/assets/images/2022-02-10-Waldo-HTB-Writeup/Screenshot_20220207_200401.png)

### Vulnerability Assessments

| Vulnerability | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| Remote File Disclosure - Web Application | High | 0 | The file and directory read functionality of the custom web application are vulnerable to directory traversal. |
| Monitor Group Capabilities for Privilege Escalation | High | 0 | The Monitor group has capabilities that allow for privilege escalation to root. |
| Waldo User to Monitor Privilege Escalation | Informational | 0 | The Waldo user (web service user) has SSH keys for the Monitor user on the target host. |
