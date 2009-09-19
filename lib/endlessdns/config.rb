#
# config処理を行う
#
require 'yaml'

module EndlessDNS
  class Config

    CONFIG_ITEMS = [{"item" => "port", "banner" => "snoop port?"},
                    {"item" => "netaddress", "banner" => "network address?"},
                    {"item" => "dnsip", "banner" => "local dns ip address?"},
                    {"item" => "logdir", "banner" => "log directory?", "default" => EndlessDNS::LOG_DIR},
                    {"item" => "statdir", "banner" => "statistics directory?", "default" => EndlessDNS::STAT_DIR}]

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
      CONFIG_ITEMS.each do |item|
        banner = item["banner"]
        banner += "(#{item["default"]})" if item["default"]
        print "#{banner}: "
        input = $stdin.gets.chomp
        input = item["default"] if input.size == 0
        conf[item["item"]] = input
      end
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

