#
# config処理を行う
#
require 'yaml'

module EndlessDNS
  class Config
    class << self
      @instance ||= new
    end

    def initialize
      @store = Hash.new
    end

    def config_setup
      conf = {}

      print "snoop port?: "  
      conf[:port] = $stdin.gets.chomp.to_i
      print "network address?: "

      Dir.mkdir(EndlessDNS::CONF_DIR) unless File.exist? EndlessDNS::CONF_DIR 
      File.open(EndlessDNS::CONF_FILE, 'w') {|f|
        f.puts YAML.dump(conf)
      }
    end

    def load
      conf = YAML.load_file(EndlessDNS::CONF_FILE)
      conf.each do |key, val|
        @store[key] = val
      end
    end
  end
end

def config
  EndlessDNS::Config.instance
end

