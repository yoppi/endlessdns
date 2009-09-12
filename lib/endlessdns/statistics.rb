#
# DNSパケットの統計情報を扱う
#
module EndlessDNS
  class Statistics

    @@client_query_num = 0
    @@localdns_query_num = 0
    @@localdns_response_num = 0
    @@outside_response_num = 0
    @@hit = 0

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # {src => {[domain, type] => n}, ...}
      @client_query = {}
      @localdns_query = {}
      # {dst => {[domain, type] => n}, ...}
      @outside_response = {}
      @localdins_response = {}
    end

    def hit
      @@hit += 1
    end

    def add_client_query(src, domain, type)
      @client_query[src] ||= Hash.new
      @client_query[src][[domain, type]] ||= 0
      @client_query[src][[domain, type]] += 1
    end

    def add_localdns_query(src, domain, type)
      @localdns_query[src] ||= Hash.new
      @localdns_query[src][[domain, type]] ||= 0
      @localdns_query[src][[domain, type]] += 1
    end

    def add_localdns_response(dst, domain, type)
      @localdns_response[dst] ||= Hash.new
      @localdns_response[dst][[domain, type]] ||= 0
      @localdns_response[dst][[domain, type]] += 1
    end

    def add_outside_response(dst, domain, type)
      @outside_response[dst] ||= Hash.new
      @outside_response[dst][[domain, type]] ||= 0
      @outside_response[dst][[domain, type]] += 1
    end
  end
end

def statistics
  EndlessDNS::Statistics.instance
end
