---
title: "Tartarsauce - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Tartarsauce-HTB-Image.png
  header: /assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Tartarsauce-HTB-Image.png
  og_image: /assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Tartarsauce-HTB-Image.png
excerpt: "Tartarsauce is a Linux web server that has a WordPress website over HTTP running an out-of-date version of the GWolle DB plugin that allows for remote file inclusion and code execution over PHP. The web service user has sudo permissions to run tar as the Onuma user. Using a public GTFObin to spawn a shell, an attacker can create a user session as the Onuma user. Onuma has been given write permissions to a root process that manipulates and logs files. Using this the user can read files as root and execute bash commands as root."
tags: [htb, writeup, tartarsauce]
---
## Tartarsauce - High Level Summary

Tartarsauce is a Linux web server that has a WordPress website over HTTP running an out-of-date version of the GWolle DB plugin that allows for remote file inclusion and code execution over PHP. The web service user has sudo permissions to run tar as the Onuma user. Using a public GTFObin to spawn a shell, an attacker can create a user session as the Onuma user. Onuma has been given write permissions to a root process that manipulates and logs files. Using this the user can read files as root and execute bash commands as root.

### Recommendations

- Do not run backup and other privileged operations as root, create a service account with strictly limited permissions to perform these actions.

- Audit sudo permissions on the target to ensure strictly necessary permissions on the target server.

- Update the GWolle DB WordPress plugin to the latest version.

---

## Tartarsauce - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs port scanning on the target to identify open ports and services on the local network. The only open port on the target is port 80 which is most likely a web service running over HTTP if it is running on the standard port. No other ports are returned which indicates that this server does not support any remote management protocols such as SSH and might have a host-based firewall preventing connections from our IP.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220221_140636.png)

#### Nmap  Script Scan

Nmap performs a script scan to further enumerate the open services. Nmap finds that the HTTP service is running on Apache HTTPd 2.4.18 on Ubuntu. A robots.txt file is found that has a few entries. These are possibly valid pages that can be further enumerated by hand. The /web services directory appears to host all of the files listed and might be a hidden root page for browsing the site.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220221_140651.png)

#### Nikto Web Service Scan on Port 80

Nikto performs automated security scanning on remote web servers on the local network. After running it on port 80 several findings are presented. Security features such as XSS protection headers, anti-clickjacking headers, and more are not present. The PHPSESSID cookie (the session cookie for users on the site) is generated without the httponly flag set which means that users can be vulnerable to XSS and CSRF attacks when browsing the target site. Apache 2.4.18 is out of date and EOL.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220221_140743.png)

#### FuFF Directory Enumeration on Port 80

FuFF performs automated fuzzing and directory and file enumeration on the target web server to identify files that might be hosted on the server. Standard files such as index pages and robots.txt are found with one directory titled webservices returning a 301 status.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220221_140754.png)

### Service Enumeration

#### HTTP Service Enumeration

Browsing to the HTTP service on the target machine returns a feature-less index.html page with ASCII art of a Tartarsauce bottle. Navigating to robots.txt with the browser (a more traditional user agent) shows the same entries found by Nmap earlier.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_093701.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_093731.png)

The /webservices directory redirects to /webservices/wp which appears to be a basic WordPress site. Inspecting the HTML code's references to other objects on the server shows that the true hostname of the target server is tartarsauce.htb. Adding this record to the /etc/hosts file on the attack machine allows the target machine to resolve assets on the target and allows the WordPress site to become functional.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_094533.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_094730.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_094810.png)

#### WP Scan

Since the site has been identified as a WordPress instance the open-source tool WP Scan is used to generate automated security scanning against the site. Security scan findings are limited but it does return that XML-RPC is enabled which can allow for username enumeration and detail of service. The WordPress base version of the site is running significantly out of date and is vulnerable to authenticated exploits.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_094610.png)

WP Scan did not find any plugins but inspecting the source code shows that a GWolle database is being used as the back end to the site. This is a database plugin that is developed by a third party and installed on some WordPress sites by the administrator to enable additional functionality.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_095801.png)

### Penetration

#### RFI GWolle DB

GWolle DB is is a Guestbook plugin for WordPress sites. The target is running version 1.5.3 which is vulnerable to remote file inclusion in its ajaxresponse.php endpoint through its abspath parameter. This endpoint can be fed a remote file address which will load wp-load.php at that address.

<https://www.exploit-db.com/exploits/38861>

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_095749.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_095907.png)

The exploitation example below shows that an HTTP server can be set up and curling our attack machine IP tries to call /wp-load.php. Since we can see that it's trying to remotely include this file we can create our malicious version of the wp-load.php page which is a PHP reverse shell to be rendered by the target machine. Doing so below shows a reverse shell returned as the www-data user.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_100219.png)

#### Shell Stabilization

The following example shows full shell stabilization that enables all interactive features through the given reverse shell. From here the file system can be enumerated within the file permissions of the www-data user on the target.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_100317.png)

#### File System Enumeration

WordPress servers have a template file structure for their back-end web service. The file wp-config.php is the file that has most of the configuration for the WordPress instance and most notably, the database credentials that allow the front end to authenticate and query the back-end MySQL database. Using the credentials found we can enumerate the back-end authentication database. A password hash for wpadmin is found but not easily crackable.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_100420.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_100516.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_100552.png)

#### Sudo Permissions

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_100614.png)

After enumerating sudo permissions on the target the www-data user can run a very specific command as another user on the box. The web service account can run tar as the Onuma user and there is a recorded 'GTFObin' for this binary that allows for command execution as the privileged user. Using this as shown below we can create a fully interactive shell as the Onuma user on the target machine.

<http://gtfobins.github.io/gtfobins/tar>

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_101028.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_101150.png)

### Privilege Escalation

Now that we have a user session as the Onuma user we can enumerate the file system with the permissions of the Onuma user. The Onuma user has a home directory where the user flag is stored and there are many other standard files. One notable file is the shadow_bkp that is being symlinked to /dev/null by root in the user's home. This doesn't appear to be directly relevant.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_101217.png)

#### Custom Binaries on Crontabs

Automated enumeration finds files that are routinely written to by root which would indicate an automated solution writing to the file system with root permissions. Given the frequency of these file writes we can enumerate processes further with Pspy to see what commands are being executed as root.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_102131.png)

A custom script at /usr/sbin/backuperer is being run with root-level permissions on the target. Luckily this script is readable by the Onuma user so we can further enumerate its functionality before attempting to exploit the process being run as root.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_103034.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_103128.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_103153.png)

In the script above /var/www/html is backed up to /var/tmp and then extracted to /var/tmp/check/var/www/html. If the files do not match the current /var/www/html directory then they are stored on the server in an exposed state for 30 seconds. During that time they are readable and executable as root since they are written by root during the process. By doing this we can drop our file into a malicious archive that is extracted onto the file system.

#### Exploit Development on Custom Script

The most simple way to utilize the functionality of a root file writes permission is to create an executable binary that drops SUID permissions. The screenshots below show the development of a C script that drops /bin/sh as a SUID file. We can compile this for the 32-bit target by using the -m32 option for gcc.

- (Fixed a 32-bit library issue with ``` sudo apt install gcc-multilib ```)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220213_165310.png)

After compiling the binary we have to change the file permissions and owner to root so that they are inherited upon the de-compression process with tar. The file structure is shown in the tar command as it must match the depth of the intended archive for proper file comparison.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220213_171732.png)

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220213_170048.png)

After transferring the tar archive to the target machine through ncat we can begin exploitation of the crontab. When watching in pspy we can see when it is executed. The files are moved and there is a 30-second section of time where a hidden file is generated with a random name starting with a period. During this time we can copy the tar archive over this temporary file.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220213_170213.png)

``` mv setuid.tar.gz ./.aa94... ```

Once this file has been copied the script will notice that there is a file difference between the temporary file and the current /var/www/html directory. When this happens the script will extract the tar archive into a directory called to check. By navigating into the directory we can access the SUID binary that we compiled and is now written as root. Executing the binary will drop a /bin/sh SUID session, creating a shell as root on the target machine.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220208_111149.png)

#### Root File System Access - Tar Exploitation

An easier way to enumerate the file system as root is using a symlink in the tar archive to point to the file in question. We can create the directory structure and then use a symlink to /root/root.txt in the tar archive. Compressing this and then performing the same actions will create a file read into an error file.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220213_174933.png)

When the symlinked archive is de-compressed and the file is not matching the contents are echoed into an onuma_backup_error.txt file that will have the contents of the file. Since root.txt is symlinked to the offending file it is echoed into the error file for us to read. The steps below show the successful exploitation of this method. This could be replicated with any other file on the target system including /etc/shadow.

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220213_171541.png)

`cat /var/backups/onuma_backup_error.txt`

![Screenshot](/assets/images/2022-02-17-Tartarsauce-HTB-Writeup/Screenshot_20220213_175326.png)

### Vulnerability Assessments

|---+---+---+---|
| Vulnerability | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| /usr/sbin/backuperer - Privilege Escalation | Critical | 0 | A customer binary on the target allows the Onuma user to escalate to root. |
| GWolle DB Out of Date - RFI | High | 0 | GWolle DB is running significantly out of date and is vulnerable to remote file inclusion. |
| Sudo Permissions Tar - Privilege Escalation | High | 0 | Sudo permissions allow for escalation from the www-data user to the Onuma user. |
