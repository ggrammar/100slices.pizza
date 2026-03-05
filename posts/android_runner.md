# Idle Games

## Introduction

I like to play games on my phone. Many of the games that I play fall into the
wide category of "idle" games, a type of game where you gain benefits after 
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
time. But, I also want to use my phone for things like making phone calls, or
playing different idle games. So, I found a way to offload the work of running
the game to my computer, so I could free up my phone for other tasks. This
article describes how to set up a virtual Android device on a computer, and how
to connect remotely to check in on progress. 

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

## 


I briefly investigated running this in the cloud, but these servers are _expensive_!
A t3.xlarge instance in AWS (4 vCPUs, 16GiB RAM) runs anywhere from $70-$150/month,
which is much more than I would like to pay to run a phone game. I investigated the
AWS free tier, which would be good for 6 months, but the servers there don't support
the type of virtualization required to run Android devices (TODO: more detail here?)

So, I'm running this on the computer in my basement. It's an Intel Core i5-4690 (3.50GHz)
with 8GB DDR3 - this computer was old 5 years ago, but it's strong enough to run an 
Android emulator. I'll need to upgrade the motherboard to make any serious upgrades 
to the machine, which will be the subject of a separate post! 

First, got Android studio installed from https://developer.android.com/studio

```
cd ~/Downloads
tar -xvf ./android-studio-panda1-patch1-linux.tar.gz
```

Then, I launch it with:

```
~/Downloads/android-studio/bin/studio &
disown
```

```
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

Noticeably improved performance of the emulator - not sure how this works, worth
looking in to. 

Now, I've offloaded the work of running the game to my computer, so my phone is 
freed up. But I'd still like to check in on the game from my phone from time to 
time! 

sudo apt-get install xrdp
xrdp xrdp-sesman

```
x11vnc -forever -display :0 -auth guess -noxdamage -scale 1 -nosel -nosetclipboard &
disown
```

Breaks when I restart my phone, I think? Worth looking into.

Didn't work with "Windows App" (formerly Microsoft Remote Desktop), connected but the
lines were all broken. Works fine with "RVNC Viewer". 

Had to add this to `/etc/xrdp/xrdp.ini`:

```
[xrdp1-loggedin]
name=Local Active Session
lib=libvnc.so
ip=127.0.0.1
port=5900
username=grammar
password=ask
delay_ms=2000
```


