#!/usr/bin/env ruby

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

# * aaron Project

require 'thor'
require 'net/ssh'
require 'open3'
require './aaron-defs.rb'
require './mastermind.rb'

#-------------------------------------------------------------------------- #
# creates a new process and controls its input/outputs
class BADPipe
  @_io # IO object
  
#-------------------------------------------------------------------------- #
  ##
  # Creates a process and ignore its first outputs until it sees the delim (delimeter) characters
  # +cmd+ is the command that runs the process
  # +delim+ is the delimeter which tells the BADPipe where output stops and it should send some input to program
  def initialize(cmd = "msfconsole", delim = "[0m> ")
    @_io = IO.popen(cmd, "w+")
    
    if @_io.nil? then
      raise "metasploit not found"
    end
    
    ##
    # ignore first outputs
    exec nil, delim
    
    puts "BADPipe: ready"
  end
  
#-------------------------------------------------------------------------- #
  ##
  # sends input (+cmd+) to the process and captures output
  def exec(cmd = nil, delim = "[0m> ")
    # sends input 
    @_io.puts cmd unless cmd.nil?
    
    ##
    # reads output from process, byte by byte till BADPipe sees +delim+
    ot = ""
    while c = @_io.read(1) do
      # print " " + c
      ot = ot + c
      break if ot.include? delim
    end
    # puts "------------ DONE -----------"
    
    ##
    # Ignores first line and the line that contains +delim+
    # TODO test
    tot = ""
    first = true
    ot.split("\n").each do |ln|
      next if ln == "\n"
      next if ln.include? delim
      if first then
        first = false
        next
      end
      tot = tot + ln + "\n"
    end
    
    return tot
  end
end

#-------------------------------------------------------------------------- #
# Main class
class Aaron < Thor
  # +master+ is the reference to the +MasterMind+ class
  attr_reader   :master # +MasterMind+ object

#-------------------------------------------------------------------------- #  
  def initialize(*args)
    super
    puts "#{$nfo}" # if not ARGV[0].include? "msf" # silenced
    
    @master = MasterMind.new(options[:verbose], options)
  end
  
  no_commands do
#-------------------------------------------------------------------------- #
    def puterr(t)
      puts "#{$aa_ban["err"]} #{t}"
    end
    
#-------------------------------------------------------------------------- #
    def putinf(t)
      puts "#{$aa_ban["inf"]} #{t}" if options[:verbose]
    end

#-------------------------------------------------------------------------- #    
    def prologue
      master.os = options[:os]
      master.load_db(options[:project])
    end

#-------------------------------------------------------------------------- #
    def epilogue
      @master.save_png(options[:project])  if options[:png]
      @master.save_pdf(options[:project])  if options[:pdf]
      
      puts "#{$lastnfo}"
    end

#-------------------------------------------------------------------------- #
    ##
    # adds targets listed inside +MasterMind::latest_targets+ to the metasploit
    def feed_msf(ws)
      if @master.latest_targets.empty? then
        puts "METASPLOIT: No Target!"
        return
      end
      
      puts "METASPLOIT: Firing up metasploit (this may take a while)..."
      msf = BADPipe.new("msfconsole")
      
      ##
      # checks msf db status
      ot = msf.exec("db_status")
      putinf "METASPLOIT: #{ot}"
      unless ot.include? "connected" then
        puts "METASPLOIT: start msfdb first! (on kali linux you may try: /etc/init.d/postgresql start)"
        msf.exec("exit")
      end
      
      ##
      # select the +ws+ as current msf workspace
      ot = msf.exec("workspace #{ws}")
      putinf "METASPLOIT: #{ot}"
      if ot.include? "not found" then
        msf.exec("exit")
      end
      
      ##
      # finally, adds hosts to the msf db
      @master.latest_targets.each do |tgt|
        ot = msf.exec("hosts -a #{tgt[:ip]}")
        puts "METASPLOIT: #{ot}"
      end
      putinf "METASPLOIT: DONE!"
    end
  end

#-------------------------------------------------------------------------- #
  desc "help [command]", "Print more information about a command (task)"
  
  ##
  # customized help task for +aaron+
  def help(command = nil)
    if command.nil? then
      puts "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
      puts "Brief Help"
      puts "=========="
    end
    super(command)
    
    if command.nil? then
      puts "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
      puts "Advanced Help"
      puts "========="
      super("adb")
      puts "-----------------------------------------------------"
      super("addconn")
      puts "-----------------------------------------------------"
      super("addhost")
      puts "-----------------------------------------------------"
      super("editconn")
      puts "-----------------------------------------------------"
      super("edithost")
      puts "-----------------------------------------------------"
      super("file")
      puts "-----------------------------------------------------"
      super("help")
      puts "-----------------------------------------------------"
      super("psexec")
      puts "-----------------------------------------------------"
      super("redraw")
      puts "-----------------------------------------------------"
      super("rmconn")
      puts "-----------------------------------------------------"
      super("rmhost")
      puts "-----------------------------------------------------"
      super("search")
      puts "-----------------------------------------------------"
      super("show")
      puts "-----------------------------------------------------"
      super("ssh")
      puts "-----------------------------------------------------"
      super("stdin")
      puts "-----------------------------------------------------"
    end
    
    if command.nil? then
      puts <<-BANNER
Examples:
  10. Create a new diagram (or update and exsisting one) from a netstat output file, then generate report in png and pdf formats
    ./aaron.rb file netstat.out --verbose --png --pdf --project test.axa
  11. Create a new diagram (remove old #{$aa_ext} file) from a netstat output file
    ./aaron.rb file netstat-win.out --verbose --png --pdf --project test.axa --new
  20. Use SSH to create a diagram (against a linux machine)
    ./aaron.rb ssh localhost --user temp --pass temp --verbose --png --pdf --project test.axa
  21. More advanced SSH (against a windows machine)
    ./aaron.rb ssh example.com --user root --pass toor --verbose --png --pdf --project test.axa --port 80 --key ~/.ssh/id_rsa --new
  30. Pipe netstat result into aaron
    cat netstat-win.out | ./aaron.rb stdin --verbose --png --pdf --project test.axa
    or
    netstat -antu | ./aaron.rb stdin --verbose --png --pdf --project test.axa
  40. Execute command on remote machine via SMB (psexec)
    ./aaron.rb psexec 192.168.13.50 --user Administrator --pass 123456 --domain WORKGROUP --verbose --png --pdf --project test.axa
  50. Print all windows clients connected to 192.168.0.1 on port 22 then add them to metasploit
    ./aaron.rb search --dst 192.168.0.1 --dst_port 22 --src_os win --msf --msf_workspace default
  51. Show all info about a host then add it to metasploit
    ./aaron.rb show --info 192.168.0.1
  52. Show all hosts then add them to metasploit
    ./aaron.rb show --hosts
  53. Show open ports (listenning port) on a host
    ./aaron.rb show --port 192.168.0.1
    
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Is network graph too large? Try "#{$aaron_name} redraw --perhost"
Does PDF output suck? Does GUI make you sick?! Do you love that old school black and white shell?
Try "#{$aaron_name} help search" to find out how to analyse the output "in depth"!

      BANNER
    end
  end

#-------------------------------------------------------------------------- #  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :new,  :type => :boolean, :default => false, :alias => "-u",
      :desc => "Remove an existing project and create a new one"
  class_option :backup,  :type => :boolean, :default => false, :alias => "-b",
      :desc => "Backup an existing diagram"
  class_option :loopback,      :type => :boolean, :default => false,
      :desc => "Draw loopback connections (e.g. localhost-to-localhost) LOGICALLY DANGEROUS"
  class_option :dead,          :type => :boolean, :default => false,
      :desc => "Draw dead connections (e.g. CLOSE_WAIT)"
  class_option :project,   :type => :string, :alias => "-o", :required => true, :default => "test#{$aa_ext}",
      :banner => "PROJECT_FILE"
  class_option :png,      :type => :boolean, :default => false,
      :desc => "Save graph in png format, too"
  class_option :pdf,      :type => :boolean, :default => false,
      :desc => "Save graph in pdf format, too"

#-------------------------------------------------------------------------- #  
  desc "stdin", "Pipe netstat result into aaron\nSupported netstat:\n#{$aa_netstat}"
  method_option :os,       :type => :string,  :default => "#{$aa_os[0]}", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
  
  ##
  # reads input from stdin
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

#-------------------------------------------------------------------------- #
  desc "file [ONE OUTPUT FILE]", "Create a new diagram from netstat files\nSupported netstat:\n#{$aa_netstat}"
  method_option :os,       :type => :string,  :default => "#{$aa_os[0]}", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
  method_option :files,    :type => :array, :required => false, :banner => "Multiple input files (supports regex)"

  ##
  # reads input from file
  def file(nsfile = nil)
    prologue
    
    if not nsfile.nil? then
      puts "files: nsfiles=#{nsfile}" if options[:verbose]
      
      master.parse_netstat(File.read(nsfile))
    elsif not options[:files].nil? then
      puts "files: files=#{options[:files]}" if options[:verbose]
      
      options[:files].each do |fr|
        Dir[fr].select do |f|
          putinf "Processing: #{f}"
          master.parse_netstat(File.read(f))
        end
      end
    else
      help("file")
    end
        
    epilogue
  end

#-------------------------------------------------------------------------- #
  desc "redraw", "Redraw an existing diagram (set at least one of --pdf or --png optoins)"
  method_option :perhost, :type => :boolean, :default => false, :desc => "Draw a seperate network graph for each host"
  ##
  # redraws an exsisting project
  def redraw
    puts "redraw: #{options[:project]}" if options[:verbose]
    
    prologue
    if not options[:perhost] then
      @master.save_graph(options[:project])
      epilogue
    else
      Host.all.each do |h|
        putinf "Drawing #{h.id} - #{h.name}..."

        @master.save_graph(options[:project], h.id)

        @master.save_png(options[:project], h.id)  if options[:png]
        @master.save_pdf(options[:project], h.id)  if options[:pdf]
      end
    end
    # epilogue
  end

#-------------------------------------------------------------------------- #
  desc "ssh {HOST}", "Execute built-in commands via a SSH connection on the remote HOST"
  method_option :user,        :type => :string, :alias => "-l", :banner => "USERNAME", :required => true
  method_option :pass,        :type => :string, :alias => "-p", :banner => "PASSWORD"
  method_option :port,        :type => :string, :banner => "PORT", :default => 22
  method_option :key,         :type => :string, :alias => "-k", :banner => "SSH_KEY",
    :desc => "Prompts for passphrase if needed."
  method_option :os,       :type => :string,  :default => "#{$aa_os[0]}", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
  # method_option :passphrase,  :type => :string, :alias => "-pp", :banner => "SSH_KEY_PASS_PHRASE"
  
  ##
  # uses ssh to retrive netstat (and some other) results
  def ssh(host)
    puts "#{$aa_ban["inf"]} ssh: #{host}:#{options[:port]}, user=#{options[:user]}" if options[:verbose]
    
    ##
    # check options (key vs pass)
    # note: :port must pass as last argument
    if options["key"].nil? then
      ssh = Net::SSH.start(host, options[:user], :password => options[:pass], :port => options[:port].to_i) 
    else
      ssh = Net::SSH.start(host, options[:user], :password => options[:pass], :keys => [options["key"]], :port => options[:port].to_i)
    end

    if not ssh.nil? then
      puts "#{$aa_ban["inf"]} ssh: Connection Established, OS: #{options[:os]}" if options[:verbose]
      
      prologue
      
      ##
      # automated OS detection
      nss = Array.new
      if options[:os] == "auto" then
        $aa_netstat.each do |os, cmd|
          ns = ssh.exec!( cmd )
          nss << ns
        end
      else
        @master.os = options[:os]
      end
      
      @master.detect_os_based_on_a_bunch_of_netstat nss
      
      ##
      # netstat
      ns = ssh.exec!( $aa_netstat[ @master.os ] )
      puts "#{$aa_ban["inf"]} netstat result:\n#{ns}" if options[:verbose]
      master.parse_netstat   ( ns )
      
      ##
      # hostname, uname, ifconfig, route
      hs = ssh.exec!( $aa_hostname[ @master.os ] )
      ov = ssh.exec!( $aa_os_ver[ @master.os ] )
      ad = ssh.exec!( $aa_adapter[ @master.os ] )      
      rt = ssh.exec!( $aa_route[ @master.os ] )            
      
      ##
      # updates +name+, +info+, +deepinfo+
      master.name = hs
      master.info = ov
      master.deepinfo = ad + rt 
      
      epilogue
      ssh.close()
    end
  
  # rescue => details
  #  puts "#{$aa_ban["err"]} SSH Failed #{details}"    
  end
  
#-------------------------------------------------------------------------- #
  desc "psexec {HOST}", "#{$aa_ban["exp"]} Execute commands via a 'psexec' connection the remote (Windows) host (requires metasploit)"
  method_option :user,        :type => :string,   :alias => "-l", :banner => "SMB_USERNAME", :require => true
  method_option :pass,        :type => :string,   :alias => "-p", :banner => "SMB_PASSWORD", :desc => "SMB Password or a valid SAM hash (pass-the-hash)"
  method_option :domain,      :type => :string,   :default => "WORKGROUP", :alias => "-d", :banner => "SMB_DOMAIN"
  method_option :os,       :type => :string,  :default => "win", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
    
  ##
  # The mighty psexec!
  # --os has been set to "win" by default (guess why?!)
  def psexec(host)
    putinf "psexec: host=#{host}, user=#{options[:user]}"
  
    prologue
    
    ##
    # creates a msfcli command
    cmd = "msfcli auxiliary/admin/smb/psexec_command RHOSTS='#{host}' SMBUser='#{options[:user]}'"
    cmd = cmd + " SMBPass='#{options[:pass]}'" if not options[:pass].nil?
    cmd = cmd + " SMBDomain='#{options[:domain]}'" if not options[:domain].nil?
    
    ##
    # netstat
    ns = %x( #{cmd} COMMAND='#{$aa_netstat[ options[:os] ]}' E )
    putinf "netstat result:\n#{ns}"
    master.parse_netstat   ( ns )
    
    hs = %x( #{cmd} COMMAND='#{$aa_hostname[ @master.os ]}' E )
    ov = %x( #{cmd} COMMAND='#{$aa_os_ver[ @master.os ]}' E )
    ad = %x( #{cmd} COMMAND='#{$aa_adapter[ @master.os ]}' E )
    rt = %x( #{cmd} COMMAND='#{$aa_route[ @master.os ]}' E )
    
    master.name = hs
    master.info = ov
    master.deepinfo = ad + rt
    
    epilogue
  end

#-------------------------------------------------------------------------- #
  desc "adb", "#{$aa_ban["exp"]} Execute commands via an 'adb' shell (android) (NOT IMPLEMENTED YET)"
  method_option :os,       :type => :string,  :default => "linux", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
    
  ##
  # uses "adb shell" to get the job done!
  # --os has been set to linux by default --> android
  def adb
    a_ = BADPipe.new("adb shell", ":/ $")
    
    if not a_.nil? then
      
      prologue
      
      ns = a_.exec( $aa_netstat[ options[:os] ], ":/ $" )
      putinf "netstat result:\n#{ns}"
      master.parse_netstat   ( ns )
      
      hs = a_.exec( $aa_hostname[ @master.os ], ":/ $")
      # putinf hs
      ov = a_.exec( $aa_os_ver[ @master.os ], ":/ $" )
      # putinf ov
      ad = a_.exec( $aa_adapter[ @master.os ], ":/ $" )
      # putinf ad
      rt = a_.exec( $aa_route[ @master.os ], ":/ $" )            
      # putinf rt
      
      master.name = hs
      master.info = ov
      master.deepinfo = ad + rt 
      
      epilogue
      a_.exec("exit")
    end
  end

#-------------------------------------------------------------------------- #
  desc "search", "Search something! (e.g. all windows clients connected to 192.168.0.1 on port 22)"
  method_option :src_os,      :type => :string, :alias => "-sos",  :banner => "SRC_OS",      :desc => "source os filter"
  method_option :dst_os,      :type => :string, :alias => "-dos",  :banner => "DST_OS",      :desc => "destination os filter"
  method_option :src_port,    :type => :string, :alias => "-sp",  :banner => "SRC_PORT",    :desc => "source port filter"
  method_option :dst_port,    :type => :string, :alias => "-dp",  :banner => "DST_PORT",    :desc => "destination port filter"
  method_option :src,         :type => :string, :alias => "-s",   :banner => "SRC_ADDRESS", :desc => "source filter"
  method_option :dst,         :type => :string, :alias => "-d",   :banner => "DST_ADDRESS", :desc => "destination filter"
  method_option :text,        :type => :string, :alias => "-t",   :banner => "TEXT",        :desc => "text filter"
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
      :desc => "An existing #{$aa_ext}"
  method_option :msf,         :type => :boolean, :default => false, :desc => "Add results to metasploit"
  method_option :msf_workspace,         :type => :string, :default => "default", :desc => "Set metasploit workspace"
  
  ##
  # searching through the databse
  # just an interface to +MasterMind::search+
  def search
    @master.load_db(options[:project], true)
    
    @master.search(options[:src_os],
                   options[:dst_os],
                   options[:src_port],
                   options[:dst_port],
                   options[:src],
                   options[:dst],
                   options[:text])
     
    feed_msf(options[:msf_workspace]) if options[:msf]
  end

#-------------------------------------------------------------------------- #
  desc "show", "Print more info about a HOST (some of them are not shown in png or pdf)"
  method_option :info,        :type => :string, :alias => "-i", :banner => "HOST", :desc => "Shows all information about a host"
  method_option :port,        :type => :string, :banner => "HOST", :desc => "List open ports on a host"
  method_option :hosts,       :type => :boolean, :default => false, :alias => "-a", :desc => "Show all hosts"
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
      :desc => "An existing #{$aa_ext} file"
  method_option :msf,         :type => :boolean, :default => false, :desc => "Add results to metasploit"
  method_option :msf_workspace,         :type => :string, :default => "default", :desc => "Sets metasploit workspace"
  
  ##
  # shows information about a single host, print all hosts or print source ports sets for a target
  def show
    @master.load_db(options[:project], true)
    
    if options[:hosts] then
      @master.print_hosts
    elsif not options[:info].nil? then
      @master.print_info options[:info]
    elsif options[:port] then
      @master.print_ports options[:port]
    end
    
    feed_msf(options[:msf_workspace]) if options[:msf]
  end

#-------------------------------------------------------------------------- #
  desc "edithost {IP}", "Edit a host"
  method_option :name,  :type => :string
  method_option :info,  :type => :string
  method_option :deepinfo,  :type => :string
  method_option :comment,  :type => :string
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
        :desc => "An existing #{$aa_ext} file"
        
  ##
  # add
  def edithost(ip)
    @master.load_db(options[:project], true)
    
    @master.edit_host(ip, options[:name], options[:info], options[:deepinfo], options[:comment])
  end
  
#-------------------------------------------------------------------------- #
  desc "addhost {IP}", "Add a new host"
  method_option :name,  :type => :string
  method_option :info,  :type => :string
  method_option :deepinfo,  :type => :string
  method_option :comment,  :type => :string
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
        :desc => "An existing #{$aa_ext} file"
        
  ##
  # add
  def addhost(ip)
    @master.load_db(options[:project], true)
    
    @master.add_new_host(ip, options[:name], options[:info], options[:deepinfo], options[:comment])
  end

#-------------------------------------------------------------------------- #
  desc "addconn", "Add a new connection"
  method_option :conn,       :type => :boolean, :default => false, :alias => "-c", :desc => "Add a new connection"
  method_option :src_ip,  :type => :string, :required => true
  method_option :dst_ip,  :type => :string, :required => true
  method_option :src_port,  :type => :string, :required => true
  method_option :dst_port,  :type => :string, :required => true
  method_option :proto,  :type => :string
  method_option :type,  :type => :string
  method_option :comment,  :type => :string
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
        :desc => "An existing #{$aa_ext} file"
        
  ##
  # add
  def addconn
    @master.load_db(options[:project], true)
    
    @master.add_new_connection(options[:src_ip], options[:src_port], options[:dst_ip], options[:dst_port], options[:proto], options[:type], options[:comment])
  end

#-------------------------------------------------------------------------- #
  desc "editconn", "Edit a new connection"
  method_option :conn,       :type => :boolean, :default => false, :alias => "-c", :desc => "Add a new connection"
  method_option :src_ip,  :type => :string, :required => true
  method_option :dst_ip,  :type => :string, :required => true
  method_option :src_port,  :type => :string, :required => true
  method_option :dst_port,  :type => :string, :required => true
  method_option :proto,  :type => :string
  method_option :type,  :type => :string
  method_option :comment,  :type => :string
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
        :desc => "An existing #{$aa_ext} file"
        
  ##
  # add
  def editconn
    @master.load_db(options[:project], true)
    
    @master.edit_connection(options[:src_ip], options[:src_port], options[:dst_ip], options[:dst_port], options[:proto], options[:type], options[:comment])
  end
  
#-------------------------------------------------------------------------- #
  desc "rmhost {IP}", "Remove a host"
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
        :desc => "An existing #{$aa_ext} file"        
  ##
  # 
  def rmhost(host)
    @master.load_db(options[:project], true)
    
    @master.remove_host(host)
  end
#-------------------------------------------------------------------------- #
  desc "rmconn", "Remove a connection"
  method_option :src_ip,  :type => :string, :required => true
  method_option :dst_ip,  :type => :string, :required => true
  method_option :src_port,  :type => :string, :required => true
  method_option :dst_port,  :type => :string, :required => true
  method_option :project,  :type => :string, :default => 'test.axa', :alias => "-i", :required => true,
        :desc => "An existing #{$aa_ext} file"        
  ##
  # 
  def rmconn
    @master.load_db(options[:project], true)
    
    @master.remove_connection(options[:src_ip], options[:src_port], options[:dst_ip], options[:dst_port])
  end
end

Aaron.start

