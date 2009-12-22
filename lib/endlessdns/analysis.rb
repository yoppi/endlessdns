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
        log.error("src: #{src} unknown packet[#{e}]")
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
        log.error("src: #{src} unknown packet[#{e}]")
        return false
      end
      [dns, src, dst, time]
    end
  end

  class Analysis
    def initialize
      @dnsip = config.get('dnsip')
      if defined? JRUBY_VERSION
        @sieve = JrubySieve.new()
      else
        @sieve = CrubySieve.new()
      end
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
        analy_query(src, dst, time, dns)
      elsif dns.header.response?
        analy_response(src, dst, time, dns)
      end
    end

    def analy_query(src, dst, time, dns)
      r = get_query(dns)
      if r
        qname, qtype = r
      else
        log.warn("query has no question")
        return
      end
      if client_query?(dst)
        #log.debug("[#{time}]client_query")
        client_query(src, qname, qtype, time)
      elsif localdns_query?(src)
        #log.debug("[#{time}]localdns_query")
        localdns_query(dst, qname, qtype, time)
      end
    end

    def client_query(src, qname, qtype, time)
      if cached?(qname, qtype)
        query.add_hit_query(src, qtype)
        #log.debug("cached!")
      end
      query.add_client_query(src, qname, qtype, time)
    end

    def localdns_query(dst, qname, qtype, time)
      query.add_localdns_query(dst, qname, qtype, time)
    end

    def analy_response(src, dst, time, dns)
      if nxdomain?(dns) # negativeキャッシュの処理
        dispose_negative(dst, dns)
        return
      end

      r = get_query(dns)
      if r
        qname, qtype = r
      else
        log.warn("response has no question")
        return
      end
      query = qname + ":" + qtype
      if localdns_response?(src)
        #log.debug("[#{time}]localdns_response")
        localdns_response(dst, dns, query)
      elsif outside_response?(dst)
        #log.debug("[#{time}]outside_response")
        outside_response(src, dns, query)
      end
    end

    def localdns_response(dst, dns, query)
        (dns.answer + dns.authority + dns.additional).each do |rr|
          cache.add_cache_ref(rr.name, rr.type)
          cache.add_record_info(rr.name, rr.type, query)
          #response.add_localdns_response(dst, rr.name, rr.type)
        end
    end

    def outside_response(src, dns, query)
        (dns.answer + dns.authority + dns.additional).each do |rr|
          next if rr.type.to_s == "OPT" # OPTは疑似レコードなのでスキップ

          cache.add_record_info(rr.name, rr.type, query)
          unless cached?(rr.name, rr.type)
            cache.add(rr.name, rr.type, rdata(rr))
            add_table(rr.name, rr.type, rr.ttl)
          end
          #response.add_outside_response(src, rr.name, rr.type)
        end
    end

    def dispose_negative(dst, dns)
      if dns.header.qdCount == 1 && dns.header.nsCount == 1
        q = dns.question.first
        #cache.add_negative_cache_client(dst, q.qName, q.qType.to_s)
        cache.add_negative_cache_ref(q.qName, q.qType.to_s)
        cache.add_negative(q.qName, q.qType.to_s)
        log.warn("negative cache[#{dst} send #{q.qName}/#{q.qType.to_s}]")
      else
        log.warn("More than one question or authority parts were received")
      end
    end

    def get_query(dns)
      q = dns.question.first
      unless q
        return nil
      end
      [q.qName, q.qType.to_s]
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
        log.warn("unrecognized type record[#{rr.type}]")
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
