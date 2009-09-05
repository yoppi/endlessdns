unless $LOAD_PATH.include? File.dirname(__FILE__)
  $LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'thread'

require 'endlessdns/engine'  # system controller
require 'endlessdns/log'     # system log
require 'endlessdns/statistics' # DNS query statistics
require 'endlessdns/table'   # to recache table
require 'endlessdns/timer'   # TTL timer
require 'endlessdns/spoof'   # packet spoofing
require 'endlessdns/packet'  # packet queue
require 'endlessdns/version' # version of system

module EndlessDNS
end
