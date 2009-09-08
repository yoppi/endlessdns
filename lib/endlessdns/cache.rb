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
    end

    def add(pkt)
    end

    def delete(record)
    end

    def is_cached?(record)
    end
  end
end

def cache
  EndlessDNS::Cache.instance
end
