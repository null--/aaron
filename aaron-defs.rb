=begin
GPLv3:

This file is part of aaron.
aaron is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

aaron is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License
along with Graviton.  If not, see http://www.gnu.org/licenses/.
=end

$aa_version = "1.0-unstable"

$aaron_name = "#aaron"
# $aaronizer_name = "#aaronizer"

$nfo = <<-NFO
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #{$aaron_name}, by _null_ - #{$aa_version} - 2014 - GPLv3
    https://github.com/null--/aaron
  
  In loving memory of internet activist, "Aaron Swartz".
    http://en.wikipedia.org/wiki/Aaron_Swartz
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
NFO

$lastnfo = "DONE!"

$aa_img_dir     = "./img/"
$aa_tmp_dir     = "./tmp/"
$aa_ext         = ".axa"

$nmg_format     = "canon"
# $nmg_format     = "dot"
$deep_tag       = "comment"
$aa_node_shape  = "folder"
$aa_graph_layout= "circo"
$clr_pnode      = "#99EECC"
$clr_cnode      = "#99EECC"
$clr_bg         = "white"
$clr_node       = "gray"
$clr_graph      = "black"
$clr_tcp        = "purple"
$clr_udp        = "brown"
$clr_ssh        = "red"

$aa_ban = {
  "exp"    => "[EXPERIMENTAL]",
  "err"    => "[ERROR]",
  "inf"    => "[INFO]",
  "war"    => "[WARNING]",
  "msm"    => "[aaron::MASTER]"
}

#TODO: detect os automatically
$aa_os = [
  "auto",
  "linux",
  "bsd",
  "solaris",
  "win"
]

$aa_os_ver = {
  "linux"    => "uname -rs",
  "bsd"      => "uname -rs",
  "solaris"  => "uname -rs",
  "win"      => "ver"
}

$aa_adapter = {
  "linux"    => "ifconfig",
  "bsd"      => "ifconfig",
  "solaris"  => "ifconfig -a",
  "win"      => "ipconfig"
}

$aa_hostname = {
  "linux"    => "hostname",
  "bsd"      => "hostname",
  "solaris"  => "hostname",
  "win"      => "hostname"
}

$aa_route = {
  "linux"    => "netstat -r",
  "bsd"      => "netstat -r",
  "solaris"  => "netstat -r",
  "win"      => "netstat -r"
}

$aa_netstat = {
  "linux"    => "netstat -antu",
  "bsd"      => "netstat -an",
  "solaris"  => "netstat -an",
  "win"      => "netstat -an"
}

#TODO: IPv6 support
$aa_netstat_regex = {
  "linux"    => /(?<proto>(tcp|udp))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\S+)/im,
  "bsd"      => /(?<proto>(tcp4|udp4))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\S+)/im,
  "solaris"  => /(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s*\d+\s*\d+\s*\d+\s*\d+\s*(?<type>ESTABLISHED|LISTEN|\S+)/im,
  "win"      => /(?<proto>(tcp|udp))\s*(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTENING|\S+)/im,
}

