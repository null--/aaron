$aa_version = "0.1-unstable"

$aaron_name = "#aaron"
$aaronizer_name = "#aaronizer"

$nfo = <<-NFO
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #{$aaron_name}, by _null_ - #{$aa_version} - 2014 - GPLv3
    https://github.com/null--/aaron
  
  In loving memory of internet activist, "Aaron Swartz".
    http://en.wikipedia.org/wiki/Aaron_Swartz
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
NFO

$lastnfo = <<-LASTNFO
==============
Does PDF or PNG output seem ugly? Do you love that old school black and white shell?
Try #{$aaronizer_name}, NOW!
LASTNFO

$aa_img_dir     = "./img/"

$aa_ext         = ".nmg"

$deep_tag       = "comment"
$aa_node_shape  = "folder"
$aa_graph_layout= "circo"
$clr_pnode      = "#00DD99"
$clr_cnode      = "#118855"
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
  "msm"    => "[MASTER]"
}

#TODO: detect os automatically
$aa_os = [
  # "auto",
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
  "linux"    => /(?<proto>(tcp|udp))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\w+)/im,
  "bsd"      => /(?<proto>(tcp4|udp4))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\w+)/im,
  "solaris"  => /(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\w+)/im,
  "win"      => /(?<proto>(tcp|udp))\s*(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTENING|\w+)/im,
}

