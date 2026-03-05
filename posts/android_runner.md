# Idle Game Runner

## Introduction

I like to play games on my phone. Many of the games that I play fall into the
broad category of "idle" games, a type of game where you gain benefits after 
time away from the game. For example, a few hours after closing "Idle Obelisk
Miner", I open the game to find that my drones have amassed a neat pile of
resources, which I can use to further my progress in the game.

Some of these games further benefit from being _left running_ for long periods
of time. For example, in "Cell: Idle Factory Incremental" (better known as
CIFI), opening all of the daily token and diamond chests can take several hours
of _runtime_, something that doesn't happen when the game is not running.
Similarly, in "Idle Sword Master", achieving a high stage (and a corresponding
high place on the leaderboard) can take hours of fighting increasingly powerful
monsters.

I would have an advantage in these games if I could leave them running all the
time. But, I also want to use my phone sometimes, like when I want to make a
phone call, or when I want to play a different idle game. So, I found a way 
to offload the work of running the game to my computer, so I could free up my 
phone for other tasks. This article describes how to set up a virtual Android
device on a computer, and how to connect remotely to check in on progress. 

## Side-Quest: Run This in the Cloud

I briefly investigated running this in the cloud, but those servers are 
_expensive_! A t3.xlarge instance in AWS (4 vCPUs, 16GiB RAM) costs $70/month,
if you pay for a 3-year commitment up-front. On-demand is closer to $150/month.
This is much, much more expensive than running something on a PC in my basement,
but I think the prices make sense. My PC gets internet from a WiFi dongle 
plugged into a monitor, where AWS EC2 boasts redundant power and gigabit fiber. 

For this application, though, I don't _need_ all of the reliability guarantees
that account for that cost - I'm just playing video games. If I don't get five
nines of availability, that's totally fine (although over-engineering an idle
game farm would be a fun hobby project, someday). 

I also found that the AWS free-tier servers don't support the type of 
virtualization required to effectively emulate Android devices. Another cloud
provider might have this capability, but I elected to run local for now. 

## The Basics: Emulate an Android Device

The path to emulating an Android device is well-trodden, and will be familiar to
Android developers the world over. First, get Android Studio installed from 
https://developer.android.com/studio . I'm on Ubuntu, so the download provides 
a tarball that I have to unpack:

```
cd ~/Downloads
tar -xvf ./android-studio-panda1-patch1-linux.tar.gz
```

Then, I launch Android Studio, taking care to disconnect it from my shell session:

```
~/Downloads/android-studio/bin/studio &
disown
```

From here, I open the Virtual Device Manager, and configure a new device. From
the "Phone" Form Factor list, I select the "Small Phone" present - emulating 
the smallest possible screen will be easier on my aging computer. Importantly,
I select an x86\_64 system image, to match my computer's CPU - selecting an ARM
image results in an impossibly slow emulator. 

Even with the matching architecture, I found that the emulator was slow. `top`
showed CPU usage well over 200%. Fortunately, the Android developer 
documentation describes how to configure VM acceleration, allowing the emulator
to use my computer's hardware directly, rather than handling everything in 
software. 

The documentation is available here: https://developer.android.com/studio/run/emulator-acceleration#vm-linux

Here is the command I ran to permit VM acceleration - it looks like, as long as
the right system packages are installed, Android Studio will see them and
automatically enable VM acceleration.

```
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

This noticeably improved emulator performance. `top` shows the `qemu-system-x86` 
process using anywhere between 90% and 110% of one CPU. I'm able to interact 
with the emulated device to install and launch the game without issue! I've 
successfully offloaded the work of running the game to my computer, freeing up 
my phone for other useful tasks. 

TODO: Screenshot of the game running in the emulator. 

## Next Steps: Remote Access

As great as it is to have this game running on my computer, it's not nearly as
convenient as running the game on my phone. My phone fits into my pocket, but 
my computer is fixed in place in my basement. It sure would be great if I could
leave the game running on the computer, but check in on the game's progress 
using my phone.

I'm using the X Window System (X11, X) on Ubuntu, which I believe is the 
default window manager for Ubuntu. It's possible to configure X11 to permit 
remote access over VNC (Virtual Network Computing). 

## Side-Quest: VNC vs RDP

Most of my experience with controlling a graphical environment remotely is with
RDP, the Remote Desktop Protocol. This is common in Microsoft environments 
where a lot of the administration is performed in a GUI. I tried to get this 
working with the `xrdp` package (which installs the `xrdp` and `xrdp-sesman`
daemons). 

I was surprised to find that xrdp did not work correctly with "Windows App"
(formerly "Microsoft Remote Desktop"). I was able to start an RDP session with
my computer from my phone, but the screen was jumbled. I couldn't figure it
out after some experimenting, so I turned to xvnc. 

## VNC Set-Up

This set-up was simpler than expected, after some time trying to configure RDP
to work correctly. First, I installed `x11vnc`:

```
sudo apt-get install x11vnc
```

Then, I launched it, again taking care to disconnect it from my terminal session:

```
x11vnc -forever -display :0 -auth guess -noxdamage -scale 1 -nosel -nosetclipboard &
disown
```

First, install `xrdp`, an RDP server for Linux. This installs two daemons,
`xrdp` and `xrdp-sesman`, that work together to provide RDP functionality. 

```
sudo apt-get install xrdp
```

TODO: What is VNC?

TODO: Screenshot of the game running in the emulator from my phone. 



```
```

Breaks when I restart my phone, I think? Worth looking into.

Didn't work with "Windows App" (formerly Microsoft Remote Desktop), connected but the
lines were all broken. Works fine with "RVNC Viewer". 


