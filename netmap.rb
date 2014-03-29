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
    @master = MasterMind.new(options[:verbose])
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :update,   :type => :boolean, :default => false, :alias => "-u",
      :desc => "Update an existing graph (or create a new one if it doesn't exist')"
  class_option :backup,   :type => :boolean, :default => true,  :alias => "-b",
      :desc => "Backup existing graph before modifying it"
  class_option :os,       :type => :string,  :default => "auto",
      :banner => "TARGET_OS",
      :desc => "Values: #{$os}"
  class_option :png,      :type => :boolean, :default => true,
      :desc => "Save graph in png format, too"

  desc "file {NETSTAT-OUTPUT}", "Create a new graph from a netstat file (netstat -blah > NETSTAT-OUTPUT)"
  method_option :output, :required => true , :alias => "-o"
  def file(nsfile)
    puts "file: nsfile=#{nsfile}" if options[:verbose]
    
    master
  end

  desc "ssh {HOST}", "Execute a netstat command via a SSH connection on the remote host"
  method_option :output,      :required => true,  :alias => "-o", :banner => "OUTPUT_FILE"
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
  method_option :output,      :required => true,  :alias => "-o", :banner => "OUTPUT_FILE"
  method_option :user,        :type => :string,   :alias => "-l", :banner => "SMB_USERNAME"
  method_option :pass,        :type => :string,   :alias => "-p", :banner => "SMB_PASSWORD"
  method_option :domain,      :type => :string,   :default => "WORKGROUP", :alias => "-d", :banner => "SMB_DOMAIN"
  def psexec(host)
    puts "#{$nm_ban[:inf]} psexec: host=#{host}, user=#{options[:user]}" if options[:verbose]
  end

  desc "adb", "#{$nm_ban[:exp]} Execute commands via an 'adb' shell (android)"
  method_option :output,      :required => true,  :alias => "-o", :banner => "OUTPUT_FILE"
  def adb()
    puts "#{$nm_ban[:inf]} adb" if options[:verbose]
  end    
end

NetMap.start
  
