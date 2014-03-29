require 'graphviz'
require 'fileutils'

class MasterMind
  attr_accessor :graph
  attr_accessor :verbose
  attr_accessor :os

  def initialize(verbose, os)
    @verbose = verbose
    @os = os
    puts "#{$nm_ban["msm"]} Let the hackin' begins!" if @verbose
  end
  
  def load_graph(path)
    if File.exists?(path) then
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
    if File.exists?(path) then
      FileUtils.mv(path, "#{path}.#{Time.now}.bak")
    end

    @graph.output( :dot => path )
  rescue => details
    puts "#{$nm_ban["err"]} save_graph failed! #{details}" if @verbose
  end

  def save_png(path)
    @graph.output( :png => "#{path}.png" )
  rescue => details
    puts "#{$nm_ban["err"]} save_graph failed! #{details}" if @verbose
  end

  def parse_os_ver(data)
  end

  def parse_adapter(data)
  end

  def parse_route(data)
  end

  def parse_adapter(data)
  end

  def parse_netstat(data)
    rex = $nm_netstat_regex[@os]
    if !rex then
      puts "#{$nm_ban["err"]} Unkown OS"
      return
    end
    
    g = @graph.add_graph("cluster0", "label" => "#netmap report", "style" => "filled", "color" => "lightgrey")
    for ln in data.lines do
      conn = rex.match(ln)
      if not conn.nil? then
        puts conn[:proto] + " # " + 
              conn[:src] + " : " + conn[:sport] + " <--> " + 
              conn[:dst] + " : " + conn[:dport] + 
              " (" + conn[:type] + ")" if @verbose
                
        a0 = g.add_nodes(conn[:src], "style" => "filled", "color" => "cyan" )
        a1 = g.add_nodes(conn[:dst], "style" => "filled", "color" => "cyan" )
        g.add_edges(a0, a1)
      end
    end
  end
end
