#!/usr/bin/env ruby

require 'thor'
require './aaron-defs.rb'
require './mastermind.rb'

class Aaronizer < Thor
  attr_reader :master
  
  def initialize(*args)
    super
    puts "#{$nfo}"
    
    @master = MasterMind.new(options[:verbose])
    @master.load_graph(options[:nmgfile], true)
  rescue
    help(nil)
  end
  
  desc "help [command]", "Print more information about a command (task)"
  def help(command = nil)
    super(command)
    
    if command.nil? then
      puts <<-BANNER
Examples:
  1. Print all windows clients connected to 192.168.0.1 on port 22
    ./aaronizer.rb search --dst 192.168.0.1 --dst_port 22 --src_os win
      BANNER
    end
  end
  
  class_option :verbose,  :type => :boolean, :default => false, :alias => "-v",
      :desc => "verbose mode"
  class_option :nmgfile,  :type => :string, :default => 'test.nmg', :alias => "-i", :required => true,
      :desc => "An existing #{$aa_ext}"

  desc "search", "Search something! (e.g. all windows clients connected to 192.168.0.1 on port 22)"
  method_option :src_os,      :type => :string, :alias => "-so",  :banner => "SRC_OS",      :desc => "source os filter"
  method_option :dst_os,      :type => :string, :alias => "-do",  :banner => "DST_OS",      :desc => "destination os filter"
  method_option :src_port,    :type => :string, :alias => "-sp",  :banner => "SRC_PORT",    :desc => "source port filter"
  method_option :dst_port,    :type => :string, :alias => "-dp",  :banner => "DST_PORT",    :desc => "destination port filter"
  method_option :src,         :type => :string, :alias => "-s",   :banner => "SRC_ADDRESS", :desc => "source filter"
  method_option :dst,         :type => :string, :alias => "-d",   :banner => "DST_ADDRESS", :desc => "destination filter"
  method_option :text,        :type => :string, :alias => "-t",   :banner => "TEXT",        :desc => "text filter"
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

Aaronizer.start
