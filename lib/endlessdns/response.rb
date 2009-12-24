module EndlessDNS
  class Response < DNSPacket

    class << self
      def instance
        @instance ||= self.new
      end

      # 全ての場合でLRUが有効ではない
      # 設定ファイルにおいてrecacheするサイズの上限が設定されていた
      # 場合のみとする
      def _new(recache_size)
        if 0 != recache_size || "unlimited" != recache_size
          return LRUResponse.new(recache_size)
        else
          return new
        end
      end
    end

    #attr_reader :localdns_response, :localdns_response_num
    #attr_reader :outside_response, :outside_response_num

    def initialize
      @localdns_response = {}
      @localdns_response_num = 0

      @outside_response = {}
      @outside_response_num = 0

      @mutex = Mutex.new
    end

    def analyze(src, dst, time, dns)
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
        outside_response(src, dns, query, time)
      end
    end

    def localdns_response(dst, dns, query)
      (dns.answer + dns.authority + dns.additional).each do |rr|
        cache.add_cache_ref(rr.name, rr.type)
        cache.add_record_info(rr.name, rr.type, query)
        #response.add_localdns_response(dst, rr.name, rr.type)
      end
    end

    def outside_response(src, dns, query, time)
      (dns.answer + dns.authority + dns.additional).each do |rr|
        next if rr.type.to_s == "OPT" # OPTは疑似レコードなのでスキップ

        cache.add_record_info(rr.name, rr.type, query)
        unless cached?(rr.name, rr.type, time)
          cache.add(rr.name, rr.type, rdata(rr))
          add_table(rr.name, rr.type, rr.ttl)
        end
        #response.add_outside_response(src, rr.name, rr.type)
      end
    end

    def add_table(name, type, ttl)
      table.add(name, type, ttl)
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

    def localdns_response?(src)
      src == @dnsip
    end

    def outside_response?(dst)
      dst == @dnsip
    end

    def add_localdns_response(dst, name, type)
      @mutex.synchronize do
        @localdns_response[dst] ||= {}
        @localdns_response[dst][[name, type]] ||= 0
        @localdns_response[dst][[name, type]] += 1
        @localdns_response_num += 1
      end
    end

    def clear_localdns_response
      @mutex.synchronize do
        @localdns_response.clear
        @localdns_response_num = 0
      end
    end

    def add_outside_response(dst, name, type)
      @mutex.synchronize do
        @outside_response[dst] ||= {}
        @outside_response[dst][[name, type]] ||= 0
        @outside_response[dst][[name, type]] += 1
        @outside_response_num += 1
      end
    end

    def clear_outside_response
      @mutex.synchronize do
        @outside_response.clear
        @outside_response_num = 0
      end
    end
  end

  class LRUResponse < Response
    def initialize(recache_size)
      super()
      @recache_size = recache_size
      @lru = LRU.new(@recache_size)
    end

    def add_table(name, type, ttl)
      # LRUテーブルをチェックしてLRUテーブルに空があるか，それとも
      # LRUテーブルに存在すればそのレコードを再キャッシュの対象とし
      # てTTL管理する
      if check_lru(name, type)
        table.add(name, type, ttl)
      end
    end

    def check_lru(name, type)
      if !@lru.max?
        return true
      elsif @lru.get(name + ":" + type)
        return true
      end
      false
    end

    def localdns_response(dst, dns, query)
      (dns.answer + dns.authority + dns.additional).each do |rr|
        cache.add_cache_ref(rr.name, rr.type)
        cache.add_record_info(rr.name, rr.type, query)
        @lru.put(rr.name + ":" + rr.type, nil)
        #response.add_localdns_response(dst, rr.name, rr.type)
      end
    end
  end
end

def response
  EndlessDNS::Response.instance
end
