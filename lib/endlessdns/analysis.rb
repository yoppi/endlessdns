#
# DNSパケットの解析器
#
require 'net/dns/packet'

module EndlessDNS
  class Analysis
    @@query_n = 0
    @@response_n = 0

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
      if client_query?(pkt)
        key = cache.make_key(dns.question.domain, dns.question.type)
        if cache.cached?(key)
          cache.hit()
          #statistics.add_client_query()
          return
        end
        question = dns.question
        domain = question.domain
        type   = question.type
        statistics.add(src, domain, type)
      elsif localdns_query?(pkt)
        # nop
      end
    end

    def analy_response(pkt, dns)
      if localdns_response?(pkt)
        # nop 
      elsif outside_response?(pkt)
        if nxdomain?(dns) # negativeキャッシュの処理
          domain = dns.question.domain
          type   = dns.question.type
          cache.add_negative(domain, type)
        else
          (dns.answer + dns.authority + dns.additional).each do |rr|
            domain = rr.domain
            type   = rr.type
            cache.add(domain, type, ttl)
          end
        end
      end
    end

    def nxdomain?(dns)
      dns.header.rcode.type == "NXDomain"
    end

    def client_query?(pkt)
      pkt.ip_dst == EndlessDNS::LOCAL_DNS_IP
    end

    def localdns_query?(pkt)
      pkt.ip_src == EndlessDNS::LOCAL_DNS_IP
    end

    def localdns_response?(pkt)
      pkt.ip_src == EndlessDNS::LOCAL_DNS_IP
    end

    def outside_response?(pkt)
      pkt.ip_dst == EndlessDNS::LOCAL_DNS_IP
    end
  end
end
