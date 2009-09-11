require 'net/dns/packet'

module EndlessDNS
  class Statistics

    @@client_query = 0
    @@localdns_query = 0
    @@localdns_response = 0
    @@outside_response = 0

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # {[src, domain, type] => n, ...}
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
