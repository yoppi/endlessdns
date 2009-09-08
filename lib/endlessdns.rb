unless $LOAD_PATH.include? File.dirname(__FILE__)
  $LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'thread'
require 'rubygems'

require 'endlessdns/config'  # system configlation
require 'endlessdns/engine'  # system controller
require 'endlessdns/log'     # system log
require 'endlessdns/statistics' # DNS query statistics
require 'endlessdns/table'   # to recache table
require 'endlessdns/timer'   # TTL timer
require 'endlessdns/snoop'   # packet snooping
require 'endlessdns/packet'  # packet queue
require 'endlessdns/version' # version of system

module EndlessDNS
  HOME = ENV['HOME']
  CONF_DIR = HOME + "/.endlessdns"
  CONF_FILE = CONF_DIR + "/config"
end
