require 'pcap'

module EndlessDNS
  class Snoop
    SNOOP_PORT = 53

    class <<  self
      def instance
        @instance ||= self.new
      end
    end

    attr_reader :device

    def initialize(device=nil)
      unless device
        @device = Pcap.lookupdev
      end
    end

    def start
      port = config.get("port") ? config.get("port") : SNOOP_PORT
      dump("udp and port #{port}")
    end

    def stop
      begin
        @snoop_th.kill
        @handle.close
      rescue => e
        log.puts("stop snooping", "warn")
      end
    end

    def setfilter(filter, optimize=true)
      @handle.setfilter(filter, optimize)
    end

    def status
      if @snoop_th.status # 'sleep'か'run'を返す
        return 'start'
      else
        return 'stop' # スレッドが死んでいればfalseかnilを返す
      end
    end

    def set_status(arg)
      return if status() == arg
      if arg == "stop"
        stop
      elsif arg == "start"
        start
      end
    end

    def dump(filter, count=-1, snaplen=1518, promisc=false)
      @handle = Pcap::Capture.open_live(@device, snaplen, promisc)
      @handle.setfilter(filter)
      @snoop_th = Thread.new do
        @handle.each_packet(count) do |pkt|
          packet.enq(pkt)
        end
        @handle.close
      end
    end
  end
end

def snoop
  EndlessDNS::Snoop.instance
end
