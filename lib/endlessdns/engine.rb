#
# EndlessDNSのコントローラ
#
module EndlessDNS
  class Engine

    class << self
      def invoke(argv)
        load_config()
        #snoop_start()
      end

      def load_config
        unless File.exist? EndlessDNS::CONF_FILE
          config.setup()
        end
        config.load()
      end

      def snoop_start
        @snoop = Snoop.new
        @snoop_th = Thread.new do
        end
      end
    end
  end
end
