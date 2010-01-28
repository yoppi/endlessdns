#
# DNSパケットの解析器
#
module EndlessDNS
  class JrubySieve
    def initialize
    end

    def analy(pkt)
      begin
        src = pkt.src_ip.to_s[1..-1]
        dst = pkt.dst_ip.to_s[1..-1]
        time = pkt.sec + pkt.usec/100000.0
        dns = Net::DNS::Packet.parse(pkt.data.to_a.pack('C*'))
      rescue => e
        log.error("#{src} send unknown packet[#{e}]")
        return false
      rescue SystemStackError
        log.fatal("#{src} send malicious packet!")
        return false
      end
      [dns, src, dst, time]
    end
  end

  class CrubySieve
    def initialize
    end

    def analy(pkt)
      begin
        src = pkt.ip_src.to_num_s
        dst = pkt.ip_dst.to_num_s
        time = pkt.time
        dns = Net::DNS::Packet.parse(pkt.udp_data)
      rescue => e
        log.error("#{src} unknown packet[#{e}]")
        return false
      rescue SystemStackError
        log.error("#{src} was malicious packet sending!")
        return false
      end
      [dns, src, dst, time]
    end
  end

  class Analysis
    def initialize
      if defined? JRUBY_VERSION
        @sieve = JrubySieve.new()
      else
        @sieve = CrubySieve.new()
      end
      recache_size = default_recache_size()
      @response = Response._new(recache_size)
      @query = Query.new()
    end

    def default_recache_size
      config.get('recache-size') ? config.get('recache-size') : 0
    end

    def run
      loop do
        pkt = packet.deq
        do_analy(pkt)
      end
    end

    def do_analy(pkt)
      ret = @sieve.analy(pkt)
      if ret
        dns, src, dst, time = ret
      else
        return
      end

      if dns.header.query?
        #analy_query(src, dst, time, dns)
        @query.analyze(src, dst, time, dns)
      elsif dns.header.response?
        #analy_response(src, dst, time, dns)
        @response.analyze(src, dst, time, dns)
      end
    end
  end
end
