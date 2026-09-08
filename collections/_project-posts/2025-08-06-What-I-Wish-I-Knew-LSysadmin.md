---
title: "What I Wish I Knew Before I Was a Linux Systems Administrator"
header: 
  teaser: /assets/images/2025-08-06-What-I-Wish-I-Knew-LSysadmin/serverroom.png
  header: /assets/images/2025-08-06-What-I-Wish-I-Knew-LSysadmin/serverroom.png
  og_image: /assets/images/2025-08-06-What-I-Wish-I-Knew-LSysadmin/serverroom.png
excerpt: "When I was 13 years old in a middle school class, I was tasked with looking up careers and developing a plan for what I wanted to be when I grew up. For a lot of kids, this was a difficult question, but ever since I started on Windows Millennium and played Fury3 at a young age, I knew I wanted to work with computers for a living. At that age, I hadn't started coding, and I wouldn't write my first console application (in C#) until late high school. Most of my interest was in hosting game servers and file shares for my friends and family."
tags: [blog, arch, rhel, el, suse, slackware, ubuntu, debian, systems, infrastructure]
---
## Starting with a Goal in Mind

When I was 13 years old in a middle school class, I was tasked with looking up careers and developing a plan for *what I wanted to be when I grew up*. For a lot of kids, this was a difficult question, but ever since I started on Windows Millennium and played [Fury3](https://en.wikipedia.org/wiki/Fury3) at a young age, I knew I wanted to work with computers for a living. At that age, I hadn't started coding, and I wouldn't write my first console application (in C#) until late high school. Most of my interest was in hosting game servers and file shares for my friends and family. 

I found joy in connecting machines and centralizing information. The fact that I could open a file on my desktop, edit it, and then open it on my dad's laptop with the same changes gave me a sense of wonder. Our middle school project instructed us to pick out jobs from the BLS website to research. All those years ago, I stumbled across a [Network and Systems Administrator](https://www.bls.gov/ooh/computer-and-information-technology/network-and-computer-systems-administrators.htm) entry, and it stuck. At the age of 13, Systems Administrator became my dream job.

### Achieving my Dream Job at 21

I seriously laugh at it now, but I'm proud to say that I started my dream job at the ripe age of 21 years old. I suppose my younger self had thought of this as a position for a lot later in my career. After serving my 9 months on the support side of IT in an internship and only a few months before I finished my third and final year of undergraduate school, I was hired as a Unix Systems Administrator for a large health organization in the next major city over. On top of the dream title, I was also fully remote, and I was happy to put a 50-minute commute to my previous job in the past.

Once I started my new job, I realized I was in the deep end. Fully remote work meant that I had to manage my own time and become relatively autonomous as quickly as possible. Luckily, I was paired with an excellent mentor, and I was just barely able to learn faster than they could find out how little I knew. Since this was my first full-time gig, and I was completely uninitiated to the sysadmin world, I had to learn quite a few things on the fly. I hope to catalog some of the things I wish I knew before I dove in headfirst.

## What I Wish I Knew Before Becoming a Linux Systems Administrator

In the following sections, I'm going to try to summarize the technical steps I wish I had taken to better prepare for my Linux Sysadmin job. There's an infinite list of preparation, but these are the topics that would've saved me the most trouble if I had learned them sooner. This is also based on my experience, so most of this will be pretty EL distro heavy simply because that's the environment I was working in.

#### Learn More Than Debian

When I started at my job, the extent of my Linux systems experience was Ubuntu Linux as a daily driver and a few Ubuntu servers. Up until my first day, I had never once jumped on the command line of an EL distro (shown in red on the [periodic table of Linux distros](https://distrowatch.com/dwres.php?resource=family-tree)). I had also made the mistake of saying that my Ubuntu experience was Debian experience. While they both use `apt`, an experienced admin will note that Ubuntu and Debian are two different beasts. Your experience on either will translate to the other, but do not make the mistake of equating the two in an interview. Definitely don't say your MacBook has given you Linux experience either (yes, that actually happened in an interview for our team)...

In my time as a Linux Sysadmin, I was managing all EL-based distros. In order to learn these quickly, I would highly suggest [Red Hat's Developer program](https://developers.redhat.com/). With a simple sign-up, you can get 16 Red Hat Enterprise Linux licenses for use in your home lab. During the time I was working as an EL-focused sysadmin, my entire home lab ran on RHEL 9 developer licenses in VMs on Proxmox. If you can enter an interview saying that you've managed Ubuntu Servers and RHEL Servers in your home lab, you will immediately have a leg up on almost every other candidate that specializes in one or the other. The same is true for Slackware based distros such as openSUSE Leap, which will allow you to get familiar with YaST and the quirks of that family. If you can run the big three enterprise-grade Linux families (Ubuntu/Debian, RHEL, SUSE) in your home lab long enough to gain proficiency, then you will suddenly make yourself applicable to almost any business running Linux. If you pick one to specialize in, you will need to be conscious of that when you apply for jobs.

#### Exploring EFI/Grub/Initrd - The Boot Cycle

I spent close to 2 years as a Linux Sysadmin before I had actually learned how the motherboard calls the EFI executable all the way until the system eventually makes it to the login screen. It was actually as part of a different personal project that I had to learn these steps, but soon after, I was working on migrating our provisioning process and newest servers to EFI boot. Previously, I had only relied on the OS installer to make sure that our bootloader and configuration were installed properly. Luckily, most enterprise-grade distros don't have too many knobs to turn inside the boot process, and Anaconda did most of the heavy lifting even when using Kickstart for me. 

It wasn't until I started migrating my personal machine to [Arch Linux](https://archlinux.org/) that I had to sit down and teach myself this. To this day, I would recommend that everyone grab an Arch Linux ISO and attempt to install Arch into a VM (with EFI boot enabled). While `Archinstall` is a wonderful tool, for educational purposes, I would suggest that you comb through the [installation guide on the Arch Wiki](https://wiki.archlinux.org/title/Installation_guide) to learn how the sausage is made. First, you will need to learn disk management (partitioning, LVM, MDADM, formatting, fstab) from the ground up as you stand up new hardware by hand. Then you'll chroot and bootstrap your first Arch install. Lastly, you'll need to install and configure your bootloader (likely Grub) and set up your first Initramfs.

It's not an elitist perspective that I recommend all Linux enthusiasts learn to install Arch. I just believe that Arch is the best hands-off distro for performing this process manually. The Arch Wiki and general support online will get you anywhere you need to go. Hopefully, I will release my Arch installation guide (for security) soon as well.

#### Logs Are Your Friend

When developers write incredible pieces of software like [Systemd](https://en.wikipedia.org/wiki/Systemd) they spend an inordinate amount of time working on sophisticated logging systems to standardize the way that your services are able to communicate the happenings of the system. While logs are rarely the glamorized facet of Linux systems administration, locating and understanding logs are absolutely critical to most tasks as a sysadmin. Because of this, it is critical to learn common log workflows. For RHEL, it's `/var/log/messages` and `/var/log/secure` in the case of most OS debugging. 

Learning to use [journalctl](https://www.man7.org/linux/man-pages/man1/journalctl.1.html) on most enterprise distros will enable you to debug most services that are managed by Systemd. Remember that journals are only shown in the user context for the query that was run. This means that unprivileged users don't always have the permissions necessary to access journals from other processes.

In order to sharpen log investigation skills, I would suggest that everyone learns `grep`, `vim`, and the `tail -f` command. Any flat file logs will be searched through manually. Learning the skills of searching with `grep` and using `sed` syntax inside of `vim` will serve you well. For learning journalctl, I would recommend that admins try to learn the most commonly used [Systemd Journal Fields](https://www.man7.org/linux/man-pages/man7/systemd.journal-fields.7.html) so they know what they can search for in their queries. All of this is another great opportunity for something you can learn in your home lab at no cost. Demonstrating that you know how to work within Systemd and Journalctl will put you above most candidates who walk in with a more limited understanding.

#### Documentation Isn't Fun

Neither reading nor writing documentation is a fun task. Both require a skill that is developed over time. Working on a team will simply require good documentation writing skills. Learning a new technology or process in any facet of IT will require that you quickly synthesize written instructions.

Writing documentation for the work that you do is paramount to working on a team. You might even read your own documentation years later. One of the questions I would always ask during interviews for our team is: "Can you tell us about a time when you had to demonstrate good documentation skills? How has documentation affected your projects in the past?" We had to ensure that someone joining our team understood the importance of sharing their work with others.

In the era of generative AI, it's unacceptable to have poor documentation. If you explain to ChatGPT what you did, as if an intern were looking over your shoulder, you can get perfectly formatted documentation that only needs a quick review for mistakes.

Another issue with many growing administrators is the over-reliance on YouTube videos and quick tutorials to learn a new technique. Often, this will result in a shallow understanding of a product. Once they encounter an issue outside of the scope of existing tutorials, they are left with a mess of configuration they do not understand.

I fell into this situation when I first learned about containers. I would follow [Techno Tim's](https://www.youtube.com/@TechnoTim) video to get started, and then I wouldn't be able to translate anything I thought I learned to another project. The simple matter of fact is that you need to become comfortable reading documentation and studying it to actually learn the tools you're using.

#### To Use Or Not To Use - AI

On the topic of not actually learning, I would find myself using AI to "learn" to code. When I was done "learning" for the night, I scrolled through code I didn't actually understand. Because of this, I've had to meter my relationship with generative AI when I try to learn new concepts. It's too easy for AI to write the code and iterate into something that will work, but in the end, I didn't learn anything.

I've set rules for myself: If the project is for work, I can rely more heavily on generative AI because it is important to perform this work quickly and ensure I'm adding the most value with my time. If the effort is for a personal project, where I'm trying to learn a new technology, I will severely limit my use of AI. Typically, this will be limited to using AI to explain and teach me about existing code or helping me understand a very specific error I'm seeing in my own code.

The current state of AI (in the Summer of 2025) is not to the point where you want to turn it loose on your environment. ChatGPT is like a good intern, with more confidence than it deserves. When you start to let ChatGPT run with an idea, you can find yourself down a tunnel with blinders on, and you'll be left with a code base you have to perform a `git reset` on. GitHub Co-Pilot is an amazing auto-complete, and ChatGPT can explain existing code very well, but neither does very well at writing their own code.

With this in mind, we have to apply the same principles to our systems administration duties. **Never blindly paste commands into a shell that you don't understand.** Rather, generative AI does a decent job at analyzing logs (with limited token length).

#### Learn How to Check Vital Signs

Here are a few commands I wish I knew on my first day. Hopefully, all of these are no-brainer commands that everyone knows, but I have no problem admitting that I didn't know any of these on my first day. I was blessed to have a mentor who didn't shame me for how little I knew.

`free -h` – Displays system memory usage (RAM and swap) in a human-readable format (e.g., MB, GB).

`df -h` – Shows disk space usage for all mounted filesystems, using human-readable sizes.

`du -sh ./*` – Summarizes the disk usage of each item (file or folder) in the current directory in human-readable format. This will show the actual size of each file.

`tail -f` – Continuously monitors and displays the end (last lines) of a file, useful for watching log files in real-time.

`ps -ef | grep <NAME>` – Lists all running processes and filters the output to show those matching a particular name (useful for finding specific processes).

Learn to use `top` or `htop` (depending on your distro and configuration), because these are essentially the Task Manager of the Linux world. Both of these tools will tell you utilization metrics for any process running on the box. When you need to find out what is hogging all of the resources. Do a little bit of research on [niceness](https://en.wikipedia.org/wiki/Nice_(Unix)) as well.

Lastly, I'd like to throw an honorable mention to [`sar`,](https://www.man7.org/linux/man-pages/man1/sar.1.html) which is a tool for monitoring and logging almost all detailed system activity. I'd say that this is a fairly advanced tool to use, but if you can learn it and demonstrate it in an interview, you will impress a lot of people.

### Why You Should Become a Linux Systems Administrator

I want to make sure that I express how rewarding this career has been, and even though I'm moving away from my Linux specialization, I will dearly miss it. 

For anyone who is a Linux enthusiast, I want to encourage you to seek out a sysadmin job. If you can find a position like mine, where you don't need to touch any OS other than Linux, and your Windows workstation is simply a formality to get onto a terminal, then I promise you will have a lot of fun.
