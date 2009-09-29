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
      when "no" # for monitoring and experiments
        false
      when "all"
        true
      when "nonref"
        check_cache_ref(name, type)
      end
    end

    def check_cache_ref(name, type)
      ref = cache.check_cache_ref(name, type)
      if ref == nil
        log.puts("[#{name}, #{type}] is no reference", "warn")
        false
      elsif ref > 1
        cache.init_cache_ref(name, type)
        true
      else
        false
      end
    end

    def init_cache_ref(name, type)
      cache.init_cache_ref(name, type)
    end
  end
end

def recache
  EndlessDNS::Recache.instance
end
