#
# config処理を行う
#
module EndlessDNS
  class Config

    CONF_DIR = "conf"
    CONF_FILE = "endlessdns.conf"

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      @store = Hash.new
      @conf_dir = default_confdir()
      @conf_file = @conf_dir + "/" + CONF_FILE
    end

    def default_confdir
      EndlessDNS::APP_DIR + "/" + CONF_DIR
    end

    def load_config
      unless File.exist? @conf_file
        setup
      end
      load_config_file
    end

    def setup
      conf = interactive()
      Dir.mkdir(@conf_dir) unless File.exist? @conf_dir
      File.open(@conf_file, 'w') {|f|
        f.puts YAML.dump(conf)
      }
    end

    def interactive
      conf = {}
      config_items().each do |item|
        banner = item["banner"]
        banner += "(#{item["default"]})" if item["default"]
        print "#{banner}: "
        input = $stdin.gets.chomp
        input = item["default"] if input.size == 0
        conf[item["item"]] = input
      end
      conf
    end

    def config_items
      [{"item" => "port",
        "banner" => "snoop port?",
        "default" => "53"},
       {"item" => "netaddress",
        "banner" => "network address?"},
       {"item" => "dnsip",
        "banner" => "local dns ip address?"},
       {"item" => "logdir",
        "banner" => "log directory?",
        "default" => log.default_logdir() },
       {"item" => "statdir",
        "banner" => "statistics directory?",
        "default" => statistics.default_statdir() },
       {"item" => "recache-method",
        "banner" => "recache method"}]
    end

    def load_config_file
      conf = YAML.load_file(@conf_file)
      conf.each do |key, val|
        @store[key] = val
      end
      validate
    end

    # NOTE: 設定ファイルが正しいかチェックする
    def validate
    end

    def get(item)
      @store[item]
    end

    def add(item, val)
      @store[item] = val
    end
  end
end

def config
  EndlessDNS::Config.instance
end

