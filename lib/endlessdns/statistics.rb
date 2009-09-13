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
      # {src => {[name, type] => n}, ...}
      @client_query = {}
      @localdns_query = {}
      # {dst => {[name, type] => n}, ...}
      @outside_response = {}
      @localdns_response = {}
      @mutex = Mutex.new
    end

    def hit
      @@hit += 1
    end

    def add_client_query(src, name, type)
      @mutex.synchronize do
        @client_query[src] ||= Hash.new
        @client_query[src][[name, type]] ||= 0
        @client_query[src][[name, type]] += 1
      end
    end

    def add_localdns_query(src, name, type)
      @mutex.synchronize do
        @localdns_query[src] ||= Hash.new
        @localdns_query[src][[name, type]] ||= 0
        @localdns_query[src][[name, type]] += 1
      end
    end

    def add_localdns_response(dst, name, type)
      @mutex.synchronize do
        @localdns_response[dst] ||= Hash.new
        @localdns_response[dst][[name, type]] ||= 0
        @localdns_response[dst][[name, type]] += 1
      end
    end

    def add_outside_response(dst, name, type)
      @mutex.synchronize do
        @outside_response[dst] ||= Hash.new
        @outside_response[dst][[name, type]] ||= 0
        @outside_response[dst][[name, type]] += 1
      end
    end
  end
end

def statistics
  EndlessDNS::Statistics.instance
end
