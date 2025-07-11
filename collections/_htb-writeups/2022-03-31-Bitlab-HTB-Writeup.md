---
title: "Bitlab - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-31-Bitlab-HTB-Writeup/Bitlab-HTB-Image.png
  header: /assets/images/2022-03-31-Bitlab-HTB-Writeup/Bitlab-HTB-Image.png
  og_image: /assets/images/2022-03-31-Bitlab-HTB-Writeup/Bitlab-HTB-Image.png
excerpt: "After thorough web service enumeration, a blog can be found at /profile which refers to the /help endpoint. The /help directory has a bookmarks.html file. Upon loading the file we can see that there is custom JavaScript for accessing the Gitlab bookmark. The JavaScript attempts to obfuscate a password that is being used to log into Gitlab. Bringing this code into our debugger allows us to pull the Clave user's credentials."
tags: [htb, writeup, bitlab]
---
## Bitlab

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_183013.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_183027.png)

### Service Enumeration

#### HTTP Scripted Enumeration

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_183108.png)

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_183132.png)

#### Gobuster Web Enumeration

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_191238.png)

#### Gitlab Service on Port 80

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_192237.png)

#### Blog at /profile on Port 80

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_192354.png)

#### Directory Listing at /help

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_192411.png)

### Penetration

#### JavaScript Data /help/bookmarks.html

After thorough web service enumeration, a blog can be found at /profile which refers to the /help endpoint. The /help directory has a bookmarks.html file. Upon loading the file we can see that there is custom JavaScript for accessing the Gitlab bookmark. The JavaScript attempts to obfuscate a password that is being used to log into Gitlab. Bringing this code into our debugger allows us to pull the Clave user's credentials.

`clave:11des0081x`

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_192600.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_193301.png)

### Gitlab Enumeration

Using the locally available credentials to sign into the GitLab instance provides access to two directories: Profile and Deployer. While the Profile has multiple branches there aren't any significant changes to the code base. The Profile repository appears to be the blog website, providing source code for what is running on the target server.

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_193530.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_194107.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_194116.png)

#### Auto Deployment Implementation

It appears that one code repository on the Gitlab instance named Deployer will automatically commit changes as they are made using a bash command.

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_195957.png)

#### Write Code to Git Repository

The index.php page of the Profile Git repository is the index.php page of the profile blog site found earlier. Since we have permission to write to it, and the code will automatically be deployed, we can write a backdoor into the site and then abuse it on the live site.

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_200429.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_200448.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_200502.png)

#### Backdoor Shell Exploitation

Now that a backdoor shell is uploaded to the live website we can simply browse to it to use the shell command module hosted on the website. Running `whoami` shows that the web service is being run by the `www-data` user. By utilizing a simple Bash reverse shell we can spawn a reverse shell as the www-data user on the target server.

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_200558.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_200608.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_200738.png)

### Privilege Escalation

#### www-data User Shell Enumeration

The www-data user has sudo permissions to run git pull with no password. This is being utilized by the deployment script to pull the git repository down from the Gitlab instance when commits are made against the repository.

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_205318.png)

#### Sudo Permission Exploitation

A simple bash script can be run when a Git repository is updated with Git pull. Since sudo allows us to run this process as root with no password we can abuse this by copying the current live repository in /var/www/html/profile into a temporary file. After this, we add our Bash command for a reverse shell as root to the repository. After logging back into Gitlab create some sort of change on the master branch so that the pull will run. Running sudo /usr/bin/gitpull in the git repository will run the bash reverse shell as root. Steps to reproduce are documented below.

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_205540.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_205815.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_205826.png)

![Screenshot](/assets/images/2022-03-31-Bitlab-HTB-Writeup/Screenshot_20220331_210018.png)
