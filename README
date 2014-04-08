aaron
======
*In loving memory of tireless internet activist,* **"Aaron Swartz"** *.*<br>
Find a way to go *deep* inside your target network to get the "Arkenstone".<br>
Designed for hacktists, professional penetration testers and APT teams.

##About
Imagine those hard times that you were inside an unknown network trying to discover how things work by looking at anything, 
just to find out a way to go *deeper and deeper* inside that **jungle of connected electronic devices**.  Going deeper means you need
to find new targets, but how? Yes! That cool **netstat -an** command, shows valuable network information.<br>
But, did you ever try to analyze 10000 lines of *netstat* result? THAT'S HELL OF A HARD WORK! so you may use grep, awk, cut, sort, uniq and a bunch of | (pipes)
trying to make one those magical single line commands and reduce the netstat result to 1000 lines! That's geek but you need something more visual!

Any advanced hacking or black-box penetration testing project starts with a short list of known targets. After exploiting
one of those known targets, you should use all the information found inside that target to find new targets.
*Discovering* new HVTs is a key point for a successful security breach because you can go *deeper and deeper*.

**aaron** helps you do that in a more visual way!

##Why?
- You can understand data-flow inside your target network.
- You don't need to install it on remote target (e.g. libpcap) => less suspicious.
- Find high value targets by looking at a graphical map!

##Features
- Draw network graph of your local machine
- Draw a network graph based on results collected from several remote hosts
- Update an existing network graph
- Supports SSH, ADB and PSExec (SMB) protocols
- Export graphs in png and pdf formats

##TODO
- png examples folder<br>
- aaron search + regex <br>
- ADB<br>
- BSD test<br>
- Find os type automatically (--os=auto)

##more                                    
- Database:
   +----------------+           +-----------------+ <br>
   | Host           |           | Edge            | <br>
   +----------------+           +-----------------+ <br>
   | id (PK)        |           | id (PK)         | <br>
   | name           |           | src_ip_id (FK)  | <br>
   | info           |           | dst_ip_id       | <br>
   | deepinfo       |           | src_tag         | <br>
   | comment        |           | dst_tag         | <br>
   |                |           | proto           | <br>
   |                |           | comment         | <br>
   +----------------+           +-----------------+ <br>
          ^                          | |            <br>
          |                          | |            <br>
          |                          | |            <br>
          |    +----------------+    | |            <br>
          |    | IP             |    | |            <br>
          |    +----------------+    | |            <br>
          |    | id (PK)        |<---+ |            <br>
          +----| host_id (FK)   |<-----+            <br>
               | addr           |                   <br>
               | comment        |                   <br>
               |                |                   <br>
               +----------------+                   <br>

