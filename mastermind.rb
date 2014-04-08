require 'graphviz'
require 'fileutils'
require 'active_record'

=begin
SQLite DB:
                                                                                            
   +----------------+           +-----------------+                                         
   | Host           |           | Edge            |                                         
   +----------------+           +-----------------+                                         
   | id (PK)        |           | id (PK)         |                                          
   | name           |           | src_ip    (FK)  |                                          
   | info           |           | dst_ip    (FK)  |                                          
   | deepinfo       |           | src_tag         |                                       
   | comment        |           | dst_tag         |                                         
   |                |           | proto           |                                         
   |                |           | comment         |                                         
   +----------------+           +-----------------+
          ^                          |
          |                          |
          |                          |
          |    +----------------+    |
          |    | IP             |    |
          |    +----------------+    |
          |    | id (PK)        |<---+
          +----| host_id (FK)   |
               | addr           |
               | comment        |
               |                |
               |                |
               |                |
               +----------------+
                                                                                            
=end

class Host < ActiveRecord::Base
  has_many :ips, :class_name => "IP"
  
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

class IP < ActiveRecord::Base
  belongs_to :host, :class_name => "Host"
  has_many   :edges, :class_name => "Edge"
end

class Edge < ActiveRecord::Base
  belongs_to :ip_src, :class_name => "IP"
  belongs_to :ip_dst, :class_name => "IP"
end

def rand_str
  (0...8).map { (65 + rand(26)).chr }.join
end

class GraphViz::Types::LblString
  def norm
    s = @data.to_s
    s.gsub("\\\\", "\\").gsub("\\n", "\n").gsub("\"", "") 
  end
end

class GraphViz::Types::EscString
  def norm
    s = @data.to_s
    s.gsub("\\\\", "\\").gsub("\\n", "\n").gsub("\"", "")
  end
end

class Numeric
  def percent_of(n)
    (self.to_f / n.to_f * 100.0).to_i.to_s + "%"
  end
end

class MasterMind
  attr_reader   :graph
  attr_reader   :host_node
  
  attr_accessor :verbose
  attr_accessor :os
  attr_accessor :update
  attr_accessor :backup
  attr_accessor :loopback
  attr_accessor :dead

  attr_accessor :name
  attr_accessor :info
  attr_accessor :deepinfo
  attr_accessor :comment
  
  @db_nmg
  
  def puterr(t)
    puts "#{$aa_ban["err"]} #{t}"
  end

  def putinf(t)
    puts "#{$aa_ban["inf"]} #{t}" if @verbose
  end
 
  def initialize(verbose, args={})
    @verbose = verbose
    @os = args[:os]
    @update = args[:update] or false
    @backup = args[:backup] or false
    @loopback = args[:loopback]
    @dead = args[:dead] or false
    putinf "DEAD MODE ACTIAED!" if @dead

    @graph = nil
    @host_node = nil
    
    if @verbose then
      ActiveRecord::Base.logger = Logger.new(File.open('debug.log', 'w'))
    else
      ActiveRecord::Base.logger = nil
    end

    puts "#{$aa_ban["msm"]} I want it all and I want it now!"
  end
  
  def load_db(path, must_exists = false)
    puts "#{$aa_ban["msm"]} Loading #{path}..." if @verbose
    
    if not @update and not must_exists and not @backup then
      putinf "Removing existing project"
      FileUtils.rm(path)
    end
    # TODO: update, backup
    
    ActiveRecord::Base.establish_connection(
      :adapter  => 'sqlite3',
      :database => path
      # :database => ':memory:'
    )
    
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
          table.column :host_id, :integer # FK
          table.column :addr,       :string
          table.column :comment,  :text
        end
      end
      
      unless ActiveRecord::Base.connection.table_exists? 'edges'
        create_table :edges do |table|
          table.column :src_ip,   :integer # FK
          table.column :dst_ip,   :integer # FK
          table.column :src_tag,     :string
          table.column :dst_tag,     :string
          table.column :proto,    :string
          table.column :comment,  :text
        end
      end
    end
  # rescue => details
    # puts "#{$aa_ban["err"]} load_graph failed! #{details}" if @verbose
  end
  
  def new_graph
    @graph = GraphViz.new("netmap", :type => "graph")
    
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
  
  def draw_graph
    new_graph
    
    return if @graph.nil?
    
    # load host ips
    host_ips = Array.new
    @host_node.ips.each do |hip|
      host_ips << hip.addr
    end
    
    # add ips
    ips = IP.find(:all)
    ips.each do |ip|
      mn  = ip.addr
      mn  = mn + "\n" + ip.host.name     if not ip.host.nil? and not ip.host.name.nil?
      mos = ip.host.find_os  if not ip.host.nil?
      
      if host_ips.include? ip.addr then
        c = @graph.add_nodes(ip.addr, "label" => mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_cnode, :image => $aa_img_dir + @os + ".png")
      elsif not ip.host.nil? and not mos.nil? then
        puts mos
        c = @graph.add_nodes(ip.addr, "label" => mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_cnode, :image => $aa_img_dir + mos + ".png")
      else
        c = @graph.add_nodes(ip.addr, "label" => mn, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_cnode)
      end
    end
    
    # add edges
    edges = Edge.find(:all)
    edges.each do |e|
      color = $clr_tcp
      color = $clr_udp if e.proto.downcase == "udp"
      src = IP.find(e.src_ip).addr
      dst = IP.find(e.dst_ip).addr
      c = @graph.add_edges(src, dst, "headlabel" => e.dst_tag, "taillabel" => e.src_tag, "labeldistance" => "2", "color" => color)
    end
  end
  
  def save_png(path)
    draw_graph if @graph.nil?
    @graph.output( :png => "#{path}.png" )
  # rescue => details
    # puterr "save_png failed! #{details}"
  end
  
  def save_pdf(path)
    draw_graph if @graph.nil?
    @graph.output( :pdf => "#{path}.pdf" )
  # rescue => details
    # puterr "save_pdf failed! #{details}"
  end
  
  def parse_netstat(data)
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
      nip = IP.find(:first, :conditions => {:addr => hip})
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
        ip = IP.new
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
      STDOUT.write "\rProcessing connections:\t#{cur}/#{total}\t#{cur.percent_of(total)}"
      # add new IP
      left  = IP.find(:first, :conditions => {:addr => cn[:src]})
      if left.nil? then
        left = IP.new
        left.host_id = nil
        left.addr = cn[:src]
        left.save
      end
      right = IP.find(:first, :conditions => {:addr => cn[:dst]})
      if right.nil? then
        right = IP.new
        right.host_id = nil
        right.addr = cn[:dst]
        right.save
      end
      
      # puts cn
      # add new connections
      if not Edge.find(:first, :conditions => {
          :src_tag => cn[:sport], 
          :dst_tag => cn[:dport], 
          :src_ip => left.id, 
          :dst_ip => right.id}) 
      then
        e = Edge.new
        if cn.names.include?("proto") then
          e.proto = cn[:proto]
        else
          e.proto = "N/A"
        end
        e.src_tag = cn[:sport]
        e.src_ip = left.id
        e.dst_tag = cn[:dport]
        e.dst_ip = right.id
        e.comment = cn[:type] if cn.names.include? "type"
        e.save
      end
    end
    puts
  end
  
  def print_hosts
    i = 1
    @graph.each_node do |nd, nid|
      puts "================="
      puts "Host #{i}:\n#{nd}"
      # puts "================="
      
      i = i + 1
    end
  end
  
  def print_info(host)
    nd = find_node(host.strip)
    puterr "HOST NOT FOUND" if nd.nil?
    return if nd.nil?
    puts nd["label"].norm.strip
    puts  "================="
    puts nd[$deep_tag].norm if not nd[$deep_tag].nil?
  end
end
