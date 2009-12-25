#
# queryとresposeの親クラス
#
module EndlessDNS
  class DNSPacket
    def initialize
      @dnsip = config.get('dnsip')
    end

    def get_query(dns)
      q = dns.question.first
      unless q
        return nil
      end
      [q.qName, q.qType.to_s]
    end

    def cached?(name, type, time)
      cache.cached?(name, type, time.tv_sec)
    end
  end
end
