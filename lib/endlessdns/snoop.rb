require 'pcap'

module EndlessDNS

  attr_reader :device

  class Snoop
    def initialize(device=nil, snaplen=1518, promisc=0)
      unless device
        @device = Pcap.lookupdev
      end
      @handle = Pcap::Capture.open_live(@device, snaplen, promisc)
    end

    def dump(count=-1)
      # NOTE: 途中でdumpのstop、またstratができるようにする
      #       そうすると、何かしらのrdbmsを使わないと、学習データを残せない
      #       汎用的にするために、ActiveRecordを使って、依存しないようにする
      @handle.each_packet(count) do |pkt|
         packet.enq(pkt)
      end
      @handle.close
    end

    def setfilter(filter, optimize=true)
      @handle.setfilter(filter, optimize)
    end
  end
end
