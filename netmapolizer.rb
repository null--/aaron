#!/usr/bin/ruby

require 'graphviz'
require 'thor'
require './netmap-defs.rb'

class Netmapolizer < Thor
  attr_reader :grap
  
  def initialize(*args)
    super
    puts "#{$nfo}"
  end
  
  desc "help", "help_banner"
  def help
    super
    
    puts <<-BANNER
Examples:
  1. Create a new diagram from a netstat output file, then generate report in png and pdf formats
    ./netmap.rb file netstat.out --verbose --png --pdf --output test.nmg
    BANNER
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :nsgfile,  :type => :string, :default => false, :alias => "-i", :required => true
      :desc => "verbose mode"
      
  desc "search", "Search something! (e.g. all windows clients connected to 192.168.0.1 on port 22)"
  def search
  end
  
  desc "info", "Print more info about a HOST (some of them are not shown in png or pdf)"
  def info(host)
  end
end

Netmapolizer.start
