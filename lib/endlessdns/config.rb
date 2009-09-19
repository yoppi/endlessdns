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
      interactive(conf)

      Dir.mkdir(EndlessDNS::CONF_DIR) unless File.exist? EndlessDNS::CONF_DIR
      File.open(EndlessDNS::CONF_FILE, 'w') {|f|
        f.puts YAML.dump(conf)
      }
    end

    def interactive(conf)
      print "snoop port?: "
      conf["port"] = $stdin.gets.chomp.to_i
      print "network address?: "
      conf["netaddress"] = $stdin.gets.chomp
      print "local dns ip address?: "
      conf["localip"] = $stdin.gets.chomp
      print "log directory?: "
      conf["logdir"] = $stdin.gets.chomp
      print "statistics directory?: "
      conf["statdir"] = $stdin.gets.chomp
    end

    def load
      conf = YAML.load_file(EndlessDNS::CONF_FILE)
      conf.each do |key, val|
        @store[key] = val
      end
      validate
    end

    # NOTE: 設定ファイルが正しいかチェックする
    def validate
    end

    def get(name)
      @store[name]
    end
  end
end

def config
  EndlessDNS::Config.instance
end

