require 'graphviz'
require 'fileutils'

class MasterMind
  attr_reader   :graph
  attr_reader   :verbose
  attr_reader   :os
  attr_reader   :update
  attr_reader   :backup
  attr_accessor :hostinfo
  attr_reader   :hostnode
  attr_reader   :loopback
  
  def initialize(verbose, os, update, backup, loopback)
    @verbose = verbose
    @os = os
    @update = update
    @backup = backup
    @hostinfo = ""
    @hostnode = nil
    @loopback = loopback
    
    puts "#{$nm_ban["msm"]} hack like a pro!" if @verbose
  end
  
  def load_graph(path)
    if File.exists?(path) and @update then
      @graph = GraphViz.parse( path )
      puts "#{$nm_ban["err"]} Failed to load diagram" if @graph.nil?
    end
    
    if @graph.nil?
      @graph = GraphViz.new("netmap", )
      
      @graph.node["shape"]  = $nm_node_shape
      @graph.node["color"]  = $clr_node
      @graph["color"]       = $clr_graph
      @graph["layout"]      = $nm_graph_layout
      @graph["ranksep"]     = "3.0"
      @graph["ratio"]       = "auto"
    end
  # rescue => details
    # puts "#{$nm_ban["err"]} load_graph failed! #{details}" if @verbose
  end

  def save_graph(path)
    if File.exists?(path) and @backup then
      FileUtils.mv(path, "#{path}.#{Time.now}.bak")
    end
    
    # @graph.each_edge do |ed|
    #   puts ed["head_lp"].to_s
    #   ed.delete("head_lp") if not ed["head_lp"].nil?
    #   ed.delete("tail_lp") if not ed["tail_lp"].nil?
    # end
    
    @graph.output( :canon => path )
  # rescue => details
  #   puts "#{$nm_ban["err"]} save_graph failed! #{details}" if @verbose
  end

  def save_png(path)
    @graph.output( :png => "#{path}.png" )
  rescue => details
    puts "#{$nm_ban["err"]} save_png failed! #{details}" if @verbose
  end
  
  def save_pdf(path)
    @graph.output( :pdf => "#{path}.pdf" )
  rescue => details
    puts "#{$nm_ban["err"]} save_pdf failed! #{details}" if @verbose
  end

  def parse_hostname(data)
    @hostinfo = @hostinfo + "Name: " + data.strip if not @hostinfo.include? data
  end
  
  def parse_os_ver(data)
    @hostinfo = @hostinfo + "Ver: " + data.strip if not @hostinfo.include? data
  end

  def parse_adapter(data)
    @hostinfo = @hostinfo + "Adapters: " + data.strip if not @hostinfo.include? data
  end

  def parse_route(data)
    @hostinfo = @hostinfo + "Route: " + data if not @hostinfo.include? data
  end

  def find_node(text)
    return nil if text.nil? or @graph.nil?
    
    puts "#{$nm_ban[:inf]} Find_Node: #{text}"
    @graph.each_node do |nd, nid|
      # puts "Node: #{nd}, ID:#{nid}"
      if nd.include? text then
        puts "#{$nm_ban[:inf]} MATCHED!"
        return nid
      end
    end
    nil
  end
  
  def find_edge(head, tail, name1, name2)
    return nil if head.nil? or tail.nil?
   
    puts "#{$nm_ban[:inf]} Find_Edge: #{head}/#{tail}, between #{name1}, #{name2}"

    @graph.each_edge do |ed|
      # puts ed.head_node.to_ruby + " | " + ed.tail_node.to_ruby

      # puts "Edge: #{ed["headlabel"].to_s}/#{ed["taillabel"].to_s}, ID:#{ed}"
      if ed["headlabel"].to_s.include? head and ed["taillabel"].to_s.include? tail and
        ((ed.head_node.to_ruby == name1 and ed.tail_node.to_ruby == name2) or
         (ed.head_node.to_ruby == name2 and ed.tail_node.to_ruby == name1) )
      then
        puts "#{$nm_ban[:inf]} EDGE MATCHED!"
        return ed
      end
    end
    puts "#{$nm_ban[:inf]} EDGE NOT FOUND!"
    nil
  end
  
  def add_node(name1, name2, head, tail, color, reverse)    
    puts "#{$nm_ban[:inf]} Adding(#{@hostinfo}) #{name1} <-- #{head}/#{tail} -- #{reverse.to_s} --> #{name2}"
    
    # loopback
    return if not @loopback and (name1.include?("127.0.0.1") or @hostinfo.include?(name2) or (name1 == name2))
    
    if name1.include?("127.0.0.1") then
      name1 = @hostinfo.strip
      name2 = @hostinfo.strip
    end
    
    if @hostinfo.include?(name2) or (name1 == name2) then
      c = @hostnode
    else
      c = find_node(name2)
      c = @graph.add_nodes(name2, "shape" => $nm_node_shape, "style" => "filled", "color" => $clr_cnode) if c.nil?
    end
    
    #TODO: it's not geek
    return if not find_edge(head, tail, name1, name2).nil?
    
    if true then
      @graph.add_edges(c, @hostnode, "headlabel" => head, "taillabel" => tail, "labeldistance" => "2", "color" => color)
    else
      @graph.add_edges(@hostnode, c, "headlabel" => tail, "taillabel" => head, "color" => color)
    end
  end

  def add_image
    @hostnode.set do |nd|
      nd.image = $nm_img_dir + @os + ".png"
    end
  end
  
  def parse_netstat(data)
    rex = $nm_netstat_regex[@os]
    if !rex then
      puts "#{$nm_ban["err"]} Unkown OS"
      return
    end
    
    # g = @graph.add_graph("netmap0", "label" => "#netmap report", "style" => "filled", "color" => "lightgrey")
    conns = [{}]
    i = 0
    for ln in data.lines do
      cn = rex.match(ln)
      if not cn.nil? then
        puts cn[:proto] + " # " + 
              cn[:src] + " : " + cn[:sport] + " <--> " + 
              cn[:dst] + " : " + cn[:dport] + 
              " (" + cn[:type] + ")" if @verbose
        conns[i] = cn
        i = i + 1
        
        if @hostnode.nil? and not (cn[:src].include? "127.0.0.1") then
           @hostnode = find_node(cn[:src])
        end

        # puts "-------------------------------------------------" if not a0.nil? 
        @hostinfo = @hostinfo + cn[:src] + "\n" if (not cn[:src].include? "127.0.0.1") and (not @hostinfo.include? cn[:src])
      end
    end

    #TODO it's not geek
    if @hostnode.nil? then
      @hostnode = @graph.add_nodes(@hostinfo.strip, "shape" => $nm_node_shape, "style" => "filled", "color" => $clr_pnode)
    else
      @hostnode.set do |nd|
        nd.color = $clr_pnode
        @hostinfo = @hostinfo + "\n" + nd.label.to_s
        nd.label = @hostinfo
      end
    end
    add_image

    conns.each do |conn|    
      next if conn[:proto].nil?
      
      color = $clr_tcp
      color = $clr_udp if conn[:proto].downcase == "udp"

      add_node(conn[:src].strip, conn[:dst].strip, conn[:sport].strip, conn[:dport].strip, color, (conn[:type].include? "LISTEN"))
    end
  end
end
