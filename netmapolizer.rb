#!/usr/bin/ruby

require 'thor'
require './netmap-defs.rb'
require './mastermind.rb'

class Netmapolizer < Thor
  attr_reader :master
  
  def initialize(*args)
    super
    puts "#{$nfo}"
    
    @master = MasterMind.new(options[:verbose])
    @master.load_graph(options[:nmgfile], true)
  end
  
  desc "help [command]", "help_banner"
  def help(command)
    super(command)
    
    puts <<-BANNER
Examples:
  1. Print all windows clients connected to 192.168.0.1 on port 22
    ./netmapolizer.rb search --dst 192.168.0.1 --dst-port 22 --src-os win
    BANNER
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :nmgfile,  :type => :string, :default => 'test.nmg', :alias => "-i", :required => true,
      :desc => "An existing #{$nm_ext}"

  desc "search", "Search something! (e.g. all windows clients connected to 192.168.0.1 on port 22)"
  def search
  end
  
  desc "show", "Print more info about a HOST (some of them are not shown in png or pdf)"
  method_option :info,        :type => :string, :alias => "-i", :banner => "HOST", :desc => "Show all information about a host"
  method_option :hosts,       :type => :boolean, :default => false, :alias => "-a", :desc => "Show all hosts"
  def show
    if options[:hosts] then
      @master.print_hosts
    elsif not options[:info].nil? then
      @master.print_info options[:info]
    end
  end
  
  desc "edit", "Edit info of a HOST"
  def edit(host)
  end
end

Netmapolizer.start
