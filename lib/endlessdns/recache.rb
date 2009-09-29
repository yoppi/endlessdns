#
# レコードの再cache
#   統計情報からそのexpireされたレコードを再cache(DNSキャッシュサーバに問い合わせる)かどうか
#   を判断する
#
module EndlessDNS
  class Recache
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      @resolver = Net::DNS::Resolver.new
      @resolver.nameservers = config.get("dnsip") # localDNSを探索リストに追加
    end

    def invoke(name, type)
      delete_cache(name, type)
      if need_recache?(name, type)
        log.puts("recache: #{name}, #{type}", "info")
        #puts "recache: #{name}, #{type}"
        ret = @resolver.search(name, type)
      end
    end

    def delete_cache(name, type)
      cache.delete(name, type)
    end

    def need_recache?(name, type)
      maintain = config.get("cache-maintain") ? config.get("cache-maintain") :
                                                EndlessDNS::Cache::DEFAULT_MAINTAIN
      # 統計データからfalseかtrueを判断
      case maintain
      when "all"
        true
      when "nonref"
        cache_check_ref(name, type)
      end
    end

    def cache_check_ref(name, type)
      ref = cache.check_ref(name, type)
      if ref > 1
        true
      else
        false
      end
      init_cache_ref(name, type)
    end
  end
end

def recache
  EndlessDNS::Recache.instance
end
