$nm_version = "0.1u" # u: unstable, t: testing, s: stable

$nfo = 
"""
+------------------------------------+
| #netmap #{$nm_version} - GPLv3 2014          |
|    by _null_                       |
| https://github.com/null--/netmap   |
+------------------------------------+
"""

$nm_ext = ".nsg"

$nm_ban = {
  :exp    => "[EXPERIMENTAL]",
  :err    => "[ERROR]",
  :inf    => "[INFO]",
  :war    => "[WARNING]",
  :msm    => "[MASTER]"
}

$nm_os = [
  # "auto",
  "linux",
  "bsd",
  "solaris",
  "win"
]

$nm_os_ver = {
  :linux    => "uname -a",
  :bsd      => "uname -a",
  :solaris  => "uname -a",
  :win      => "ver"
}

$nm_adapter = {
  :linux    => "ifconfig",
  :bsd      => "ifconfig",
  :solaris  => "ifconfig",
  :win      => "ipconfig"
}

$nm_hostname = {
  :linux    => "hostname",
  :bsd      => "hostname",
  :solaris  => "hostname",
  :win      => "hostname"
}

$nm_route = {
  :linux    => "netstat -r",
  :bsd      => "netstat -r",
  :solaris  => "netstat -r",
  :win      => "netstat -r"
}

$nm_netstat = {
  :linux    => "netstat -antu",
  :bsd      => "netstat -an",
  :solaris  => "netstat -an",
  :win      => "netstat -an"
}

#TODO: IPv6 support
$nm_netstat_regex = {
  :linux    => /(?<proto>(tcp|udp))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[\d|*]+)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[\d|*]+)\s*(ESTABLISHED|LISTEN)/im,
  :bsd      => //im,
  :solaris  => //im,
  :win      => //im,
}
