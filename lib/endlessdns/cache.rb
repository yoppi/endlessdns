#
# レコードをキャッシュ
#
module EndlessDNS
  class Cache
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # {[domain, type] => record, ...}
      @cache = {}
      # {[domain, type] => record, ...}
      @negative_cache = {}
      @hit = 0
    end

    def add(domain, type, ttl)
      key = make_key(domain, type)
      if cached?(key)
        hit()
        return
      end
      @cache[[domain, type]] = record
    end

    def add_negative(domain, type)
      @negative_cache[[domain, type]] 
    end

    def delete(record)
    end

    def make_key(domain, type)
      [domain, type]
    end

    def cached?(key)
      @cache[key]
    end

    def hit
      @hit += 1
    end
  end
end

def cache
  EndlessDNS::Cache.instance
end
