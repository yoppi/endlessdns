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
      dns = Net::DNS::Packet.parse(pkt.udp_data)
      timestamp = pkt.time
      if dns.header.query?
        src = pkt.ip_src
        question = dns.question
        domain = question.domain
        type   = question.type
        statistics.add(src, domain, type)
      elsif dns.header.response?
        if nxdomain?(dns)
          domain = dns.question.domain 
          type   = dns.question.type
          cache.add(domain, type)
        else
        (dns.answer + dns.authority + dns.additional).each do |rr|
          domain = rr.domain
          type   = rr.type
          cache.add(domain, type)
        end
      end
    end

    def nxdomain?(dns)
      dns.header.rcode.type == "NXDomain"
    end
  end
end
