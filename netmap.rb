#!/usr/bin/ruby

# Tested on Kali - 2014

# INSTALLATION (Debian):
#  sudo aptitude install ruby-thor ruby-net ruby-net-ssh ruby-graphviz
#  sudo aptitude install ruby-highline ruby-termios

require 'thor'
require 'net/ssh'

require './mastermind.rb'

$nfo = 
"""
+------------------------------------+
| #netmap - GPLv3 2014               |
|    by _null_                       |
| https://github.com/null--/netmap   |
+------------------------------------+
"""

class NetMap < Thor
  @master

  def initialize(*args)
    super
    puts $nfo
    @master = MasterMind.new
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v"

  class_option :update,   :type => :boolean, :default => false, :alias => "-u"
  class_option :backup,   :type => :boolean, :default => true,  :alias => "-b"

  class_option :output,   :type => :string, :alias => "-o"
  class_option :png,      :type => :string

  class_option :all,      :type => :boolean, :default => true
  class_option :tcp,      :type => :boolean, :default => false
  class_option :udp,      :type => :boolean, :default => false

  desc "file {NETSTAT-OUTPUT}", "Create a new graph from a netstat file (e.g. netstat -blah > NETSTAT-OUTPUT)"
  method_option :output, :required => true , :alias => "-o"
  def file(nsfile)
    puts "file: nsfile=#{nsfile}"
  end

  desc "ssh {HOST}", "Execute a netstat command via a SSH connection on a remote host"
  method_option :user,        :type => :string, :alias => "-l"
  method_option :pass,        :type => :string, :alias => "-p"
  method_option :key,         :type => :string, :alias => "-k"
  method_option :passphrase,  :type => :string, :alias => "-pp"
  def ssh(host)
    puts "ssh: host=#{host}, user=#{options[:user]}"

    if options[:user].nil? and options[:key].nil? then
      puts "#{$err_ban} At least a valid username (--user or -l) or a keyfile (--key or -k) required!"
      return
    end
  end

  desc "psexec {HOST}", "Execute a netstat command via a 'psexec' connection on a remote (Windows) host"
  method_option :output,      :required => true, :alias => "-o"
  method_option :user,        :type => :string, :alias => "-l"
  method_option :pass,        :type => :string, :alias => "-p"
  method_option :domain,      :type => :string, :default => "WORKGROUP", :alias => "-d"
  def ssh(host)
    puts "ssh: host=#{host}, user=#{options[:user]}"

    if options[:user].nil? and options[:key].nil? then
      puts "#{$err_ban} At least a valid username (--user or -l) or a keyfile (--key or -k) required!"
      return
    end
  end
end

NetMap.start
  
