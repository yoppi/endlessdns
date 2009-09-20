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
        log.puts("src: #{pkt.ip_src} unknown packet", "error")
        return
      end

      if dns.header.query?
        analy_query(pkt, dns)
      elsif dns.header.response?
        analy_response(pkt, dns)
      end
    end
      
    def analy_query(pkt, dns)
      dns.question.each {|q|
        if client_query?(pkt)
          puts "debug: [#{pkt.time}]client_query"
          client_query(pkt, q.qName, q.qType.to_s)
        elsif localdns_query?(pkt)
          puts "debug: [#{pkt.time}]localdns_query"
          localdns_query(pkt, q.qName, q.qType.to_s)
        end
      }
    end

    def client_query(pkt, name, type)
      if cached?(name, type)
        # NOTE: log処理
        statistics.hit()
        puts "cached!"
      else
        puts "no cached..."
      end
      statistics.add_client_query(pkt.ip_src.to_num_s, name, type)
    end

    def localdns_query(pkt, name, type)
      statistics.add_localdns_query(pkt.ip_src.to_num_s, name, type)
    end

    def analy_response(pkt, dns)
      if localdns_response?(pkt)
        puts "debug: [#{pkt.time}]localdns_response"
        localdns_response(pkt, dns)
      elsif outside_response?(pkt)
        puts "debug: [#{pkt.time}]outside_response"
        outside_response(pkt, dns)
      end
    end

    def localdns_response(pkt, dns)
      if nxdomain?(dns) # negativeキャッシュの処理
        dns.question.each do |q|
          add_negative_cache(pkt.ip_dst.to_num_s, q.qName, q.qType)
        end
      else
        (dns.answer + dns.authority + dns.additional).each do |rr|
          refcnt_cache(rr.name, rr.type)
          statistics.add_localdns_response(pkt.ip_dst.to_num_s, rr.name, rr.type)
        end
      end
    end

    def outside_response(pkt, dns)
      (dns.answer + dns.authority + dns.additional).each do |rr|
        unless cached?(rr.name, rr.type)
          add_cache(rr.name, rr.type, rr)
          add_table(rr.name, rr.type, rr.ttl)
        end
        statistics.add_outside_response(pkt.ip_src.to_num_s, rr.name, rr.type)
      end
    end

    def add_cache(name, type, rr)
      cache.add(name, type, rdata(rr))
    end

    def add_negative_cache(dst, qname, qtype)
      cache.add_negative(dst, qname, qtype) 
    end

    def refcnt_cache(name, type)
      cache.refcnt(name, type)
    end

    def rdata(rr)
      data = []
      case rr.type
      when 'A'
        data << rr.address 
      when 'AAAA'
        data << rr.address
      when 'NS'
        data << rr.nsdname 
      when 'CNAME'
        data << rr.cname
      when 'MX'
        data << rr.preference
        data << rr.exchage
      when 'PTR'
        data << rr.ptr
      when 'TXT'
        data << rr.txt
      when 'SOA'
        data << rr.mname
        data << rr.rname
        data << rr.serial
        data << rr.refresh
        data << rr.retry
        data << rr.expire
        data << rr.minimum
      else 
        # NOTE: ログ処理
        puts "unrecognized packet arrived"
        return rr 
      end
      data
    end

    def add_table(name, type, ttl)
      table.add(name, type, ttl)  
    end

    def cached?(name, type)
      cache.cached?(name, type)
    end

    def nxdomain?(dns)
      dns.header.rCode.type == "NXDomain"
    end

    def client_query?(pkt)
      pkt.ip_dst.to_num_s == config.get("dnsip") 
    end

    def localdns_query?(pkt)
      pkt.ip_src.to_num_s == config.get("dnsip")
    end

    def localdns_response?(pkt)
      pkt.ip_src.to_num_s == config.get("dnsip")
    end

    def outside_response?(pkt)
      pkt.ip_dst.to_num_s == config.get("dnsip") 
    end
  end
end
