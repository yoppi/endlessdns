#
# DNSパケットの解析器
#
module EndlessDNS
  class Analysis

    def initialize
      @dnsip = config.get('dnsip')
    end

    def run
      loop do
        pkt = packet.deq
        analy(pkt)
      end
    end

    def analy(pkt)
      begin
        if defined? JRUBY_VERSION
          dns = Net::DNS::Packet.parse(pkt.data.to_a.pack('C*'))
          src = pkt.src_ip.to_s[1..-1]
          dst = pkt.dst_ip.to_s[1..-1]
          time = pkt.sec + pkt.usec/100000.0
        else
          dns = Net::DNS::Packet.parse(pkt.udp_data)
          src = pkt.ip_src.to_num_s
          dst = pkt.ip_dst.to_num_s
          time = pkt.time
        end
      rescue => e
        log.puts("src: #{src} unknown packet[#{e}]", "error")
        return
      end

      if dns.header.query?
        analy_query(src, dst, time, dns)
      elsif dns.header.response?
        analy_response(src, dst, time, dns)
      end
    end

    def analy_query(src, dst, time, dns)
      dns.question.each  do |q|
        if client_query?(dst)
          #log.puts("[#{time}]client_query", "debug")
          client_query(src, q.qName, q.qType.to_s)
        elsif localdns_query?(src)
          #log.puts("[#{time}]localdns_query", "debug")
          localdns_query(src, q.qName, q.qType.to_s)
        end
      end
    end

    def client_query(src, name, type)
      if cached?(name, type)
        statistics.add_hit_query(src, type)
        #log.puts("cached!", "debug")
      end
      statistics.add_client_query(src, name, type)
    end

    def localdns_query(src, name, type)
      statistics.add_localdns_query(src, name, type)
    end

    def analy_response(src, dst, time, dns)
      if localdns_response?(src)
        #log.puts("[#{time}]localdns_response", "debug")
        localdns_response(dst, dns)
      elsif outside_response?(dst)
        #log.puts("[#{time}]outside_response", "debug")
        outside_response(src, dst, dns)
      end
    end

    def localdns_response(dst, dns)
      if nxdomain?(dns) # negativeキャッシュの処理
        dispose_negative(dst, dns)
      else
        (dns.answer + dns.authority + dns.additional).each do |rr|
          name = root?(rr.name) ? '.' : rr.name
          cache.add_cache_ref(name, rr.type)
          statistics.add_localdns_response(dst, name, rr.type)
        end
      end
    end

    def outside_response(src, dst, dns)
      if nxdomain?(dns)
        dispose_negative(dst, dns)
      else
        (dns.answer + dns.authority + dns.additional).each do |rr|
          next if rr.type.to_s == "OPT" # OPTは疑似レコードなのでスキップ

          name = root?(rr.name) ? '.' : rr.name # NOTE: namesのdn_expandで対処すべきか?
          unless cached?(name, rr.type)
            cache.add(name, rr.type, rdata(rr))
            add_table(name, rr.type, rr.ttl)
          end
          statistics.add_outside_response(src, name, rr.type)
        end
      end
    end

    def dispose_negative(dst, dns)
      if dns.header.qdCount == 1 && dns.header.nsCount == 1
        q = dns.question.first
        cache.add_negative_cache_client(dst, q.qName, q.qType.to_s)
        cache.add_negative_cache_ref(q.qName, q.qType.to_s)
        cache.add_negative(q.qName, q.qType.to_s)
        log.puts("negative cache[#{dst} send #{q.qName}/#{q.qType.to_s}]", "warn")
      else
        log.puts("More than one question or authority parts were received", "warn")
      end
    end

    def rdata(rr)
      case rr.type.to_s
      when 'A'
        data = rr.address
      when 'AAAA'
        data = rr.address
      when 'NS'
        data = rr.nsdname
      when 'CNAME'
        data = rr.cname
      when 'MX'
        data = []
        data << rr.preference
        data << rr.exchage
      when 'PTR'
        data = rr.ptr
      when 'TXT'
        data = rr.txt
      when 'SOA'
        data = []
        data << rr.mname
        data << rr.rname
        data << rr.serial
        data << rr.refresh
        data << rr.retry
        data << rr.expire
        data << rr.minimum
      else
        log.puts("unrecognized type record[#{rr.type}]", "warn")
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

    def root?(name)
      name == ''
    end

    def client_query?(dst)
      dst == @dnsip
    end

    def localdns_query?(src)
      src == @dnsip
    end

    def localdns_response?(src)
      src == @dnsip
    end

    def outside_response?(dst)
      dst == @dnsip
    end
  end
end
