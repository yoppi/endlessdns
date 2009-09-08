module EndlessDNS
  class Packet
    class << self
      def instance
        @instance ||= new
      end
    end

    def initialize
      @queue = Queue.new
    end

    def deq
      @queue.deq
    end

    def enq(obj)
      @queue.enq(obj)
    end
  end
end

def packet
  EndlessDNS::Packet.instance
end
