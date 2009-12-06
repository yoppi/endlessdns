module EndlessDNS
  class Response

    class << self
      def instance
        @instance ||= self.new
      end
    end

    attr_reader :localdns_response, :localdns_response_num
    attr_reader :outside_response, :outside_response_num

    def initialize
      @localdns_response = {}
      @localdns_response_num = 0

      @outside_response = {}
      @outside_response_num = 0

      @mutex = Mutex.new
    end

    def add_localdns_response(dst, name, type)
      @mutex.synchronize do
        @localdns_response[dst] ||= {}
        @localdns_response[dst][[name, type]] ||= 0
        @localdns_response[dst][[name, type]] += 1
        @localdns_response_num += 1
      end
    end

    def clear_localdns_response
      @mutex.synchronize do
        @localdns_response.clear
        @localdns_response_num = 0
      end
    end

    def add_outside_response(dst, name, type)
      @mutex.synchronize do
        @outside_response[dst] ||= {}
        @outside_response[dst][[name, type]] ||= 0
        @outside_response[dst][[name, type]] += 1
        @outside_response_num += 1
      end
    end

    def clear_outside_response
      @mutex.synchronize do
        @outside_response.clear
        @outside_response_num = 0
      end
    end
  end
end

def response
  EndlessDNS::Response.instance
end
