#
# EndlessDNSのコントローラ
#
module EndlessDNS
  class Engine

    class << self
      def invoke(argv)
        Thread.abort_on_exception = true
        load_config()
        log_setup()
        stat_setup()
        snoop_start()
        #loop do
        #  sleep 1
        #  puts packet.size
        #end
        packet_analy()
      end

      def load_config
        unless File.exist? EndlessDNS::CONF_FILE
          config.setup()
        end
        config.load()
      end

      def log_setup
        log.setup
      end

      def stat_setup
        stat.setup
      end

      def snoop_start
        @snoop = Snoop.new
        @snoop.setfilter("udp and port #{config.get("port")}")
        @snoop_th = Thread.new do
          @snoop.dump
        end
      end

      def packet_analy
        # NOTE: パケットを処理するのが遅ければthread数を増やす
        @analy_th = Thread.new do
          @analyzer = Analysis.new
          @analyzer.run
        end
        @analy_th.join
      end
    end
  end
end
