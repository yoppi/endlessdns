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
      @stats[[src, domain, type]] ||= 0
      @stats[[src, domain, type]] += 1
    end
  end
end

def statistics
  EndlessDNS::Statistics.instance
end
