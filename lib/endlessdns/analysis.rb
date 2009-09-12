#
# DNSパケットの解析器
#
module EndlessDNS
  class Analysis

    def initialize
    end
  
    def run
      loop do
        pkt = packet.deq
        analy(pkt)
      end
    end

    def analy(pkt)
      begin
        dns = Net::DNS::Packet.parse(pkt.udp_data)
      rescue => e
        # NOTE: log処理
        puts "time: #{pkt.time}\nsrc: #{pkt.ip_src} unknown packet"
        return
      end

      if dns.header.query?
        analy_query(pkt, dns)
      elsif dns.header.response?
        analy_response(pkt, dns)
      end
    end
      
    def analy_query(pkt, dns)
      domain = dns.question.domain
      type   = dns.question.type
      if client_query?(pkt)
        if cached?(domain, type)
          # NOTE: log処理
          statistics.hit()
          puts "cached!"
        end
        statistics.add_client_query(pkt.ip_src, domain, type)
        puts "debug: [#{pkt.time}]client_query"
      elsif localdns_query?(pkt)
        # nop
        statistics.add_localdns_query(pkt.ip_src, domain, type)
        puts "debug: [#{pkt.time}]localdns_query"
      end
    end

    def analy_response(pkt, dns)
      if localdns_response?(pkt)
        if nxdomain?(dns) # negativeキャッシュの処理
          cache.add_negative(pkt.ip_dst, dns.question.domain, dns.question.type)
        else
          (dns.answer + dns.authority + dns.additional).each do |rr|
            cache.refcnt(rr.domain, rr.type)
            statistics.add_localdns_response(pkt.ip_dst, rr.domain, rr.type)
          end
        end
        puts "debug: [#{pkt.time}]localdns_response"
      elsif outside_response?(pkt)
        (dns.answer + dns.authority + dns.additional).each do |rr|
          cache.add(rr.domain, rr.type, rr)
          statistics.add_outside_response(pkt.ip_src, rr.domain, rr.type)
        end
        puts "debug: [#{pkt.time}]outside_response"
      end
    end

    def cached?(domain, type)
      cache.cached?(key)
    end

    def nxdomain?(dns)
      dns.header.rcode.type == "NXDomain"
    end

    def client_query?(pkt)
      pkt.ip_dst == config.get(:localip) 
    end

    def localdns_query?(pkt)
      pkt.ip_src == config.get(:localip)
    end

    def localdns_response?(pkt)
      pkt.ip_src == config.get(:localip)
    end

    def outside_response?(pkt)
      pkt.ip_dst == config.get(:localip) 
    end
  end
end
