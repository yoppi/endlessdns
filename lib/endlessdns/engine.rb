#
# EndlessDNSのコントローラ
#
module EndlessDNS
  class Engine

    class << self
      def invoke(options)
        @options = options
        load_config
        config.add('pid', @options[:pid])

        if @options[:daemonize]
          run_daemonize
        else
          run_in_front
        end
      end

      def run_daemonize
        pid = fork do
          run_in_front
        end
        exit
      end

      def run_in_front
        Thread.abort_on_exception = true
        log_setup()
        stat_setup()
        sharing_setup()
        cgi_setup()
        snoop_start()
        packet_analy()
      end

      def load_config
        unless File.exist? EndlessDNS::CONF_FILE
          config.setup
        end
        config.load
      end

      def log_setup
        log.setup
      end

      def stat_setup
        statistics.setup
      end

      def sharing_setup
        @share_th = Thread.new do
          share.setup
        end
      end

      def cgi_setup
        if @options[:web]
          helper = EndlessDNS::CGIHelper.new
          helper.setup
        end
      end

      def snoop_start
        @snoop = EndlessDNS::Snoop.new
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
