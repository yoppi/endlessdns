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
        if defined? JRUBY_VERSION
          dns = Net::DNS::Packet.parse(pkt.data.to_a.pack('C*'))
        else
          dns = Net::DNS::Packet.parse(pkt.udp_data)
        end
      rescue => e
        log.puts("src: #{pkt.ip_src} unknown packet[#{e}]", "error")
        return
      end

      # FIXME: pktをわたすのではなく、インスタンス変数に使用するパラメータ
      # を格納する
      if dns.header.query?
        analy_query(pkt, dns)
      elsif dns.header.response?
        analy_response(pkt, dns)
      end
    end

    def analy_query(pkt, dns)
      dns.question.each  do |q|
        if client_query?(pkt)
          log.puts("[#{pkt.time}]client_query", "debug")
          client_query(pkt, q.qName, q.qType.to_s)
        elsif localdns_query?(pkt)
          log.puts("[#{pkt.time}]localdns_query", "debug")
          localdns_query(pkt, q.qName, q.qType.to_s)
        end
      end
    end

    def client_query(pkt, name, type)
      if cached?(name, type)
        statistics.hit(type)
        log.puts("cached!", "debug")
      end
      statistics.add_client_query(pkt.ip_src.to_num_s, name, type)
    end

    def localdns_query(pkt, name, type)
      statistics.add_localdns_query(pkt.ip_src.to_num_s, name, type)
    end

    def analy_response(pkt, dns)
      if localdns_response?(pkt)
        log.puts("[#{pkt.time}]localdns_response", "debug")
        localdns_response(pkt, dns)
      elsif outside_response?(pkt)
        log.puts("[#{pkt.time}]outside_response", "debug")
        outside_response(pkt, dns)
      end
    end

    def localdns_response(pkt, dns)
      if nxdomain?(dns) # negativeキャッシュの処理
        dispose_negative(pkt.ip_dst.to_num_s, dns)
      else
        (dns.answer + dns.authority + dns.additional).each do |rr|
          name = root?(rr.name) ? '.' : rr.name
          add_cache_ref(name, rr.type)
          statistics.add_localdns_response(pkt.ip_dst.to_num_s, name, rr.type)
        end
      end
    end

    def outside_response(pkt, dns)
      if nxdomain?(dns)
        dispose_negative(pkt.ip_dst.to_num_s, dns)
      else
        (dns.answer + dns.authority + dns.additional).each do |rr|
          next if rr.type.to_s == "OPT" # OPTは疑似レコードなのでスキップ

          name = root?(rr.name) ? '.' : rr.name # NOTE: namesのdn_expandで対処すべきか?
          unless cached?(name, rr.type)
            add_cache(name, rr.type, rr)
            add_table(name, rr.type, rr.ttl)
          end
          statistics.add_outside_response(pkt.ip_src.to_num_s, name, rr.type)
        end
      end
    end

    def dispose_negative(dst, dns)
      if dns.header.qdCount == 1 && dns.header.nsCount == 1
        q = dns.question.first
        add_negative_cache_client(dst, q.qName, q.qType.to_s)
        add_negative_cache_ref(q.qName, q.qType.to_s)
        add_negative_cache(q.qName, q.qType.to_s)
        log.puts("negative cache[#{pkt.ip_dst.to_num_s} send #{q.qName.to_s}/#{q.qType.to_s}]", "warn")
      else
        log.puts("More than one question or authority parts were received", "warn")
      end
    end

    def add_cache(name, type, rr)
      cache.add(name, type, rdata(rr))
    end

    def add_cache_ref(name, type)
      cache.add_cache_ref(name, type)
    end

    def add_negative_cache(qname, qtype)
      cache.add_negative(qname, qtype)
    end

    def add_negative_cache_client(client, qname, qtype)
      cache.add_negative_cache_client(client, qname, qtype)
    end

    def add_negative_cache_ref(qname, qtype)
      cache.add_negative_cache_ref(qname, qtype)
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
