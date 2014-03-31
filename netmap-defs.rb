$nm_version = "0.1-unstable"

$nfo = <<-NFO
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #netmap, by _null_ - #{$nm_version} - 2014 - GPLv3
    https://github.com/null--/netmap
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
NFO

$nm_img_dir     = "./img/"

$nm_ext         = ".nmg"

$deep_tag       = "comment"
$nm_node_shape  = "folder"
$nm_graph_layout= "circo"
$clr_pnode      = "#00DD99"
$clr_cnode      = "#118855"
$clr_bg         = "white"
$clr_node       = "gray"
$clr_graph      = "black"
$clr_tcp        = "purple"
$clr_udp        = "brown"
$clr_ssh        = "red"

$nm_ban = {
  "exp"    => "[EXPERIMENTAL]",
  "err"    => "[ERROR]",
  "inf"    => "[INFO]",
  "war"    => "[WARNING]",
  "msm"    => "[MASTER]"
}

#TODO: detect os automatically
$nm_os = [
  # "auto",
  "linux",
  "bsd",
  "solaris",
  "win"
]

$nm_os_ver = {
  "linux"    => "uname -rs",
  "bsd"      => "uname -rs",
  "solaris"  => "uname -rs",
  "win"      => "ver"
}

$nm_adapter = {
  "linux"    => "ifconfig",
  "bsd"      => "ifconfig",
  "solaris"  => "ifconfig",
  "win"      => "ipconfig"
}

$nm_hostname = {
  "linux"    => "hostname",
  "bsd"      => "hostname",
  "solaris"  => "hostname",
  "win"      => "hostname"
}

$nm_route = {
  "linux"    => "netstat -r",
  "bsd"      => "netstat -r",
  "solaris"  => "netstat -r",
  "win"      => "netstat -r"
}

$nm_netstat = {
  "linux"    => "netstat -antu",
  "bsd"      => "netstat -an",
  "solaris"  => "netstat -an",
  "win"      => "netstat -an"
}

#TODO: IPv6 support
$nm_netstat_regex = {
  "linux"    => /(?<proto>(tcp|udp))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\w+)/im,
  "bsd"      => /(?<proto>(tcp4|udp4))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\w+)/im,
  "solaris"  => /(?<proto>(tcp|udp))\s*\d+\s*\d+\s*(?<src>(\d+\.\d+\.\d+\.\d+))\.(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\.(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTEN|\w+)/im,
  "win"      => /(?<proto>(tcp|udp))\s*(?<src>(\d+\.\d+\.\d+\.\d+))\:(?<sport>[1-9]\d*)\s*(?<dst>(\d+\.\d+\.\d+\.\d+))\:(?<dport>[1-9]\d*)\s*(?<type>ESTABLISHED|LISTENING|\w+)/im,
}

