netmap
======
Find a way to go *deep* inside your target network to get the "Arkenstone".<br>

##About
Imagine those hard times that you were inside an unknown network trying to discover how things work by looking at anything, 
just to find out a way to go *deeper and deeer* inside that **jungle of connected electronic devices**.  Going deeper means you need
to find new targets, but how? Yes! Taht cool **netstat -an** command, shows valuable network information.<br>
But, did you ever try to analyse 10000 lines of *netstat* result? THAT'S HELL OF HARD WORK! so you may use grep, awk, cut, sort, uniq and a bunch of | (pipes)
tyrying to make one those magical single line commands and reduce the netstat result to 1000 lines! That's geek but you need something more visual!

Any advanced hacking or blackbox penetration testing project starts with a short list of known targets. After exploiting
one of those known targets, you should use all the information found inside that target to find new targets.
*Discovering* new HVTs is a key point for a successful security breach because you can go *deeper and deeper*.

**netmap** and **netmapolizer** will help you do that in a more visual way!

##Why?
- You can nderstand data-flow inside your target network.
- You don't need to install it on remote target (e.g. libpcap) => less suspicious.
- Find high value targets by looking at a graphical map!

##Features
- Draw network graph of your local machine
- Draw a network graph based on results collected from servral remote hosts
- Update an existing network graph
- Supports SSH, ADB and PSExec (SMB) protocols
- Export graphs in png and pdf formats

##TODO
- png examples folder<br>
- save hidden info on each node<br>
- netmapolizer (+ os/port/ip filter): 2/5<br>
- ADB<br>
- Solaris test<br>
- BSD test<br>
- Find os type automatically
