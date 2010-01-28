unless $LOAD_PATH.include? File.dirname(__FILE__)
  $LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'thread'
require 'observer'
require 'logger'
require 'set'
require 'yaml'
#require 'rubygems'

require 'net/dns/packet'
require 'net/dns/resolver'

require 'endlessdns/config'  # system configlation
require 'endlessdns/analysis' # packet analyzer
require 'endlessdns/cache'   # dns cache
require 'endlessdns/engine'  # system controller
require 'endlessdns/log'     # system log
require 'endlessdns/statistics' # DNS query statistics
require 'endlessdns/table'   # to recache table
require 'endlessdns/timer'   # TTL timer
require 'endlessdns/snoop'   # packet snooping
require 'endlessdns/packet'  # packet queue
require 'endlessdns/version' # version of system
require 'endlessdns/recache' # ReCache
require 'endlessdns/share'   # sharing cache info
require 'endlessdns/cgihelper' # cgi setup
require 'endlessdns/front' # communicate other system
require 'endlessdns/pqueue' # priority queue
require 'endlessdns/dns' # DNS packet
require 'endlessdns/query' # DNS query packet
require 'endlessdns/response' # DNS response packet
require 'endlessdns/lru' # Least Recently Used table

module EndlessDNS
  LIB_DIR = File.expand_path(File.dirname(__FILE__))
  HOME = ENV['HOME']
  APP_DIR = HOME + "/.endlessdns"
end
