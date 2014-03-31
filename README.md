netmap
======
Find a way to go *deep* inside your target network to find the "Arkenstone".<br>

##About
Imagine those hard times that you were inside an unknown network trying to discover how things work looking at anything, 
just to find out a way to go *deeper and deeer* inside that jungle of connected electronic devices.  Going deeper means you need
to find new targets, but how? Then somehow you remembered that cool **netstat -an** command which show's valuable network information.<br>
Did you ever try to analyse 5000 lines on *netstat* result? THAT'S REALLY HARD!<br>
An advanced hacking or blackbox penetration testing project starts with a short list of known targets. after compromising
one of those known targets, you should find new ones. *Discovering* new HVTs is a key point for a successful security breach
because you can go *deeper and deeper*.<br>
**netmap** and **netmapolizer** will help you do that.

##Why?
- Understand data/information flow inside your target network
- No need to install it on remote target (e.g. libpcap), so it's less suspicious.
- Find high value targets

##Features:
- Draw network graph of your local machine
- Draw a network graph based on results collected from servral remote hosts
- Update an existing network graph
- Supports SSH, ADB and PSExec (SMB) protocols
- Export graphs in png and pdf formats

##TODO:
- png example folder<br>
- save hidden info on each node<br>
- netmapolizer (+ os/port/ip filter): 1/5<br>
- ADB<br>
- Solaris test<br>
- BSD test<br>
- Find os type automatically

