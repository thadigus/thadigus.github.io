---
title: "Lightweight - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-03-Lightweight-HTB-Writeup/Lightweight-HTB-Image.png
  header: /assets/images/2022-03-03-Lightweight-HTB-Writeup/Lightweight-HTB-Image.png
  og_image: /assets/images/2022-03-03-Lightweight-HTB-Writeup/Lightweight-HTB-Image.png
excerpt: "The service indicates that users are automatically generated on the target server and we can use our IP address as the username and password to SSH into the box. Doing show below shows a relatively limited shell."
tags: [htb, writeup, lightweight]
---
## Lightweight

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_185946.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_185955.png)

### Service Enumeration

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_190026.png)

#### FFuF Web Enumeration on Port 80

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_190038.png)

#### LDAP Search Enumeration

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_190216.png)

### HTTP Service Enumeration

The service is very resistant to enumeration by returning random values and such.

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_190432.png)

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_190500.png)

### Penetration

#### SSH Foothold

The service indicates that users are automatically generated on the target server and we can use our IP address as the username and password to SSH into the box. Doing show below shows a relatively limited shell.

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_190556.png)

#### SSH Shell Enumeration

After running an automated enumeration script such as LinPEAS we can see that tcpdump has non-standard permissions and by running it within our user context we can read the data coming across the Ethernet adapter and listen to network traffic.

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_190929.png)

#### TCP Dump Monitoring for LDAP

Using the steps below we can use tcpdump to create a network packet capture and then exfiltrate the capture file.

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_191817.png)

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_191904.png)

#### TCP Dump Enumeration - LDAP User Creds

LDAP user credentials are found in the packet transmission in clear text.

`ldapuser2:8bc8251332abe1d7f105d3e53ad39ac2`

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_191951.png)

#### Ldapuser2 Shell

Using the found credentials we can su to the ldapuser2.

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_192208.png)

#### Backup.7z Password Cracking

A file called backup.7z is found in the home folder of the ldapuser2 but it is password protected. After using nc to bring it over to the attacking machine for offline cracking we can find the password and unzip the folder.

Password: `delete`

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_193213.png)

`sudo apt-get install -y libcompress-raw-lzma-perl`

`7z2john backup.7z > backup.hash`

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_193656.png)

#### Status.php Backup Ldapuser1 Creds

Using the found password we can unzip the backup.7z file. Searching status.php from the backup reveals the user credentials for ldapuser1.

`ldapuser1:f3ca9d298a553da117442deeb6fa932d`

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_193737.png)

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_193754.png)

#### Ldapuser1 User Shell

Using the found password we can su to the ldapuser1 user on the target server.

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_193836.png)

### Privilege Escalation

#### Ldapuser1 User Shell Enumeration

OpenSSL is available in the home directory, using Linpeas to easily enumerate binary capabilities again we can see that this is assigned the empty privilege of ep which means that it will simply execute as root just like a SUID. OpenSSL is a simple program but it can write to the file system if done properly and we can use this to gain a root shell.

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_194654.png)

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_194707.png)

![Screenshot](/assets/images/2022-03-03-Lightweight-HTB-Writeup/Screenshot_20220319_194734.png)
