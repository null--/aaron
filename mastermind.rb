require 'graphviz'

class MasterMind
  attr_accessor :graph
  attr_accessor :verbose

  def initialize(verbose)
    @verbose = verbose
    puts "#{$nm_ban[:msm]} Let the hackin' begins!" if @verbose
  end
  
  def load_graph(path)
    if File.Exists?(path) then
      @graph = GraphViz.parse( path )
    else
      @graph = GraphViz.new("netmap")
    end
  rescue details
    puts "load_graph failed! #{details}" if @verbose
  end

  def save_graph(path, update, backup)
  end

  def save_png(path)
  end

  def parse_os_ver(data)
  end

  def parse_adapter(data)
  end

  def parse_route(data)
  end

  def parse_netstat(data)
  end
end
