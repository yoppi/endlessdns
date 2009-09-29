unless $LOAD_PATH.include? File.dirname(__FILE__)
  $LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'thread'
require 'observer'
require 'logger'
require 'yaml'
require 'rubygems'

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
require 'endlessdns/recache'

module EndlessDNS
  HOME = ENV['HOME']
  CONF_DIR = HOME + "/.endlessdns"
  CONF_FILE = CONF_DIR + "/config"
  LOG_DIR = CONF_DIR + "/log"
  LOG_NAME = "endlessdns.log"
  LOG_LEVEL = Logger::WARN
  STAT_DIR = CONF_DIR + "/stat"
  CONFIG_ITEMS = [{"item" => "port",
                   "banner" => "snoop port?",
                   "default" => "53"},
                  {"item" => "netaddress",
                   "banner" => "network address?"},
                  {"item" => "dnsip",
                   "banner" => "local dns ip address?"},
                  {"item" => "logdir",
                   "banner" => "log directory?",
                   "default" => EndlessDNS::LOG_DIR},
                  {"item" => "statdir",
                   "banner" => "statistics directory?",
                   "default" => EndlessDNS::STAT_DIR},
                  {"item" => "cache-maintian",
                   "banner" => "cache maintain?"
                   "default" => EndlessDNS::Cache::DEFAULT_MAINTAIN}]
end
