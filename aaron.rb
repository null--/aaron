#!/usr/bin/env ruby

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

# Tested on Kali - 2014

# INSTALLATION (Debian):
#  sudo aptitude install ruby-thor ruby-net ruby-net-ssh ruby-graphviz libsqlite3-ruby ruby-activerecord
#  sudo aptitude install ruby-highline ruby-termios

require 'thor'
require 'net/ssh'
require 'open3'
require './aaron-defs.rb'
require './mastermind.rb'

class MSFPipe
  @_in
  @_out
  @_err
  
  @_b
  
  def initialize
    @_b = "[0m> "
    
    @_in, @_out, @_err = Open3.popen3("msfconsole", "w+")
    
    if @_in.nil? then
      raise "metasploit not found"
    end
    
    exec
    
    puts "METASPLOIT: ready"
  end
  
  def exec(cmd = nil, delim = @_b)
    @_in.puts cmd unless cmd.nil?
    
    ot = ""
    while c = @_out.read(1) do
      # puts "---> " + c
      ot = ot + c
      break if ot.include? delim
    end
    
    return ot
  end
end

class Aaron < Thor
  attr_reader   :master

  def initialize(*args)
    super
    puts "#{$nfo}" # if not ARGV[0].include? "msf" # silenced
    
    @master = MasterMind.new(options[:verbose], options)
  end
  
  no_commands do
    def puterr(t)
      puts "#{$aa_ban["err"]} #{t}"
    end

    def putinf(t)
      puts "#{$aa_ban["inf"]} #{t}" if options[:verbose]
    end
    
    def prologue
      master.os = options[:os]
      master.load_db(options[:project])
    end

    def epilogue
      master.save_png(options[:project])  if options[:png]
      master.save_pdf(options[:project])  if options[:pdf]
      
      puts "#{$lastnfo}"
    end
    
    def feed_msf(ws)
      if @master.latest_targets.empty? then
        puts "METASPLOIT: No Target!"
        return
      end
      
      puts "METASPLOIT: Firing up metasploit (this may take a while)..."
      msf = MSFPipe.new
      ot = msf.exec("db_status")
      putinf "METASPLOIT: #{ot}"
      unless ot.include? "connected" then
        puts "METASPLOIT: start msfdb first! (on kali linux you may try: /etc/init.d/postgresql start)"
        msf.exec("exit")
      end
      ot = msf.exec("workspace #{ws}")
      putinf "METASPLOIT: #{ot}"
      if ot.include? "not found" then
        msf.exec("exit")
      end
      
      @master.latest_targets.each do |tgt|
        ot = msf.exec("hosts -a #{tgt[:ip]}")
        puts "METASPLOIT: #{ot}"
      end
      putinf "METASPLOIT: DONE!"
    end
  end

  desc "help [command]", "Print more information about a command (task)"
  def help(command = nil)
    super(command)
    
    if command.nil? then
      puts <<-BANNER
Examples:
  10. Create a new diagram (or update and exsisting one) from a netstat output file, then generate report in png and pdf formats
    ./aaron.rb file netstat.out --verbose --png --pdf --project test.nmg
  11. Create a new diagram (remove old #{$aa_ext} file) from a netstat output file
    ./aaron.rb file netstat-win.out --verbose --png --pdf --os win --project test.nmg --new
  20. Use SSH to create a diagram (against a linux machine)
    ./aaron.rb ssh localhost --user temp --pass temp --verbose --png --pdf --project test.nmg
  21. More advanced SSH (against a windows machine)
    ./aaron.rb ssh example.com --user root --pass toor --verbose --png --pdf --project test.nmg --os win --port 80 --key ~/.ssh/id_rsa --new
  30. Pipe netstat result into aaron
    cat netstat-win.out | ./aaron.rb stdin --verbose --png --pdf --os linux --project test.nmg
    or
    netstat -antu | ./aaron.rb stdin --verbose --png --pdf --os linux --project test.nmg
  40. Execute command on remote machine via SMB (psexec)
    ./aaron.rb psexec 192.168.13.50 --os win --user Administrator --pass 123456 --domain WORKGROUP --verbose --png --pdf --project test.nmg
  50. Print all windows clients connected to 192.168.0.1 on port 22 then add them to metasploit
    ./aaron.rb search --dst 192.168.0.1 --dst_port 22 --src_os win --msf --msf_workspace default
  51. Show all info about a host then add it to metasploit
    ./aaron.rb show --info 192.168.0.1
  52. Show all hosts then add them to metasploit
    ./aaron.rb show --hosts
  53. Show open ports (listenning port) on a host
    ./aaron.rb show --port 192.168.0.1
    
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Does PNG output SUCK? Do you love that old school black and white shell?
Try "#{$aaron_name} help search" and find out how to analyse the output "in depth"!

Another cool tool is aaron_import.rb. copy it to metasploit as a pluin folder and enjoy it!
      BANNER
    end
  end
  
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
      
  desc "stdin", "Pipe netstat result into aaron"
  method_option :os,       :type => :string,  :default => "#{$aa_os[0]}", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
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
  method_option :os,       :type => :string,  :default => "#{$aa_os[0]}", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
  def file(nsfile)
    puts "file: nsfile=#{nsfile}" if options[:verbose]
    
    prologue
    master.parse_netstat(File.read(nsfile))
    epilogue
  end

  desc "redraw", "Redraw an existing diagram (set at least one of --pdf or --png optoins)"
  def redraw
    puts "redraw: #{options[:project]}" if options[:verbose]
    
    prologue
    epilogue
  end

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
  def ssh(host)
    puts "#{$aa_ban["inf"]} ssh: #{host}:#{options[:port]}, user=#{options[:user]}" if options[:verbose]
    
    #note: :port must pass as last argument
    if options["key"].nil? then
      ssh = Net::SSH.start(host, options[:user], :password => options[:pass], :port => options[:port].to_i) 
    else
      ssh = Net::SSH.start(host, options[:user], :password => options[:pass], :keys => [options["key"]], :port => options[:port].to_i)
    end

    if not ssh.nil? then
      puts "#{$aa_ban["inf"]} ssh: Connection Established, OS: #{options[:os]}" if options[:verbose]
      hs = ssh.exec!( $aa_hostname[ options[:os] ] )
      ov = ssh.exec!( $aa_os_ver[ options[:os] ] )      
      ad = ssh.exec!( $aa_adapter[ options[:os] ] )
      rt = ssh.exec!( $aa_route[ options[:os] ] )            
      ns = ssh.exec!( $aa_netstat[ options[:os] ] )
      puts "#{$aa_ban["inf"]} netstat result:\n#{ns}" if options[:verbose]
      
      prologue
      
      master.name = hs
      master.info = ov
      master.deepinfo = ad + rt 
      
      master.parse_netstat   ( ns )
      
      epilogue
      ssh.close()
    end
  
  # rescue => details
  #  puts "#{$aa_ban["err"]} SSH Failed #{details}"    
  end
  
  desc "metasploit {SESION_ID}", "#{$aa_ban["exp"]} Execute commands through a metasploit shell session" 
  method_option :shell,             :type => :boolean,  :default => true
  method_option :meterpreter,       :type => :boolean,  :default => false
  method_option :os,                :type => :string,  :default => "#{$aa_os[0]}", :required => true,
                :banner => "TARGET_OS", :desc => "Values: #{$aa_os}"
  def metasploit(sid)
    puts "#{$aa_ban["inf"]} adb IS NOT IMPLEMENTED YET!" if options[:verbose]
    return
    
    msf = MSFPipe.new
    
    if not msf.nil? then
      puts "#{$aa_ban["inf"]} METASPLOIT: OS: #{options[:os]}" if options[:verbose]
      
      ot = msf.exec("sessions -i #{sid}")
      
      putinf "METASPLOIT: #{ot}"
      if ot.include? "Invalid" then
        puterr "METASPLOIT: Session not found!"
        return
      end
      
      # hs = msf.exec( $aa_hostname[ options[:os] ] )
      # ov = msf.exec( $aa_os_ver[ options[:os] ] )      
      # ad = msf.exec( $aa_adapter[ options[:os] ] )
      # rt = msf.exec( $aa_route[ options[:os] ] )            
      # ns = msf.exec( $aa_netstat[ options[:os] ] )
      # puts "#{$aa_ban["inf"]} netstat result:\n#{ns}" if options[:verbose]
      
      # prologue
      
      # master.name = hs
      # master.info = ov
      # master.deepinfo = ad + rt 
      
      # master.parse_netstat   ( ns )
      
      # epilogue
      # msf.exec("exit")
    end
  end
    
  desc "psexec {HOST}", "#{$aa_ban["exp"]} Execute commands via a 'psexec' connection the remote (Windows) host (requires metasploit)"
  method_option :user,        :type => :string,   :alias => "-l", :banner => "SMB_USERNAME", :require => true
  method_option :pass,        :type => :string,   :alias => "-p", :banner => "SMB_PASSWORD", :desc => "SMB Password or a valid SAM hash (pass-the-hash)"
  method_option :domain,      :type => :string,   :default => "WORKGROUP", :alias => "-d", :banner => "SMB_DOMAIN"
  method_option :os,       :type => :string,  :default => "#{$aa_os[0]}", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
  def psexec(host)
    puts "#{$aa_ban["inf"]} psexec: host=#{host}, user=#{options[:user]}" if options[:verbose]
  
    cmd = "msfcli auxiliary/admin/smb/psexec_command RHOSTS='#{host}' SMBUser='#{options[:user]}'"
    cmd = cmd + " SMBPass='#{options[:pass]}'" if not options[:pass].nil?
    cmd = cmd + " SMBDomain='#{options[:domain]}'" if not options[:domain].nil?
    
    hs = %x( #{cmd} COMMAND='#{$aa_hostname[ options[:os] ]}' E )
    ov = %x( #{cmd} COMMAND='#{$aa_os_ver[ options[:os] ]}' E )
    ad = %x( #{cmd} COMMAND='#{$aa_adapter[ options[:os] ]}' E )
    rt = %x( #{cmd} COMMAND='#{$aa_route[ options[:os] ]}' E )
    ns = %x( #{cmd} COMMAND='#{$aa_netstat[ options[:os] ]}' E )
    
    puts "#{$aa_ban["inf"]} netstat result:\n#{ns}" if options[:verbose]
    prologue
    
    master.name = hs
    master.info = ov
    master.deepinfo = ad + rt
    
    master.parse_netstat   ( ns )
    epilogue
  end

  desc "adb", "#{$aa_ban["exp"]} Execute commands via an 'adb' shell (android)"
  method_option :os,       :type => :string,  :default => "#{$aa_os[0]}", :required => true,
    :banner => "TARGET_OS",
    :desc => "Values: #{$aa_os}"
  def adb()
    puts "#{$aa_ban["inf"]} adb IS NOT IMPLEMENTED YET!" if options[:verbose]
  end
  
  desc "search", "Search something! (e.g. all windows clients connected to 192.168.0.1 on port 22)"
  method_option :src_os,      :type => :string, :alias => "-sos",  :banner => "SRC_OS",      :desc => "source os filter"
  method_option :dst_os,      :type => :string, :alias => "-dos",  :banner => "DST_OS",      :desc => "destination os filter"
  method_option :src_port,    :type => :string, :alias => "-sp",  :banner => "SRC_PORT",    :desc => "source port filter"
  method_option :dst_port,    :type => :string, :alias => "-dp",  :banner => "DST_PORT",    :desc => "destination port filter"
  method_option :src,         :type => :string, :alias => "-s",   :banner => "SRC_ADDRESS", :desc => "source filter"
  method_option :dst,         :type => :string, :alias => "-d",   :banner => "DST_ADDRESS", :desc => "destination filter"
  method_option :text,        :type => :string, :alias => "-t",   :banner => "TEXT",        :desc => "text filter"
  method_option :project,  :type => :string, :default => 'test.nmg', :alias => "-i", :required => true,
      :desc => "An existing #{$aa_ext}"
  method_option :msf,         :type => :boolean, :default => false, :desc => "Add results to metasploit"
  method_option :msf_workspace,         :type => :string, :default => "default", :desc => "Set metasploit workspace"
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
  
  desc "show", "Print more info about a HOST (some of them are not shown in png or pdf)"
  method_option :info,        :type => :string, :alias => "-i", :banner => "HOST", :desc => "Show all information about a host"
  method_option :port,        :type => :boolean, :banner => "HOST", :desc => "List open ports on a host"
  method_option :hosts,       :type => :boolean, :default => false, :alias => "-a", :desc => "Show all hosts"
  method_option :project,  :type => :string, :default => 'test.nmg', :alias => "-i", :required => true,
      :desc => "An existing #{$aa_ext}"
  method_option :msf,         :type => :boolean, :default => false, :desc => "Add results to metasploit"
  method_option :msf_workspace,         :type => :string, :default => "default", :desc => "Set metasploit workspace"
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
  
  desc "edit", "Edit a HOST"
  method_option :project,  :type => :string, :default => 'test.nmg', :alias => "-i", :required => true,
        :desc => "An existing #{$aa_ext}"
  def edit(host)
    @master.load_db(options[:project], true)
    
    @master.edit(host)
  end
end

Aaron.start

