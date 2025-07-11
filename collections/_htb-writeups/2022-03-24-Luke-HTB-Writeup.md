---
title: "Luke - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-24-Luke-HTB-Writeup/Luke-HTB-Image.png
  header: /assets/images/2022-03-24-Luke-HTB-Writeup/Luke-HTB-Image.png
  og_image: /assets/images/2022-03-24-Luke-HTB-Writeup/Luke-HTB-Image.png
excerpt: "Web service enumeration reveals a config.php file that appears to be malformed PHP with typos that allow it to be rendered to the screen as ASCII text. Because of this mistake, all users on the local network can render the contents of the intended code which has sensitive credentials for the SQL server behind the web service."
tags: [htb, writeup, luke]
---
## Luke

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_205915.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_205922.png)

#### Nmap HTTP Script Scan

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_205943.png)

### Service Enumeration

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_210002.png)

#### FFuF Web Enumeration on Port 80

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_210013.png)

#### Nikto Web Scan on Port 3000

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_210026.png)

#### FFuF Web Enumeration on Port 3000

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_210033.png)

#### Nikto Web Scan on Port 8000

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_210048.png)

#### FTP Enumeration

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_202947.png)

#### Gobuster Enumeration on Port 80

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_210121.png)

#### Web Service Enumeration

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_203153.png)

#### /management Endpoint

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_203210.png)

#### Gobuster Enumeration on Port 3000

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_210140.png)

### Penetration

#### Config.php Web File

Web service enumeration reveals a config.php file that appears to be malformed PHP with typos that allow it to be rendered to the screen as ASCII text. Because of this mistake, all users on the local network can render the contents of the intended code which has sensitive credentials for the SQL server behind the web service.

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_203102.png)

#### Web Service on Port 3000

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_203325.png)

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_203447_1.png)

#### JSON Web Service Enumeration

The web service on port 3000 is a JSON API that appears to require authentication. By using our previously discovered credentials we can enumerate the JSON API.

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_203838.png)

#### JSON User Enumeration

The JSON API appears to have a list of users and passwords stored in a database. With our stolen credentials we can read this list, revealing username and password combinations for the target service.

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_204032.png)

#### /management Login with Credentials

The /management endpoint has a login prompt. Using the credentials for Derry that we found in the previous step we can log into the management portion of the service. This drops the attacker into a file directory listing.

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_204228.png)

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_204239.png)

### Privilege Escalation

#### /management/config.json Credentials

The /management/config.json file is behind the /management login prompt, but when using our stolen credentials we can view the file. The file shows more credentials for an Ajenti service.

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_204347.png)

#### Ajenti Exploitation on Port 8000

The web service on port 8000 is the Ajenti service that is referenced in the previous step. Using the credentials found in /management/config.json we can log into the application. A feature of Ajenti is that it can spawn a bash shell of the server behind it. Using this we can spawn a reverse shell as root on the target machine.

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_204620.png)

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_204653.png)

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_205021.png)

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_205413.png)

![Screenshot](/assets/images/2022-03-24-Luke-HTB-Writeup/Screenshot_20220324_205523.png)
