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
  attr_reader   :master

  def initialize(*args)
    super
    puts "#{$nfo}"
    @master = MasterMind.new(options[:verbose], options[:os], options[:update], options[:backup], options[:loopback])
  end
  
  no_commands do
    def prologue
      master.load_graph(options[:output])
    end

    def epilogue
      master.save_graph(options[:output])
      master.save_png(options[:output])  if options[:png]
      master.save_pdf(options[:output])  if options[:pdf]
    end
  end

  desc "help", "help_banner"
  def help
    super
    
    puts <<-BANNER
Examples:
  1. Create a new diagram from a netstat output file, then generate report in png and pdf formats
    ./netmap.rb file netstat.out --verbose --png --pdf --output test.nmg
  2. Update an existing diagram from a netstat output file
    ./netmap.rb file netstat-win.out --verbose --png --pdf --os win --output test.nmg --update
  3. Using SSH to create a diagram
    ./netmap.rb ssh localhost --user temp --pass temp --verbose --png --pdf --output test.nmg
  4. More advanced SSH
    ./netmap.rb ssh example.com --user root --pass toor --verbose --png --pdf --output test.nmg --os win --port 80 --key ~/.ssh/id_rsa --update
  5. Pipe netstat result into netmap
    cat netstat-win.out | ./netmap.rb stdin --verbose --png --pdf --os linux --output output-win.nmg
    or
    netstat -antu | ./netmap.rb stdin --verbose --png --pdf --os linux --output output-win.nmg
    BANNER
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :update,  :type => :boolean, :default => false, :alias => "-u",
      :desc => "Update an existing diagram"
  class_option :backup,  :type => :boolean, :default => false, :alias => "-b",
      :desc => "Backup an existing diagram"
  class_option :os,       :type => :string,  :default => "#{$nm_os[0]}", :required => true,
      :banner => "TARGET_OS",
      :desc => "Values: #{$os}"
  class_option :loopback,      :type => :boolean, :default => false,
      :desc => "Draw loopback connections (e.g. localhost-to-localhost)"
  class_option :output,   :type => :string, :alias => "-o", :required => true, :default => "sample#{$nm_ext}",
      :banner => "OUTPUT_FILE"
  class_option :png,      :type => :boolean, :default => false,
      :desc => "Save graph in png format, too"
  class_option :pdf,      :type => :boolean, :default => false,
      :desc => "Save graph in pdf format, too"
      
  desc "stdin", "Pipe netstat result into netmap"
  def stdin
    data = ""
    inp = ""
    while inp = STDIN.gets do
      data = data + inp
    end
    prologue
    master.parse_netstat(data)
    epilogue
  end
  
  desc "file {NETSTAT-OUTPUT}", "Create a new diagram from a netstat file (netstat -blah > NETSTAT-OUTPUT)"
  def file(nsfile)
    puts "file: nsfile=#{nsfile}" if options[:verbose]
    
    prologue
    master.parse_netstat(File.read(nsfile))
    epilogue
  end

  desc "redraw", "Redraw an existing diagram (set at least one of --pdf or --png optoins)"
  def redraw
    puts "redraw: #{options[:output]}" if options[:verbose]
    
    prologue
    epilogue
  end

  desc "ssh {HOST}", "Execute built-in commands via a SSH connection on the remote HOST"
  method_option :user,        :type => :string, :alias => "-l", :banner => "USERNAME", :required => true
  method_option :pass,        :type => :string, :alias => "-p", :banner => "PASSWORD"
  method_option :port,        :type => :string, :banner => "PORT", :default => 22
  method_option :key,         :type => :string, :alias => "-k", :banner => "SSH_KEY",
    :desc => "Prompts for passphrase if needed."
  # method_option :passphrase,  :type => :string, :alias => "-pp", :banner => "SSH_KEY_PASS_PHRASE"
  def ssh(host)
    puts "#{$nm_ban["inf"]} ssh: #{host}:#{options[:port]}, user=#{options[:user]}" if options[:verbose]
    
    #note: :port must pass as last argument
    if options["key"].nil? then
      ssh = Net::SSH.start(host, options[:user], :password => options[:pass], :port => options[:port].to_i) 
    else
      ssh = Net::SSH.start(host, options[:user], :password => options[:pass], :keys => [options["key"]], :port => options[:port].to_i)
    end

    if not ssh.nil? then
      puts "#{$nm_ban["inf"]} ssh: Connection Established, OS: #{options[:os]}" if options[:verbose]
      hs = ssh.exec!( $nm_hostname[ options[:os] ] )
      ov = ssh.exec!( $nm_os_ver[ options[:os] ] )      
      # ad = ssh.exec!( $nm_adapter[ options[:os] ] )
      # rt = ssh.exec!( $nm_route[ options[:os] ] )            
      ns = ssh.exec!( $nm_netstat[ options[:os] ] )
      puts "#{$nm_ban["inf"]} netstat result:\n#{ns}" if options[:verbose]
      prologue
      master.parse_hostname ( hs )
      master.parse_os_ver   ( ov )
      # master.parse_adapter  ( ad )
      # master.parse_route    ( rt )
      master.parse_netstat  ( ns )
      epilogue
      ssh.close()
    end
  
  # rescue => details
    # puts "#{$nm_ban["err"]} SSH Failed #{details}"    
  end

  desc "psexec {HOST}", "#{$nm_ban["exp"]} Execute commands via a 'psexec' connection the remote (Windows) host (requires metasploit)"
  method_option :user,        :type => :string,   :alias => "-l", :banner => "SMB_USERNAME"
  method_option :pass,        :type => :string,   :alias => "-p", :banner => "SMB_PASSWORD"
  method_option :domain,      :type => :string,   :default => "WORKGROUP", :alias => "-d", :banner => "SMB_DOMAIN"
  def psexec(host)
    puts "#{$nm_ban["inf"]} psexec: host=#{host}, user=#{options[:user]}" if options[:verbose]
  end

  desc "adb", "#{$nm_ban["exp"]} Execute commands via an 'adb' shell (android)"
  def adb()
    puts "#{$nm_ban["inf"]} adb" if options[:verbose]
  end    
end

NetMap.start

