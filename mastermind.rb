require 'graphviz'
require 'fileutils'

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

class MasterMind
  attr_reader   :graph
  attr_reader   :verbose
  attr_reader   :os
  attr_reader   :update
  attr_reader   :backup
  attr_accessor :hostinfo
  attr_reader   :hostnode
  attr_reader   :deepinfo
  attr_reader   :loopback
  
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
    @hostinfo = ""
    @deepinfo = ""
    @hostnode = nil
    @loopback = args[:loopback]
    
    puts "#{$aa_ban["msm"]} I want it all and I want it now!" if @verbose
  end
  
  def load_graph(path, must_exists = false)
    puts "#{$aa_ban["msm"]} Loading #{path}..." if @verbose
    
    if File.exists?(path) and (@update or must_exists) then
      @graph = GraphViz.parse( path )
      puterr "Failed to load diagram" if @graph.nil?
    end
    
    if @graph.nil? and not must_exists then
      @graph = GraphViz.new("netmap", )
      
      @graph.node["shape"]  = $aa_node_shape
      @graph.node["color"]  = $clr_node
      @graph["color"]       = $clr_graph
      @graph["layout"]      = $aa_graph_layout
      @graph["ranksep"]     = "3.0"
      @graph["ratio"]       = "auto"
    end
    
    if @graph.nil? and must_exists then
      puterr "Failed to load graph"
      raise "DEAD END!"
    end
  # rescue => details
    # puts "#{$aa_ban["err"]} load_graph failed! #{details}" if @verbose
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
  #   puts "#{$aa_ban["err"]} save_graph failed! #{details}" if @verbose
  end

  def save_png(path)
    @graph.output( :png => "#{path}.png" )
  rescue => details
    puterr "save_png failed! #{details}"
  end
  
  def save_pdf(path)
    @graph.output( :pdf => "#{path}.pdf" )
  rescue => details
    puterr "save_pdf failed! #{details}"
  end

  def add_to_hostinfo(data)
    # not geek
    @hostinfo = @hostinfo + data.strip + "\n" if not @hostinfo.include? data
    add_to_deepinfo(data)
  end

  def add_to_deepinfo(data)
    putinf "DEEPINFO: #{data}"
    # not geek
    @deepinfo = @deepinfo + data + "\n" if not @deepinfo.include? data
  end

  def find_node(text)
    return nil if text.nil? or @graph.nil?
    
    putinf "Find_Node: #{text}"
    @graph.each_node do |nd, nid|
      # puts "Node: #{nd}, ID:#{nid}"
      if nd.include? text then
        putinf "MATCHED!"
        return nid
      end
    end
    nil
  end
  
  def find_edge(head, tail, name1, name2)
    return nil if head.nil? or tail.nil?
   
    putinf "Find_Edge: #{head}/#{tail}, between #{name1}, #{name2}"

    @graph.each_edge do |ed|
      # puts ed.head_node.norm + " | " + ed.tail_node.norm

      # puts "Edge: #{ed["headlabel"].norm}=#{head}/#{ed["taillabel"].norm}=#{tail}, #{ed.tail_node.norm}=#{name1} <--> #{ed.head_node.norm}=#{name2}"
      # print (ed["headlabel"].norm.include? head), (ed["taillabel"].norm.include? tail), (ed.head_node.include? name1), (ed.tail_node.include? name2), "\n"
      if (ed["headlabel"].norm.include? head) and (ed["taillabel"].norm.include? tail) and
         (ed.head_node.include? name1.strip) and (ed.tail_node.include? name2.strip)
      then
        putinf "EDGE MATCHED!"
        return ed
      end
    end
    putinf "EDGE NOT FOUND!"
    nil
  end
  
  def add_node(name1, name2, head, tail, color, reverse)    
    putinf "Adding(#{@hostinfo}) #{name1} <-- #{head}/#{tail} -- #{reverse.to_s} --> #{name2}"
    
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
      c = @graph.add_nodes(name2, "shape" => $aa_node_shape, "style" => "filled", "color" => $clr_cnode) if c.nil?
    end
    
    #TODO: it's not geek
    if not reverse then
      return if not find_edge(tail, head, name2, name1).nil?
    else
      return if not find_edge(head, tail, name1, name2).nil?
    end
    
    if reverse then
      @graph.add_edges(c, @hostnode, "headlabel" => head, "taillabel" => tail, "labeldistance" => "2", "color" => color)
    else
      @graph.add_edges(@hostnode, c, "headlabel" => tail, "taillabel" => head, "color" => color)
    end
  end

  def add_image
    @hostnode.set do |nd|
      nd.image = $aa_img_dir + @os + ".png"
    end
  end
  
  def parse_netstat(data)
    rex = $aa_netstat_regex[@os]
    if !rex then
      puts "#{$aa_ban["err"]} Unkown OS"
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
      @hostnode = @graph.add_nodes(@hostinfo.strip, 
          "shape" => $aa_node_shape, 
          "style" => "filled", 
          "color" => $clr_pnode, 
          $deep_tag => $deepinfo)
    else
      @hostnode.set do |nd|
        nd.color = $clr_pnode
        if not nd.label.to_s.include? @hostinfo then
          @hostinfo = @hostinfo + "\n" + nd.label.to_s
          nd.label = @hostinfo
        end
        nd[$deep_tag] = @deepinfo
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
