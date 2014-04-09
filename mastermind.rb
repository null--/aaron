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

require 'graphviz'
require 'fileutils'
require 'active_record'

#-------------------------------------------------------------------------- #
##
# Host class
# contains information about a host
class Host < ActiveRecord::Base
  has_many :ips # , :class_name => "IP", :foreign_key => "host_id"
  
#-------------------------------------------------------------------------- #
  ##
  # find OS type based on +info+ column
  def find_os
    return nil if self.info.nil?
    
    return "win"      if self.info.downcase.include? "win"
    return "linux"    if self.info.downcase.include? "linux"
    return "bsd"      if self.info.downcase.include? "bsd"
    return "solaris"  if self.info.downcase.include? "sun"
    return "solaris"  if self.info.downcase.include? "solaris"
    return "solaris"  if self.info.downcase.include? "oracle"
    return "linux"    if self.info.downcase.include? "linux"
    
    nil
  end
end

#-------------------------------------------------------------------------- #
##
# IP class
class Ip < ActiveRecord::Base
  belongs_to :host # , :class_name => "Host", :foreign_key => "host_id"
  has_many   :start_edges , :class_name => "Edge", :foreign_key => "src_ip_id"
  has_many   :end_edges , :class_name => "Edge", :foreign_key => "dst_ip_id"
  
  # def edges
  #   return start_edges.concat end_edges if not start_edges.nil?
  #   return end_edges.concat start_edges if not end_edges.nil?
  #   nil
  # end
end

#-------------------------------------------------------------------------- #
##
# Edge class
class Edge < ActiveRecord::Base
  belongs_to :src_ip, :class_name => "Ip", :foreign_key => "src_ip_id"
  belongs_to :dst_ip, :class_name => "Ip", :foreign_key => "dst_ip_id"
end

#-------------------------------------------------------------------------- #
##
# generates a random string
def rand_str
  (0...8).map { (65 + rand(26)).chr }.join
end

#-------------------------------------------------------------------------- #
class GraphViz::Types::LblString
  def norm
    s = @data.to_s
    s.gsub("\\\\", "\\").gsub("\\n", "\n").gsub("\"", "") 
  end
end

#-------------------------------------------------------------------------- #
class GraphViz::Types::EscString
  def norm
    s = @data.to_s
    s.gsub("\\\\", "\\").gsub("\\n", "\n").gsub("\"", "")
  end
end

#-------------------------------------------------------------------------- #
class Numeric
  def percent_of(n)
    (self.to_f / n.to_f * 100.0).to_i.to_s + "%"
  end
end

#-------------------------------------------------------------------------- #
##
# The master mind rules behind aaron
class MasterMind
  attr_reader   :graph # GraphViz object
  attr_reader   :host_node # +Host+ object contains information about current processing host
  attr_reader   :latest_targets # list of targets found during a search or etc.
  
  attr_accessor :verbose
  attr_accessor :os
  attr_accessor :update
  attr_accessor :backup
  attr_accessor :loopback # don not ignore localhost to localhost conections
  attr_accessor :dead # do not ignore dead connections

  attr_accessor :name
  attr_accessor :info
  attr_accessor :deepinfo
  attr_accessor :comment
  
  @db_axa # ActiveRecord object

#-------------------------------------------------------------------------- #
  def puterr(t)
    puts "#{$aa_ban["err"]} #{t}"
  end

#-------------------------------------------------------------------------- #
  def putinf(t)
    puts "#{$aa_ban["inf"]} #{t}" if @verbose
  end

#-------------------------------------------------------------------------- # 
  def initialize(verbose, args={})
    @latest_targets = Array.new
    
    @verbose = verbose
    @os = args[:os]
    @update = true
    @update = false if args[:new]
    @backup = args[:backup] or false
    @loopback = args[:loopback]
    @dead = args[:dead] or false
    putinf "DEAD MODE ACTIAED!" if @dead

    @graph = nil
    @host_node = nil
    
    if @verbose then
      ActiveRecord::Base.logger = Logger.new(File.open('debug.log', 'w'))
    else
      ActiveRecord::Base.logger = Logger.new('/dev/null')
      ActiveRecord::Migration.verbose = false
    end

    puts "#{$aa_ban["msm"]} I want it all and I want it now!" if @verbose
  end

#-------------------------------------------------------------------------- #  
  def load_db(path, must_exists = false)
    puts "#{$aa_ban["msm"]} Loading #{path}..." if @verbose
    
    if not @update and not must_exists and not @backup then
      putinf "Removing existing project"
      FileUtils.rm(path) if File.exists? path
    end
    # TODO: update, backup
    
    ActiveRecord::Base.establish_connection(
      :adapter  => 'sqlite3',
      :database => path
      # :database => ':memory:'
    )
    
    unless @update then
      ActiveRecord::Schema.define do
        unless ActiveRecord::Base.connection.table_exists? 'hosts'
          create_table :hosts do |table|
            table.column :name,     :string
            table.column :info,     :text
            table.column :deepinfo, :text
            table.column :comment,  :text
          end
        end
        
        unless ActiveRecord::Base.connection.table_exists? 'ips'
          create_table :ips do |table|
            table.column :host_id,  :integer # FK
            table.column :addr,     :string
            table.column :comment,  :text
          end
        end
        
        unless ActiveRecord::Base.connection.table_exists? 'edges'
          create_table :edges do |table|
            table.column :src_ip_id,  :integer
            table.column :dst_ip_id,  :integer
            table.column :src_tag,    :string
            table.column :dst_tag,    :string
            table.column :proto,      :string
            table.column :type_tag,       :string
            table.column :comment,    :text
          end
        end
      end
    end
  # rescue => details
    # puts "#{$aa_ban["err"]} load_graph failed! #{details}" if @verbose
  end

#-------------------------------------------------------------------------- #
  ##
  # initializes graph  
  def new_graph
    @graph = GraphViz.new("aaron_graph", :type => "graph")
    
    @graph.node["shape"]  = $aa_node_shape
    @graph.node["color"]  = $clr_node
    @graph["color"]       = $clr_graph
    @graph["layout"]      = $aa_graph_layout
    @graph["ranksep"]     = "3.0"
    @graph["ratio"]       = "auto"
    
    if @graph.nil? then
      puterr "Failed to create graph"
      # raise "DEAD END!"
    end
  end

#-------------------------------------------------------------------------- #
  ##
  # draw_graph
  def draw_graph
    new_graph
    
    putinf "Drawing graph..."
    return if @graph.nil?
    
    # load host ips
    # host_ips = Array.new
    # @host_node.ips.each do |hip|
    #  host_ips << hip.addr
    # end
    
    # add hosts
    hosts_lbl = Array.new
    hosts = Host.find(:all)
    hosts.each do |h|
      mn  = ""
      mn = mn + h.name unless h.name.nil?
      mos = h.find_os
      
      unless h.ips.nil? then
        h.ips.each do |hip|
          mn = mn + "\n" + hip.addr
        end
      end
      
      hosts_lbl << mn
      
      if not mos.nil? then
        c = @graph.add_nodes(mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_cnode, :image => $aa_img_dir + mos + ".png")
      else
        c = @graph.add_nodes(mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_cnode)
      end
    end
    
    # add ips
    ips = Ip.find(:all)
    ips.each do |ip|
      next unless ip.host.nil?
      mn  = ip.addr
      
      c = @graph.add_nodes(ip.addr, "label" => mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_cnode)
    end
    
    # add edges
    edges = Edge.find(:all)
    edges.each do |e|
      color = $clr_tcp
      color = $clr_udp if e.proto.downcase == "udp"
      
      src = e.src_ip.addr
      dst = e.dst_ip.addr
      
      hosts_lbl.each do |lbl|
        src = lbl if lbl.include? src
        dst = lbl if lbl.include? dst
      end
      
      dp = e.dst_tag
      dp = dp + "\n" + $aa_known_ports[dp] unless $aa_known_ports[dp].nil?
      
      sp = e.src_tag
      sp = sp + "\n" + $aa_known_ports[sp] unless $aa_known_ports[sp].nil?
      
      c = @graph.add_edges(src, dst, "headlabel" => dp, "taillabel" => sp, "labeldistance" => "2", "color" => color)
    end
  end

#-------------------------------------------------------------------------- #
  def save_png(path)
    draw_graph if @graph.nil?
    @graph.output( :png => "#{path}.png" )
  # rescue => details
    # puterr "save_png failed! #{details}"
  end

#-------------------------------------------------------------------------- #
  def save_pdf(path)
    draw_graph if @graph.nil?
    @graph.output( :pdf => "#{path}.pdf" )
  # rescue => details
    # puterr "save_pdf failed! #{details}"
  end

#-------------------------------------------------------------------------- #  
  def save_graph(path)
    draw_graph if @graph.nil?
    @graph.output( $axa_format => "#{path}.#{$axa_format}" )
  # rescue => details
    # puterr "save_pdf failed! #{details}"
  end

#-------------------------------------------------------------------------- #  
  def detect_os_based_on_os_version(data)
    @os = "auto"
    
    @os = "win"      if data.downcase.include? "win"
    @os = "linux"    if data.downcase.include? "linux"
    @os = "bsd"      if data.downcase.include? "bsd"
    @os = "solaris"  if data.downcase.include? "sun"
    @os = "solaris"  if data.downcase.include? "solaris"
    @os = "solaris"  if data.downcase.include? "oracle"
    @os = "linux"    if data.downcase.include? "linux"
    
    puts "OS Detected: #{@os}"
  end
  
  def detect_os_based_on_netstat(data)
    max_os = "linux"
    max_mc = 0
    
    $aa_netstat_regex.each do |os, rex|
      mc = 0
      
      data.lines.each do |ln|
        cn = rex.match(ln)
        
        if not cn.nil? then
          mc = mc + 1
        end
      end
      
      if mc > max_mc then
        max_mc = mc
        max_os = os
      end
    end
    
    puts "OS Detected: #{max_os} | score: #{max_mc} of #{data.count("\n")}"
    @os = max_os
    
    return max_mc
  end

#-------------------------------------------------------------------------- #
  def detect_os_based_on_a_bunch_of_netstat(nss)
    mx = 0
    mo = "linux"
    
    nss.each do |ns|
      m = detect_os_based_on_netstat ns
      
      if m > mx then
        mx = m
        mo = @os
      end
    end
    
    @os = mo
    
    puts "[Final Guess] OS Detected: #{@os} | max freq: #{mx}}"
  end

#-------------------------------------------------------------------------- #  
  def parse_netstat(data)
    detect_os_based_on_netstat data if @os == "auto"
    
    rex = $aa_netstat_regex[@os]
    if !rex then
      puts "#{$aa_ban["err"]} Unkown OS"
      return
    end
    
    conns = Array.new
    hostips = Array.new
    hostips << "127.0.0.1" if @loopback
    i = 0
    data.lines.each do |ln|
      cn = rex.match(ln)
      
      if not cn.nil? then
        next if cn.names.include? "type" and not @dead and not (cn[:type].upcase.include? "ESTAB" or cn[:type].upcase.include? "LIST")
        
        print cn[:proto] + " # " if @verbose and cn.names.include?("proto")
        print cn[:src] + " : " + cn[:sport] + " <--> " + 
              cn[:dst] + " : " + cn[:dport] + 
              " (" + cn[:type] + ")" + "\n" if @verbose
              
        conns << cn
        
        if not cn[:src].include? "127.0.0.1" and not hostips.include? cn[:src] then
           hostips << cn[:src]
        end
      end
    end
    
    return if hostips.empty? or conns.empty?
    
    # find host node
    @host_node = nil
    hostips.each do |hip|
      nip = Ip.find(:first, :conditions => {:addr => hip})
      if not nip.nil? then
        @host_node = nip.host
        break
      end
    end
    
    # create new host node
    new_node = @host_node.nil?
    if new_node then
      @host_node = Host.new
      @host_node.save
    end
    
    if @info.nil? then
      @info = @os
    end
    
    @host_node.name = @name
    @host_node.info = @info
    @host_node.deepinfo = @deepinfo
    @host_node.comment = @comment
    @host_node.save
    
    # add new ip to node
    hostips.each do |hip|
      exists = false
      
      if not new_node then
        @host_node.ips
        @host_node.ips.each do |qip|
          if hip == qip.addr then
            exists = true
            break
          end
        end
      end
      
      if not exists then
        ip = Ip.new
        ip.host_id = @host_node.id
        ip.addr = hip
        ip.save
      end
    end
    
    # add edges
    total = conns.size
    cur = 0
    conns.each do |cn|
      cur = cur + 1
      STDOUT.write "\rProcessing connections:\t#{cur}/#{total}\t#{cur.percent_of(total)} \t"
      # add new IP
      left  = Ip.find(:first, :conditions => {:addr => cn[:src]})
      if left.nil? then
        left = Ip.new
        left.host_id = nil
        left.addr = cn[:src]
        left.save
      end
      right = Ip.find(:first, :conditions => {:addr => cn[:dst]})
      if right.nil? then
        right = Ip.new
        right.host_id = nil
        right.addr = cn[:dst]
        right.save
      end
      
      # puts cn
      # add new connections
      if not Edge.find(:first, :conditions => {
          :src_tag => cn[:sport], 
          :dst_tag => cn[:dport], 
          :src_ip_id => left.id, 
          :dst_ip_id => right.id}) 
      then
        e = Edge.new
        if cn.names.include?("proto") then
          e.proto = cn[:proto]
        else
          e.proto = "N/A"
        end
        e.src_tag = cn[:sport]
        e.src_ip_id = left.id
        
        e.dst_tag = cn[:dport]
        e.dst_ip_id = right.id
        
        e.type_tag = cn[:type] if cn.names.include? "type"
        e.save
        
        print "Edge: " + e.proto + " # " if @verbose
        print e.src_ip.addr + " : " + e.src_tag + " <--> " + 
            e.dst_ip.addr + " : " + e.dst_tag + 
            " (" + e.type_tag + ")" + "\n" if @verbose
      end
    end
    puts
  end

#-------------------------------------------------------------------------- #  
  def clear_latest_targets
    latest_targets.clear
  end

#-------------------------------------------------------------------------- #  
  def add_to_latest_targets(ip)
    tgt = Hash.new
    tgt[:ip] = ip.addr
    tgt[:name] = "N/A"
    tgt[:name] = ip.host.name unless ip.host.nil? or ip.host.name.nil?
    tgt[:info] = "N/A"
    tgt[:info] = ip.host.info unless ip.host.nil? or ip.host.info.nil?
    tgt[:comment] = "N/A"
    tgt[:comment] = ip.host.comment unless ip.host.nil? or ip.host.comment.nil?
    latest_targets << tgt
  end

#-------------------------------------------------------------------------- #  
  def print_ports(host)
    ip = Ip.find(:first, :conditions => {:addr => host})
    puterr "print_ports: HOST NOT FOUND: #{host}" if ip.nil?
    return if ip.nil?
    
    es = ip.start_edges
    
    unless es.nil? then
      puts "Open Ports:"
      es.each do |e|
        next unless e.type_tag.downcase.include? "list" # LISTENNING
        print "\t#{e.src_tag}"
        print ":\t#{$aa_known_ports[e.src_tag]}" unless $aa_known_ports[e.src_tag].nil?
        puts
      end
    end  
    
    es = ip.end_edges
    
    unless es.nil? then
      es.each do |e|
        next if e.type_tag.downcase.include? "list" # LISTENNING
        print "\t#{e.dst_tag}"
        print ":\t#{$aa_known_ports[e.dst_tag]}" unless $aa_known_ports[e.dst_tag].nil?
        puts
      end
    end
  end
  
  def print_hosts
    clear_latest_targets
    
    i = 1
    seen = Array.new
    
    Ip.find(:all).each do |ip|
      add_to_latest_targets ip
      
      if not ip.host.nil? and not ip.host.name.nil? then
        next if seen.include? ip.host.name
        
        puts "================="
        puts "Host #{i}: #{ip.host.name}" 
        seen << ip.host.name
        
        ip.host.ips.each do |mip|
          puts mip.addr
        end
      else
        puts "================="
        puts "Host #{i}:"    
        puts ip.addr
      end
      
      # puts "================="
      
      i = i + 1
    end
  end

#-------------------------------------------------------------------------- #  
  def print_info(host)
    clear_latest_targets
    
    ip = Ip.find(:first, :conditions => {:addr => host})
    puterr "print_info: HOST NOT FOUND: #{host}" if ip.nil?
    return if ip.nil?
    
    if ip.host.nil? then
      putinf "No Info!"
      return
    end
    
    add_to_latest_targets ip
    
    puts "IP:\n" + ip.addr
    puts "Name:\n" + ip.host.name + "================="         unless ip.host.name.nil?
    puts "Info:\n" + ip.host.info + "================="         unless ip.host.info.nil?
    puts "Deepinfo:\n" + ip.host.deepinfo + "=================" unless ip.host.deepinfo.nil?
    puts "Comment:\n" + ip.host.comment + "================="   unless ip.host.comment.nil?
  end
  
  def search(sos, dos, sp, dp, src, dst, txt)
    clear_latest_targets
    
    ips = Ip.find(:all)
    
    not_found = true
    
    ips.each do |ip|
      es = ip.start_edges
      next if es.nil?
      
      sos_m = sos.nil?
      dos_m = dos.nil?
      sp_m = sp.nil?
      dp_m = dp.nil?
      src_m = src.nil?
      dst_m = dst.nil?
      txt_m = txt.nil?
      
      es.each do |e|
        # puts e.src_ip.addr
        if e.src_tag == sp then
          sp_m = true
        end
        
        if e.dst_tag == dp then
          dp_m = true
        end
        
        if e.src_ip.addr == src then
          sp_m = true
        end
        
        if e.dst_ip.addr == dst then
          dst_m = true
        end
        
        if not e.src_ip.host.nil? and e.src_ip.host.find_os == sos then
          src_m = true
        end
        
        if not e.dst_ip.host.nil? and e.dst_ip.host.find_os == dos then
          dst_m = true
        end
      end
      
      if not ip.host.nil? and ip.host.find_os == sos then
        sos_m = true
      end
      
      if not ip.host.nil? and not ip.host.name.nil? and ip.host.name.downcase.include? txt.downcase then
        txt_m = true
      end
      
      if not ip.host.nil? and not ip.host.info.nil? and ip.host.info.downcase.include? txt.downcase then
        txt_m = true
      end
      
      if not ip.host.nil? and not ip.host.deepinfo.nil? and ip.host.deepinfo.downcase.include? txt.downcase then
        txt_m = true
      end
      
      if not ip.host.nil? and not ip.host.comment.nil? and ip.host.name.comment.include? txt.downcase then
        txt_m = true
      end
      
      # puts sos_m.to_s + dos_m.to_s + sp_m.to_s + dp_m.to_s + src_m.to_s + dst_m.to_s + txt_m.to_s
      if sos_m and dos_m and sp_m and dp_m and src_m and dst_m and txt_m then
        not_found = false
        
        add_to_latest_targets ip
        puts ip.addr
      end
    end
    
    puts "Nothing matched your search query!" if not_found
  end

#-------------------------------------------------------------------------- #  
  def edit(host)
    ip = Ip.find(:first, :conditions => {:addr => host})
    puterr "edit: HOST NOT FOUND: #{host}" if ip.nil? or ip.host.nil?
    return if ip.nil? or ip.host.nil?
    
    puts "Name:"
    puts ip.host.name
    puts "New Name:"
    ip.host.name = STDIN.gets
    
    puts "Info:"
    puts ip.host.info
    puts "New Info:"
    ip.host.info = STDIN.gets
    
    puts "Comment:"
    puts ip.host.comment
    puts "New Comment:"
    ip.host.comment = STDIN.gets
    
    ip.host.save
  end
  
#-------------------------------------------------------------------------- #
  ##
  # TODO
  def add_new_host
    ip = IP.new
    ip.host = Host.new
    
    puts "New IP:"
    ip.addr = STDIN.gets
    
    puts "New Name:"
    ip.host.name = STDIN.gets
    
    puts "New Info:"
    ip.host.info = STDIN.gets
    
    puts "New Comment:"
    ip.host.comment = STDIN.gets  
    
    ip.host.save
    ip.save
  end
  
#-------------------------------------------------------------------------- #
  ##
  # TODO
  def add_new_connection
    e = Edge.new
    
    puts "Source IP:"
    puts "Source Port:"
    puts "Destination IP:"
    puts "Destination Port:"
    puts "Protocol:"
    puts "Type (write LISTENING if source IP is a server):"
    puts "Comment:"
  end
  
#-------------------------------------------------------------------------- #
  ##
  # TODO
  def remove_host(host)
  end

end
