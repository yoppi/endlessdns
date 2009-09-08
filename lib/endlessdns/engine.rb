module EndlessDNS
  class Engine

    class << self
      def invoke(argv)
        load_config()
        #snoop_start()
      end

      def snoop_start
        @snoop = Spoof.new
        @snoop_th = Thread.new do
        end
      end
    end
  end
end
