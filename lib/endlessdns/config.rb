#
# config処理を行う
#
require 'yaml'

module EndlessDNS
  class Config
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      @store = Hash.new
    end

    def setup
      conf = {}

      print "snoop port?: "
      conf[:port] = $stdin.gets.chomp.to_i
      print "network address?: "
      conf[:netaddress] = $stdin.gets.chomp

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

    def get(name)
      @store[name]
    end
  end
end

def config
  EndlessDNS::Config.instance
end

