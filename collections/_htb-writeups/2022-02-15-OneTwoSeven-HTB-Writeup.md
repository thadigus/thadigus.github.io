---
title: "OneTwoSeven - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/OneTwoSeven-HTB-Image.png
  header: /assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/OneTwoSeven-HTB-Image.png
  og_image: /assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/OneTwoSeven-HTB-Image.png
excerpt: "A statically configured password hash is found for the admin user. We can also see that there is a template site running on top of Jekyll 3.8.5."
tags: [htb, writeup, onetwoseven]
---

## OneTwoSeven - Methodologies

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220224_122551.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220224_122604.png)

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220224_122534.png)

### Service Enumeration

#### SFTP Hosting

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_132155.png)

#### IPv6 Reference

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_132216.png)

#### Web Service Enumeration

Signing up

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_132354.png)

Hostname revealed

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_132428.png)

After adding onetwoseven.htb to /etc/hosts

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_132833.png)

We can put files onto the server in the public_html but we cannot access them on a web server...

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_133536.png)

### Penetration

#### SFTP Service Exploitation

We can symlink root to a file and browse the file system with limited capacity.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_134407.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_134434.png)

Most directories return forbidden we have very limited access but we can enumerate the web application source code.

#### Administrator User Hash

`.login.php.swp`

A statically configured password hash is found for the admin user. We can also see that there is a template site running on top of Jekyll 3.8.5.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_134640.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_134745.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_135208.png)

`ots-admin:Homesweethome1`

#### Administrator Web Login

Admin is greyed out

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_135455.png)

Looking further into the login source code we see that this is running on 60080. That port is not exposed to the local network so it must be running on localhost. Since we have our SFTP access we can port forward the local web server.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_140220.png)

Browsing to `http://localhost:60080` shows the OneTwoSeven Administration Back End, where we can log in with our stolen credentials.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_140347.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_140605.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_144137.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_144257.png)

#### Plugin Upload to Reverse Shell

File upload is disabled but we can see the source code.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_145039.png)

By deleting the disabled parameter on the submit button we can re-enable the file upload functionality. We can try to upload a PHP reverse shell and then intercept it to work on bypassing the file upload functionality.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_151105.png)

Posting our upload returns a 404 not found, but the source code referenced a /addon-download.php and included a few parameters in its request. We can try to mimic this functionality to get a file upload.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_151812.png)

The file can be executed by visiting `/addons/rev.php`

#### Shell as www-admin-data

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_152851.png)

### Privilege Escalation

#### Sudo Enumeration www-admin-data

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_153005.png)

While a few GTFO Bins exist for this program our privileges are locked down to the point that we can only run update and upgrade. We can point this process to our attacking machine by adding ourselves to the sources list.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_154348.png)

We cannot edit the sources list, but we can confirm that the source is pointed toward <http://packages.onetwoseven.htb/devaun>, and the sudo -l listing states that the http_proxy environment variable is kept as sudo is executed, meaning we can set it without user context and it will stay in the command. This effectively gives us Man in the Middle permissions on the apt update and upgrade process by adding ourselves as the proxy for the process.

We can set up an HTTP server to respond to the requests and use Burp as our proxy. To properly resolve the hostname we can to our attacking machine we have to add it to the localhost record in /etc/hosts.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_154650.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_154835.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_154913.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_155042.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_155047.png)

There is a quick time out, turning off intercept allows us to see the requests on the HTTP server.

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_155141.png)

#### APT Repository Poisoning

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_160608.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_160833.png)

Size is the ls -la size of the deb file

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_161227.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_162256.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_162726.png)

`sudo apt-get update`

`sudo apt-get upgrade`

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_162908.png)

![Screenshot](/assets/images/2022-02-15-OneTwoSeven-HTB-Writeup/Screenshot_20220214_162951.png)
