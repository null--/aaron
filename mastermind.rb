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
# along with aaron.  If not, see http://www.gnu.org/licenses/.

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
  
  attr_accessor :max_edges
  attr_accessor :template
  
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

    @max_edges = args[:max_edges]
    # template = connectivity graph
    @max_edges = 1 if args[:template] == 0
    
    @template = args[:template]
    
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
    
    if not File.exist? path and @update then
      @update = false
    end
    
    if @backup then
      FileUtils.mv(path, path + "_" + Time.now.strftime("%Y-%m-%d_%H-%M-%S") + ".axa") if File.exists? path
    end
    
    if not @update and not must_exists then
      putinf "Removing existing project"
      FileUtils.rm(path) if File.exists? path
    end
    
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
    @graph["ranksep"]     = "2.0"
    @graph["overlap"]     = "false"
    #@graph["ratio"]       = "auto"
    
    if @graph.nil? then
      puterr "Failed to create graph"
      # raise "DEAD END!"
    end
    
    # puts "Maximum Number of Edges: " + @max_edges.to_s
  end

#-------------------------------------------------------------------------- #
def add_host_to_graph(mn, mos)
  if not mos.nil? then
    c = @graph.add_nodes(mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_node_seen, :image => $aa_img_dir + mos + ".png")
  else
    c = @graph.add_nodes(mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_node_seen)
  end
end

#-------------------------------------------------------------------------- #
def add_ip_to_graph(addr)
  putinf "adding ip: #{addr}"
  c = @graph.add_nodes(addr, "label" => addr, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_node_unseen)
end

#-------------------------------------------------------------------------- #
def add_connection_to_graph(src, dst, sp, dp, color)
  # puts src + dst + sp + dp + color

  case @template
  when 0
    c = @graph.add_edges(src, dst, "color" => color)
  when 1
    c = @graph.add_edges(src, dst, "headlabel" => dp, "taillabel" => sp, "labeldistance" => "2", "color" => color)
      
  when 2
    c = @graph.add_edges(src, dst, "label" => "src:" + sp + " dst: " + dp, "labeldistance" => "2", "color" => color)
      
  when 3
    ts = rand_str
    td = rand_str
    @graph.add_nodes(ts, "label" => sp, "shape" => $aa_stag_shape, "style" => "filled", "color" => $clr_tag)
    @graph.add_nodes(td, "label" => dp, "shape" => $aa_dtag_shape, "style" => "filled", "color" => $clr_tag)
    @graph.add_edges(src, ts, "color" => color)
    @graph.add_edges(ts, td, "color" => color)
    @graph.add_edges(td, dst, "color" => color)
  
  when 4
    ts = rand_str
    @graph.add_nodes(ts, "label" => sp, "shape" => $aa_stag_shape, "style" => "filled", "color" => $clr_tag)
    @graph.add_edges(src, ts, "color" => color)
    @graph.add_edges(ts, dst, "label" => dp, "color" => color)
    
  end
end

#-------------------------------------------------------------------------- #
  ##
  # draw_host
  def draw_host(host_id)
    new_graph

    h = Host.find(:first, :conditions => {:id => host_id})

    host_lbl = ""
    host_lbl = h.name unless h.name.nil?
    if not h.ips.nil? then
      h.ips.each do |hip|
        host_lbl = host_lbl + "\n" + hip.addr
      end
    end

    putinf "Draw Host: #{host_lbl}"
    
    add_host_to_graph(host_lbl, h.find_os)
    
    edg = Array.new
    h.ips.each do |i|
      i.start_edges.each do |e|
        edg << e
      end
      i.start_edges.each do |e|
        edg << e
      end
    end
    
    iconns = Hash.new
    edg.each do |e|
      src = nil
      dst = nil
      once = false
    
      unless host_lbl.include? e.src_ip.addr
        add_ip_to_graph(e.src_ip.addr)
        src = e.src_ip.addr
      else
        once = true
        src = host_lbl
      end
                    
      unless host_lbl.include? e.dst_ip.addr
        add_ip_to_graph(e.dst_ip.addr)
        dst = e.dst_ip.addr
      else
        once = true
        dst = host_lbl
      end
      
      next if not once or dst.nil? or src.nil?
      color = $clr_tcp
      color = $clr_udp if not e.proto.nil? and e.proto.downcase == "udp"
      
      iconns[src+dst] = 0 if iconns[src+dst].nil?
      iconns[dst+src] = 0 if iconns[dst+src].nil?
      
      iconns[src+dst] = iconns[src+dst] + 1
      iconns[dst+src] = iconns[dst+src] + 1
      next if iconns[src+dst] + iconns[dst+src] > 2 * @max_edges
      
      add_connection_to_graph(src, dst, e.src_tag, e.dst_tag, color)
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
      
      unless h.ips.nil? then
        h.ips.each do |hip|
          mn = mn + "\n" + hip.addr
        end
      end
      
      hosts_lbl << mn
      # puts mn
      add_host_to_graph(mn, h.find_os)
    end
    
    # add ips
    ips = Ip.find(:all)
    ips.each do |ip|
      next unless ip.host.nil?
      mn  = ip.addr
    
      add_ip_to_graph(mn)
    end
    
    # add edges
    iconns = Hash.new
    edges = Edge.all
    edges.each do |e|
      next if e.src_ip.nil? or e.dst_ip.nil?

      color = $clr_tcp
      color = $clr_udp if not e.proto.nil? and e.proto.downcase == "udp"
      
      src = e.src_ip.addr
      dst = e.dst_ip.addr
      
      hosts_lbl.each do |lbl|
        src = lbl if lbl.include? src
        dst = lbl if lbl.include? dst
      end
      
      dp = e.dst_tag
      dp = dp + " " + $aa_known_ports[dp] unless $aa_known_ports[dp].nil?
      
      sp = e.src_tag
      sp = sp + " " + $aa_known_ports[sp] unless $aa_known_ports[sp].nil?
      
      iconns[src+dst] = 0 if iconns[src+dst].nil?
      iconns[dst+src] = 0 if iconns[dst+src].nil?
      
      iconns[src+dst] = iconns[src+dst] + 1
      iconns[dst+src] = iconns[dst+src] + 1
      next if iconns[src+dst] + iconns[dst+src] > 2 * @max_edges
      
      add_connection_to_graph(src, dst, sp, dp, color)
    end
  end

#-------------------------------------------------------------------------- #
  def save_png(path, host_id=nil)
    # draw_graph if @graph.nil?
    # @graph.output( :png => "#{path}.png" )
    if host_id.nil?
      draw_graph # if @graph.nil?
      @graph.output( :png => "#{path}.png" )
    else
      draw_host(host_id) # if @graph.nil?
      @graph.output( :png => "#{path}.#{host_id}.png" )
    end
  # rescue => details
    # puterr "save_png failed! #{details}"
  end

#-------------------------------------------------------------------------- #
  def save_pdf(path, host_id=nil)
    # draw_graph if @graph.nil?
    # @graph.output( :pdf => "#{path}.pdf" )
    if host_id.nil?
      draw_graph # if @graph.nil?
      @graph.output( :pdf => "#{path}.pdf" )
    else
      draw_host(host_id) # if @graph.nil?
      @graph.output( :pdf => "#{path}.#{host_id}.pdf" )
    end
  # rescue => details
    # puterr "save_pdf failed! #{details}"
  end

#-------------------------------------------------------------------------- #  
  def save_graph(path, host_id = nil)
    if host_id.nil?
      draw_graph # if @graph.nil?
      @graph.output( $aa_format => "#{path}.#{$aa_format}" )
    else
      draw_host(host_id) # if @graph.nil?
      @graph.output( $aa_format => "#{path}.#{host_id}.#{$aa_format}" )
    end
  # rescue => details
    # puterr "save_pdf failed! #{details}"
  end

#-------------------------------------------------------------------------- #
  ##
  # yield(cn)
  def netstat_regex_loop(data, rex)
    rex_pos = 0
    while (cn = data.match(rex, rex_pos)) do
      rex_pos = cn.end(0)
      
      yield(cn)
    end
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

#-------------------------------------------------------------------------- #  
  def detect_os_based_on_netstat(data)
    max_os = "linux"
    max_mc = 0
    
    $aa_netstat_regex.each do |os, rex|
      mc = 0
      
      netstat_regex_loop(data, rex) do |cn|       
        mc = mc + 1
        # puts cn
      end
      
      # putinf "OS: #{os} Matches: #{mc}"
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
    putinf "Parsing netstat..."
    detect_os_based_on_netstat data if @os == "auto"
    
    rex = $aa_netstat_regex[@os]
    if !rex then
      puts "#{$aa_ban["err"]} Unkown OS"
      return
    end
    
    conns = Array.new
    hostips = Array.new
    
    # TODO: loopback is not geek!
    if @loopback then
      hostips << "127.0.0.1" 
      conns << "127.0.0.1"
      putinf "ADDING 127.0.0.1"
    end
    
    i = 0
    netstat_regex_loop(data, rex) do |cn|
    
      next if cn.names.include? "type" and not @dead and not (cn[:type].upcase.include? "ESTAB" or cn[:type].upcase.include? "LIST")
      
      print cn[:proto] + " # " if @verbose and cn.names.include?("proto")
      print cn[:src] + " : " + cn[:sport] + " <--> " + 
            cn[:dst] + " : " + cn[:dport] + 
            " (" + cn[:type] + ")" + "\n" if @verbose
      
      if not cn[:src].include? "127.0.0.1" then
        conns << cn
      end
      
      if not cn[:src].include? "127.0.0.1" and not hostips.include? cn[:src] then
         hostips << cn[:src]
         putinf "-- ADDED"
      end

    end
    
    return if hostips.empty? or conns.empty?
    
    # find host node
    @host_node = nil
    Host.all.each do |h|
      h.ips.each do |ip|
        hostips.each do |hip|          
          if ip.addr == hip then
            putinf "#{hip} was Found! (#{h.id})"
            @host_node = h
            break
          end
        end
        
        break unless @host_node.nil?
      end
      
      break unless @host_node.nil?
    end
    
    # create new host node
    new_node = @host_node.nil?
    if new_node then
      @host_node = Host.new
      @host_node.save
      
      putinf "-- New Host"
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
        ip = Ip.find(:first, :conditions => {:addr => hip})
        ip = Ip.new if ip.nil?
        ip.host_id = @host_node.id
        ip.addr = hip
        ip.save
      end
    end
    
    # add edges
    total = conns.size
    cur = 0
    
    # make things faster!
    mips = Ip.all.to_a
    medge = Edge.all.to_a
    conns.each do |cn|
      cur = cur + 1
      STDOUT.write "\rProcessing connections:\t#{cur}/#{total}\t\t #{cur.percent_of(total)} \t"
      # add new IP
      left = nil
      right = nil
      mips.each do |i|
        if i.addr == cn[:src] then
          left = i
        elsif i.addr == cn[:dst] then
          right = i
        end
      end
      # left  = Ip.find(:first, :conditions => {:addr => cn[:src]})
      if left.nil? then
        left = Ip.new
        left.host_id = nil
        left.addr = cn[:src]
        left.save
        mips << left
      end
      # right = Ip.find(:first, :conditions => {:addr => cn[:dst]})
      if right.nil? then
        right = Ip.new
        right.host_id = nil
        right.addr = cn[:dst]
        right.save
        mips << right
      end
      
      if (left.host_id == right.host_id or
         left.addr.include? "127.0.0.1" or right.addr.include?"127.0.0.1") and 
         not @loopback 
      then
        putinf "Skipped (loopback)"
        next
      end
      
      # puts cn
      # add new connections
      #if not Edge.find(:first, :conditions => {
      #    :src_tag => cn[:sport], 
      #    :dst_tag => cn[:dport], 
      #    :src_ip_id => left.id, 
      #    :dst_ip_id => right.id}) 
      #then
      
      found = false
      medge.each do |me|
        if me.src_tag == cn[:sport] and
           me.dst_tag == cn[:dport] and
           me.src_ip_id == left.id and
           me.dst_ip_id == right.id
        then
          found = true
          next
        end
      end
      if not found then
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
          
        medge << e
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
  def edit_host(host, name , info, deepinfo, comment)
    ip = Ip.find(:first, :conditions => {:addr => host})
    puterr "edit: HOST NOT FOUND: #{host}" if ip.nil? or ip.host.nil?
    return if ip.nil? or ip.host.nil?
    
    ip.host.name = name unless name.nil?
    ip.host.info = info unless info.nil?
    ip.host.deepinfo = deepinfo unless deepinfo.nil?
    ip.host.comment = comment unless comment.nil?
    
    ip.host.save
    ip.save
  end
  
#-------------------------------------------------------------------------- #
  ##
  # TODO
  def add_new_host(addr, name, info, deepinfo, comment)
    ip = Ip.new
    ip.host = Host.new
    
    ip.addr = addr
    ip.host.name = name
    ip.host.info = info
    ip.host.deepinfo = deepinfo
    ip.host.comment = comment
    
    ip.host.save
    ip.save
  end
  
#-------------------------------------------------------------------------- #
  def add_new_connection(src, sport, dst, dport, proto, type, comment)
    e = Edge.new
    e.src_ip = Ip.find(:first, :conditions => {:addr => src})
    e.dst_ip = Ip.find(:first, :conditions => {:addr => dst})
    
    if e.src_ip.nil? then
      puterr "Source IP not found: #{src}"
      return
    end
    
    if e.dst_ip.nil? then
      puterr "Dst IP not found: #{dst}"
      return
    end
    
    e.src_tag = sport
    e.dst_tag = dport
    e.proto = proto
    e.type_tag = type
    e.comment = comment
    
    e.save
  end

#-------------------------------------------------------------------------- #
  def edit_connection(src, sport, dst, dport, proto, type, comment)
    Edge.all.each do |e|
      if e.src_ip.addr == src and e.dst_ip.addr == dst and e.src_tag == sport and e.dst_tag == dport then
        
        e.proto = proto unless proto.nil?
        e.type_tag = type unless type.nil?
        e.comment = comment unless comment.nil?
        e.save
        
        return
      end
    end
    
    puterr "Connection not found"
  end
  
#-------------------------------------------------------------------------- #
  def remove_host(host)
    id = Ip.find(:first, :conditions => {:addr => host})
    if id.nil? then
      puterr "Host not found: #{host}"
      return
    end
    
    Ip.destroy(id.id)
  end

#-------------------------------------------------------------------------- #
  def remove_connection(src, sport, dst, dport)
    Edge.all.each do |e|
      if e.src_ip.addr == src and e.dst_ip.addr == dst and e.src_tag == sport and e.dst_tag == dport then
        Edge.destroy(e.id)
        return
      end
    end
    
    puterr "Connection not found"
  end
end
