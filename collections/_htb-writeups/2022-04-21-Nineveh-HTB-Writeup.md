---
title: "Nineveh - HTB Writeup"
header: 
  teaser: /assets/images/2022-04-21-Nineveh-HTB-Writeup/Nineveh-HTB-Image.png
  header: /assets/images/2022-04-21-Nineveh-HTB-Writeup/Nineveh-HTB-Image.png
  og_image: /assets/images/2022-04-21-Nineveh-HTB-Writeup/Nineveh-HTB-Image.png
excerpt: "The HTTPS service is running phpLIteAdmin version 1.9. While a username is not required a simple password is used for authentication for users connecting to the service. There appears to be an error at the top of the page which reveals the global path to the web server on the target host."
tags: [htb, writeup, nineveh]
---
## Nineveh

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232629.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232643.png)

#### Nmap HTTP Vulnerability Scan

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232614.png)

#### Nmap HTTPS Vulnerability Scan

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232727.png)

### Service Enumeration

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232821.png)

#### FFuF Web Enumeration on Port 80

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232838.png)

#### SSL Scan on Port 443

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232858.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232913.png)

#### Nikto Web Scan on Port 443

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232932.png)

#### FFuF Web Enumeration on Port 443

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220414_232950.png)

#### HTTP Service Enumeration

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_130126.png)

#### HTTPS Service Enumeration

The HTTPS service is running phpLIteAdmin version 1.9. While a username is not required a simple password is used for authentication for users connecting to the service. There appears to be an error at the top of the page which reveals the global path to the web server on the target host.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_130330_1.png)

### Penetration

#### phpLiteAdmin Password Brute Forcing

A simple Hydra command can be used to brute force the password authentication is used to protect the target site. By using `rockyou.txt` we discover that the password is `password123`.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_130832.png)

#### /department Web Enumeration

A custom web service is located at /department on the HTTP service running on port 80. This is yet another login page that requires a username and password combination. Further enumeration shows that the site does not return much data unless the user is authenticated first.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_130922.png)

#### /department Login Brute Forcing

Using Hydra once again to brute force the password we can use `rockyou.txt` and discover the password for the admin user. The admin username was chosen since it is a common username. The target site does not appear to allow for username enumeration. The credentials found are documented below.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_131450.png)

#### PHPLiteAdmin Authenticated RCE Exploitation

The phpLiteAdmin service is running version 1.9 which is vulnerable to an authenticated remote code execution. Since we have the administrative password we can carry out this attack by injecting PHP into a database file as documented below.

<https://www.exploit-db.com/exploits/24044>

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_131422.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_131541.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_131758.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_132431.png)

#### /department Development manage.php LFI

While we cannot render the database that has had PHP code injected into it, the /department custom web service appears to be vulnerable to a local file inclusion attack. The notes section of the web service loads in the other database that is available on the phpLIteAdmin service titled notes. We can replace this file path supplied with the discovered file path of the code-injected database to render the PHP code on the server.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_132042.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_132137.png)

#### www-data User Shell

Exploiting the local file inclusion vulnerability and rendering the PHP code on the target server we are returned a reverse shell as the www-data user on the target server. Below shows a basic shell upgrade and stabilization.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_132609.png)

### Privilege Escalation

#### SSH Key Found in nineveh.png

A PNG file titled `nineveh.png` is stored in `/var/www/ssl/secure_notes`. Running strings on this file shows that there is a basic stenography file being used. An SSH key found in this file can be exfiltrated to the attacking machine.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_132946.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_133009.png)

#### Knockd Configuration Enumeration

The SSH shell does not work after being exfiltrated into a local RSA key. The further enumeration in the www-data user shell shows that there is a Knockd configuration on the target server. It appears that the SSH service is blocked, but by performing the correct combination of port knocking port 22 will be opened to the local network.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_134226.png)

#### Amrois User Shell over SSH

After setting the correct file permissions for the Amrois SSH RSA key and performing the port-knocking command shown in the second screenshot, SSH opens on the target server. Once authentication succeeds a user shell as the Amrois is spawned.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_133233.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_134500.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_134522.png)

#### Amrois User Shell Enumeration

An automated privilege escalation enumeration script LinPEAS is run to enumerate the user shell on the target server. The script at `/usr/sbin/report-reset.sh` is being run on a crontab as shown below. This script simply deleted the text files that are stored in the /report directory.

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_134931.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_134952.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_135138.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_135237.png)

#### Chkrootkit Privilege Escalation Exploitation

The script as `/usr/sbin/report-reset.sh` is running a cleanup task for logs generated by `chkrootkit` as is evident by the static file analysis in the previous step. The version on the target server is vulnerable to a local privileges escalation as the program will arbitrarily run whatever is located at `/tmp/update` as root on the target server. By placing a reverse shell at `/tmp/update` we spawn a reverse shell as root.

<https://www.exploit-db.com/exploits/33899>

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_135553.png)

![Screenshot](/assets/images/2022-04-21-Nineveh-HTB-Writeup/Screenshot_20220415_135627.png)
