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
  1. Print all windows clients connected to 192.168.0.1 on port 22
    ./netmapolizer.rb search --dst 192.168.0.1 --dst-port 22 --src-os win
    BANNER
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :nsgfile,  :type => :string, :default => false, :alias => "-i", :required => true,
      :desc => "verbose mode"
      
  desc "search", "Search something! (e.g. all windows clients connected to 192.168.0.1 on port 22)"
  def search
  end
  
  desc "info", "Print more info about a HOST (some of them are not shown in png or pdf)"
  def info(host)
  end
end

Netmapolizer.start
