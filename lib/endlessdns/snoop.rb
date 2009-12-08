if defined? JRUBY_VERSION
  require '/usr/lib/jvm/java-6-sun/jre/lib/ext/jpcap.jar'
  class PacketHandler
    include Java::jpcap.PacketReceiver

    def receivePacket(pkt)
      packet.enq pkt
    end
  end
else
  require 'pcap'
end

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
        @device = get_device()
      end
    end

    def get_device
      if defined? JRUBY_VERSION
        Java::jpcap.JpcapCaptor.getDeviceList()[0]
      else
        Pcap.lookupdev
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
        log.warn("stop snooping")
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

    def dump(filter, count=-1, snaplen=1518, promisc=false, to_ms=20)
      if defined? JRUBY_VERSION
        @handle = Java::jpcap.JpcapCaptor.openDevice(@device, snaplen, promisc, to_ms)
        @handle.setFilter(filter, true)
        @snoop_th = Thread.new do
          @handle.loopPacket(count, PacketHandler.new)
        end
      else
        @handle = Pcap::Capture.open_live(@device, snaplen, promisc, to_ms)
        @handle.setfilter(filter, true)
        @snoop_th = Thread.new do
          @handle.each_packet(count) do |pkt|
            packet.enq(pkt)
          end
          @handle.close
        end
      end
    end
  end
end

def snoop
  EndlessDNS::Snoop.instance
end
