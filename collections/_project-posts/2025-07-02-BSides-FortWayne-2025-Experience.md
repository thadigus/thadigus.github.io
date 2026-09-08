---
title: "BSides Fort Wayne 2025 Conference Experience"
header: 
  teaser: /assets/images/2025-07-02-FortWayneBsides/BadgeDemo.jpg
  header: /assets/images/2025-07-02-FortWayneBsides/BadgeDemo.jpg
  og_image: /assets/images/2025-07-02-FortWayneBsides/BadgeDemo.jpg
excerpt: "The Fort Wayne BSides Information Security Conference in Fort Wayne, Indiana, took place on June 7th of 2025. I was privileged enough to play a large part in the development of the CTF challenges as well as the badge that was given to each attendee at the conference."
tags: [bsides, writeup, badge]
---
## BSides Fort Wayne - 2025

The Fort Wayne BSides Information Security Conference in Fort Wayne, Indiana, took place on June 7th of 2025. I was privileged enough to play a large part in the development of the CTF challenges as well as the badge that was given to each attendee at the conference. While serving on both of these teams I had the chance to work with some incredible people, and write **a lot** of code.

![Speaking on Stage](/assets/images/2025-07-02-FortWayneBsides/SpeakingStage.jpg)

### Badge Firmware Development

During the six months leading up to BSides this year I was lucky enough to work with an incredibly talented team. We were challenged to build upon the badge from last year: [a Badger2040](https://shop.pimoroni.com/products/badger-2040). In the previous two years all attendees recieved this badge with relatively minor modifications, but there was a considerable interest in hacking this off the shelf product. Personally, I was able to load my logo onto the device and edit the text on screen. This was what my Badger2040 looked like after my badge hacking experience in 2024.

![Badger2040 /w Logo](/assets/images/2025-07-02-FortWayneBsides/Badger2040.png)

We had noticed that the MicroPython firmware was really approachable for all skill levels, so it was an easy pick to start there. [Brett Gilsinger](https://www.linkedin.com/in/brettgilsinger/) was responsible for the hardware development. More information about the final product (including schematics for the circuit board) can be found in the [GitHub Repo](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/HARDWARE.md). To summarize, an ESP32-WROVER-E-N8R8 chip was chosen for it's affordability and performance. This chip ran two screens, an accelerometer, more than 7 LEDs, a buzzer, some buttons, and more.

![Badge Demo Picture](/assets/images/2025-07-02-FortWayneBsides/BadgeDemo.jpg)

After quite a bit of tooling around I was able to get a few things running on the badge. I had a simple demo and our MicroPython environment was working nicely. [Stephen Heindel](https://www.linkedin.com/in/stephen-heindel/) and [Luke Gilsinger](https://www.linkedin.com/in/lucas-gilsinger-6b84b2307/) built an entire framework for developing apps on this device. There were even built in drivers for components such as the screens and the buzzer. This would allow users to easily interact with components without needing to build their own interactions in MicroPython. Some great examples of apps on the device can be found in the apps portion of the [GitHub Repo](https://github.com/BSidesFortWayne/BSidesFW2025Badge/tree/main/src/apps) as well.

### CTF Challenges

My primary role on this team was a liaison position between the CTF team and the badge team. The CTF is a hacking competition that we put on every year to allow for some compeitive coding and hacking. Each year the team will build custom challenges for competitors to try to break. While I did create a few traditional challenges, I will refrain from any writeups on these in case we wish to use parts of them next year. Most of my challenges included simple Linux tricks to circumvent misconfigured systems security measures. This year, I also created six badge related challenges, that would require competitors to connect, hack, and script against their badges in order to retrieve flags from the device.

The foremost issue with creating CTF challenges in MicroPython was the fact that the code was source available. In order to help this issue, I elected to write all of the challenges in C and then compile them into the MicroPython binary as a [C User Module](https://docs.micropython.org/en/latest/develop/cmodules.html). We built an app for each challenge that may contain some limited MicroPython, but in reality, all of the challenge code was contained in a `badgechal` library that was available on the [device firmware](https://github.com/BSidesFortWayne/BSidesFW2025Badge/tree/main/firmware). We simply imported it and ran the code within the app. 

I have elected to author individual writeups for each of these challenges. In many cases, the apps are written to do something in MicroPython which will point the user in the right direction. Each writeup contains links to the app code, code blocks of the relevant custom C code, and solve steps. Some even include automated solve scripts which were written to demonstrate the functionality of the challenge. Each writeup is linked below:

- [BSides Fort Wayne 2025 Challenge 1](/htb-writeups/2025-07-02-BSFW2025-BadgeChallenge1-Writeup/)
- [BSides Fort Wayne 2025 Challenge 2](/htb-writeups/2025-07-02-BSFW2025-BadgeChallenge2-Writeup/)
- [BSides Fort Wayne 2025 Challenge 3](/htb-writeups/2025-07-02-BSFW2025-BadgeChallenge3-Writeup/)
- [BSides Fort Wayne 2025 Challenge 4](/htb-writeups/2025-07-02-BSFW2025-BadgeChallenge4-Writeup/)
- [BSides Fort Wayne 2025 Challenge 5](/htb-writeups/2025-07-02-BSFW2025-BadgeChallenge5-Writeup/)
- [BSides Fort Wayne 2025 Challenge 6](/htb-writeups/2025-07-02-BSFW2025-BadgeChallenge6-Writeup/)

### Badge Talk - Discussing our Development on the Main Stage

Since the badge was attracting some attention on [social media](https://www.linkedin.com/posts/bsidesfortwayne_look-what-our-bsidesfw-2025-badge-team-have-activity-7310614946717859840-4LM5?utm_source=social_share_send&utm_medium=member_desktop_web&rcm=ACoAADSzqJ0B26a3kOKQaQp_ySgL6M6eTI--J5s) and throughout the community, the badge team was asked to put on a talk about the development process. The team prepared a one hour long talk to discuss all facets of the badge development project. Each of us took a time slot to discuss the aspect of the badge for which we were responsible. My time slot was primarily dedicated to the custom code written and baked into the MicroPython binary for the CTF challenges.

![Speaking Header](/assets/images/2025-07-02-FortWayneBsides/SpeakingGraphic.jpg)

This talk was a huge success, and we ran out of time for questions. I was really happy with the turn out and I want to encourage anyone who still has questions to reach out to me directly on [LinkedIn](https://www.linkedin.com/in/thadigus/) because I would love to further discuss this exciting project. You can also catch me in the [BSides Fort Wayne Discord Server](https://discord.gg/tM4eZFFzjg). This was a really cool opportunity, and without the talented individuals on both the teams I serve, none of this would be possible.

![Main Ballroom](/assets/images/2025-07-02-FortWayneBsides/SpeakingRoom.jpg)

We are already discussing ideas for next year's badge. Please feel free to share any ideas/requests so we can work them into the project for next year. Some ideas for the future will include:

- Wireless Communication/Mesh Networking
- Time Syncing
- Speaker Schedule
