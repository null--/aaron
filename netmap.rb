#!/usr/bin/ruby

# Tested on Kali - 2014

# INSTALLATION (Debian):
#  sudo aptitude install ruby-thor ruby-net ruby-net-ssh ruby-graphviz
#  sudo aptitude install ruby-highline ruby-termios

require 'thor'
require 'net/ssh'
require './netmap-defs.rb'
require './mastermind.rb'

class NetMap < Thor
  attr_accessor :master

  def initialize(*args)
    super
    @master = MasterMind.new(options[:verbose], options[:os])
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :os,       :type => :string,  :default => "#{$nm_os[0]}", :required => true,
      :banner => "TARGET_OS",
      :desc => "Values: #{$os}"
  class_option :output,   :type => :string, :alias => "-o", :default => "output#{$nm_ext}", :required => true,
      :banner => "OUTPUT_FILE"
  class_option :png,      :type => :boolean, :default => true,
      :desc => "Save graph in png format, too"

  desc "file {NETSTAT-OUTPUT}", "Create a new graph from a netstat file (netstat -blah > NETSTAT-OUTPUT)"
  def file(nsfile)
    puts "file: nsfile=#{nsfile}" if options[:verbose]
    
    master.load_graph(options[:output])
    master.parse_netstat(File.read(nsfile))
    master.save_graph(options[:output])
    master.save_png(options[:output])  if options[:png]
  end

  desc "ssh {HOST}", "Execute a netstat command via a SSH connection on the remote host"
  method_option :user,        :type => :string, :alias => "-l", :banner => "USERNAME"
  method_option :pass,        :type => :string, :alias => "-p", :banner => "PASSWORD"
  method_option :key,         :type => :string, :alias => "-k", :banner => "SSH_KEY"
  method_option :passphrase,  :type => :string, :alias => "-pp", :banner => "SSH_KEY_PASS_PHRASE"
  def ssh(host)
    puts "#{$nm_ban[:inf]} ssh: host=#{host}, user=#{options[:user]}" if options[:verbose]

    if options[:user].nil? and options[:key].nil? then
      puts "#{$nm_ban[:err]} At least a valid username (--user or -l) or a keyfile (--key or -k) required!"
      return
    end
  end

  desc "psexec {HOST}", "#{$nm_ban[:exp]} Execute commands via a 'psexec' connection the remote (Windows) host (requires metasploit)"
  method_option :user,        :type => :string,   :alias => "-l", :banner => "SMB_USERNAME"
  method_option :pass,        :type => :string,   :alias => "-p", :banner => "SMB_PASSWORD"
  method_option :domain,      :type => :string,   :default => "WORKGROUP", :alias => "-d", :banner => "SMB_DOMAIN"
  def psexec(host)
    puts "#{$nm_ban[:inf]} psexec: host=#{host}, user=#{options[:user]}" if options[:verbose]
  end

  desc "adb", "#{$nm_ban[:exp]} Execute commands via an 'adb' shell (android)"
  def adb()
    puts "#{$nm_ban[:inf]} adb" if options[:verbose]
  end    
end

NetMap.start
  
