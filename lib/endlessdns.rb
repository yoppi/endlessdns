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
require 'endlessdns/share'

module EndlessDNS
  LIB_DIR = File.expand_path(File.dirname(__FILE__))
  HOME = ENV['HOME']
  APP_DIR = HOME + "/.endlessdns"
  CONF_DIR = APP_DIR + '/conf'
  CONF_FILE = CONF_DIR + "/endlessdns.conf"
  LOG_DIR = APP_DIR + "/log"
  LOG_NAME = "endlessdns.log"
  STAT_DIR = APP_DIR + "/stat"
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
                  {"item" => "cache-maintain",
                   "banner" => "cache maintain?",
                   "default" => EndlessDNS::Cache::DEFAULT_MAINTAIN}]
end
