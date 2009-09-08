require 'net/dns/packet'

module EndlessDNS
  class Statistics
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # {src => {[domain, type] => n, ...}, ...}
      @stats = {}
    end

    def add(src, domain, type)
      if exist? src
      end
    end

    def exist?(src)
    end
  end
end

def statistics
  EndlessDNS::Statistics.instance
end
