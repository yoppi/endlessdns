#
# config処理を行う
#
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
      conf = interactive()
      Dir.mkdir(EndlessDNS::CONF_DIR) unless File.exist? EndlessDNS::CONF_DIR
      File.open(EndlessDNS::CONF_FILE, 'w') {|f|
        f.puts YAML.dump(conf)
      }
    end

    def interactive
      conf = {}
      EndlessDNS::CONFIG_ITEMS.each do |item|
        banner = item["banner"]
        banner += "(#{item["default"]})" if item["default"]
        print "#{banner}: "
        input = $stdin.gets.chomp
        input = item["default"] if input.size == 0
        conf[item["item"]] = input
      end
      conf
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

