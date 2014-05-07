##
# GPLv3:
#
# This file is part of aaron.
# aaron is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# aaron is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#  
# You should have received a copy of the GNU General Public License
# along with Graviton.  If not, see http://www.gnu.org/licenses/.

#-------------------------------------------------------------------------- #
##
# aaron current version
$aa_version = "1.1.3-testing"

$aaron_name = "#aaron"
# $aaronizer_name = "#aaronizer"

##
# the "hello" banner
$nfo = <<-NFO
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #{$aaron_name}, by _null_ - #{$aa_version} - 2014 - GPLv3
    https://github.com/null--/aaron
  
  In loving memory of Internet activist, "Aaron Swartz".
    http://en.wikipedia.org/wiki/Aaron_Swartz
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
NFO

##
# the "goodbye" banner
$lastnfo = "DONE!"

#-------------------------------------------------------------------------- #
##
# general settings
$aa_img_dir     = "./img/"
$aa_tmp_dir     = "./tmp/"
$aa_ext         = ".axa"

#-------------------------------------------------------------------------- #
##
# graphviz settings

$aa_format      = "dot" # $axa_format     = "canon"
$deep_tag       = "comment"
$aa_node_shape  = "component"
$aa_stag_shape  = "octagon" #"ellipse"
$aa_dtag_shape  = "doubleoctagon"
$aa_graph_layout= "circo"
$clr_node_seen  = "#99EECC"
$clr_node_unseen= "#9999CC"
$clr_tag        = "#EECC22"
$clr_bg         = "white"
$clr_node       = "gray"
$clr_graph      = "black"
$clr_tcp        = "#001155"
$clr_udp        = "#005511"
$clr_ssh        = "red"

#-------------------------------------------------------------------------- #
##
# messages
$aa_ban = {
  "exp"    => "[EXPERIMENTAL]",
  "err"    => "[ERROR]",
  "inf"    => "[INFO]",
  "war"    => "[WARNING]",
  "msm"    => "[aaron::MASTER]"
}

#-------------------------------------------------------------------------- #
##
# supported OSs
$aa_os = [
  "auto",
  "linux",
  "bsd",
  "solaris",
  "solaris2",
  "win"
]

#-------------------------------------------------------------------------- #
##
# find OS version
$aa_os_ver = {
  "linux"    => "uname -rs",
  "bsd"      => "uname -rs",
  "solaris"  => "uname -rs",
  "solaris2" => "uname -rs",
  "win"      => "ver"
}

#-------------------------------------------------------------------------- #
##
# list of network adapters
$aa_adapter = {
  "linux"    => "ifconfig",
  "bsd"      => "ifconfig",
  "solaris"  => "ifconfig -a",
  "solaris2" => "ifconfig -a",
  "win"      => "ipconfig"
}

#-------------------------------------------------------------------------- #
##
# get hosname
$aa_hostname = {
  "linux"    => "hostname",
  "bsd"      => "hostname",
  "solaris"  => "hostname",
  "solaris2" => "hostname",
  "win"      => "hostname"
}

#-------------------------------------------------------------------------- #
##
# find routing table
$aa_route = {
  "linux"    => "netstat -r",
  "bsd"      => "netstat -r",
  "solaris"  => "netstat -r",
  "solaris2" => "netstat -r",
  "win"      => "netstat -r"
}

#-------------------------------------------------------------------------- #
##
# netstat
$aa_netstat = {
  "linux"    => "netstat -antu",
  "bsd"      => "netstat -an",
  "solaris"  => "netstat -an",
  "solaris2" => "netstat -anv",
  "win"      => "netstat -an"
}

#-------------------------------------------------------------------------- #
##
# netstat regex
# TODO: IPv6 support
$aa_netstat_regex = {
  "linux"    => /(?<proto>(tcp|udp))\s+\d+\s+\d+\s+(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s+(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s+(?<type>ESTABLISHED|LISTEN|\S+)/i,
  "bsd"      => /(?<proto>(tcp4|udp4))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s+(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s+(?<type>ESTABLISHED|LISTEN|\S+)/i,
  "solaris"  => /(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s+(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s+\d+\s+\d+\s+\d+\s+\d+\s+(?<type>ESTABLISHED|LISTEN|\w+)/i,
  "solaris2" => /(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s+\W+(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s+\w+\s+\w+\s*\w+\s+\w+\s+\w+\s+\w+\s+\w+\s+\w+\s+(?<type>ESTABLISHED|LISTEN|\S+)/im,
  "win"      => /(?<proto>(tcp|udp))\s+(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s+(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s+(?<type>ESTABLISHED|LISTENING|\S+)/i,
}

#-------------------------------------------------------------------------- #
##
# known ports
$aa_known_ports = {
  "20"      => "ftp-dt",
  "21"      => "ftp-ctl",
  "22"      => "ssh",
  "23"      => "telnet",
  "25"      => "smtp",
  "53"      => "dns",
  "80"      => "http",
  "110"     => "pop3",
  "115"     => "sftp",
  "123"     => "ntp",
  "139"     => "netbios",
  "143"     => "imap",
  "161"     => "snmp",
  "443"     => "https",
  "445"     => "smb",
  "989"     => "ftps-d",
  "990"     => "ftps-c",
  "993"     => "imaps",
  "995"     => "pop3s",
  "1194"    => "openvpn",
  "1521"    => "oracle",
  "1723"    => "pptp",
  "3128"    => "squid",
  "3306"    => "mysql",
  "3389"    => "rdp",
  "4444"    => "meterpreter",
  "5432"    => "postgresql",
  "5900"    => "vnc",
  "5985"    => "powershell",
  "5986"    => "powershell",
  "6000"    => "X11",
  "6001"    => "X11",
  "8080"    => "http-alt",
  "8080"    => "http-alt",
  "8834"    => "nessus"
}
