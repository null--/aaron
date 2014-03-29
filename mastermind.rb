require 'graphviz'
require 'fileutils'

class MasterMind
  attr_accessor :graph
  attr_accessor :verbose
  attr_accessor :os
  attr_accessor :update
  attr_accessor :backup
  @hostinfo
  @hostnode

  def initialize(verbose, os, update, backup)
    @verbose = verbose
    @os = os
    @update = update
    @backup = backup
    @hostinfo = ""
    @hostnode = nil

    puts "#{$nm_ban["msm"]} Let the hackin' begins!" if @verbose
  end
  
  def load_graph(path)
    if File.exists?(path) and @update then
      @graph = GraphViz.parse( path )
    else
      @graph = GraphViz.new("netmap")

      @graph.node["shape"] = "ellipse"
      @graph.node["color"] = "black"
      @graph["color"] = "black"
    end
  rescue => details
    puts "#{$nm_ban["err"]} load_graph failed! #{details}" if @verbose
  end

  def save_graph(path)
    if File.exists?(path) and @backup then
      FileUtils.mv(path, "#{path}.#{Time.now}.bak")
    end

    @graph.output( :dot => path )
  rescue => details
    puts "#{$nm_ban["err"]} save_graph failed! #{details}" if @verbose
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

  def parse_os_ver(data)
  end

  def parse_adapter(data)
  end

  def parse_route(data)
  end

  def parse_adapter(data)
  end

  def find_node(text)
    return nil if text.nil?
    
    puts "Find_Node: #{text}"
    @graph.each_node do |nd, nid|
      # puts "Node: #{nd}, ID:#{nid}"
      if nd.include? text then
        puts "MATCHED!"
        return nid
      end
    end
    nil
  end
  
  def find_edge(text, name1, name2)
    return nil if text.nil?
   
    puts "Find_Edge: #{text}, between #{name1}, #{name2}"

    @graph.each_edge do |ed|
      # puts ed.head_node.to_ruby + " | " + ed.tail_node.to_ruby

      # puts "Edge: #{ed["label"].to_s}, ID:#{ed}"
      if ed["label"].to_s.include? text and 
        ((ed.head_node.to_ruby == name1 and ed.tail_node.to_ruby == name2) or
         (ed.head_node.to_ruby == name2 and ed.tail_node.to_ruby == name1) )
      then
        puts "EDGE MATCHED!"
        return ed
      end
    end
    puts "EDGE NOT FOUND!"
    nil
  end
  
  def add_node(name1, name2, lbl, color, reverse)    
    puts "Adding(#{@hostinfo}) #{name1} <-- #{lbl} --> #{name2}"
    
    # loopback
    if name1.include?("127.0.0.1") then
      name1 = @hostinfo.strip
      name2 = @hostinfo.strip
    end
    
    puts "Adding(#{@hostinfo.strip}) #{name1} <-- #{lbl} --> #{name2}"

    if @hostinfo.include?(name2) or (name1 == name2) then
      c = @hostnode
    else
      c = find_node(name2)
      c = @graph.add_nodes(name2, "style" => "filled", "color" => "gray") if c.nil?
    end
    
    #TODO: it's not geek
    return if not find_edge(lbl, name1, name2).nil?
    
    if reverse then
      @graph.add_edges(c, @hostnode, "label" => lbl, "color" => color)
    else
      @graph.add_edges(@hostnode, c, "label" => lbl, "color" => color)
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
      @hostnode = @graph.add_nodes(@hostinfo.strip, "style" => "filled", "color" => "green")
    else
      @hostnode.set do |nd|
        nd.color = "green"
        @hostinfo = @hostinfo + "\n" + nd.label.to_s
        nd.label = @hostinfo
      end
    end

    conns.each do |conn|      
      lbl = " s:#{conn[:sport]} d:#{conn[:dport]}"

      color = "red"
      color = "blue" if conn[:proto].downcase == "tcp"

      add_node(conn[:src].strip, conn[:dst].strip, lbl.strip, color, (conn[:type].include? "LISTEN"))
    end
  end
end
