#
# レコードの再キャッシュ
#   o 統計情報からそのexpireされたレコードを再cache(DNSキャッシュサーバに問い合わせる)かどうか
#   を判断する
#   o TYPE別に再キャッシュするかどうか判断
#
module EndlessDNS
  class Recache

    # 再キャッシュするタイプ
    TYPES = [
      'A',
      'AAAA',
      'SOA',
      'NS',
      'PTR',
      'CNAME',
      'MX'
    ]

    METHODS = [
      'no',
      'all',
      'ref'
    ]

    class << self
      def instance
        @instance ||= self.new
      end
    end

    attr_reader :recache_types, :recache_method

    def initialize
      @resolver = Net::DNS::Resolver.new
      @resolver.nameservers = config.get("dnsip") # localDNSを探索リストに追加
      @recache_method = default_method()
      @recache_types = default_types()
    end

    def invoke(name, type)
      delete_cache(name, type)
      if need_recache?(name, type)
        log.puts("recache: #{name}, #{type}", "info")
        #puts "recache: #{name}, #{type}"
        begin
          ret = @resolver.search(name, type)
        rescue => e
          log.puts("#{e}", "warn")
        end
      end
    end

    def delete_cache(name, type)
      cache.delete(name, type)
    end

    def need_recache?(name, type)
      # typeの判断
      if @recache_types[type]
        # 再キャッシュ方法
        case @recache_method
        when "no" # for monitoring and experiments
          return false
        when "all"
          return true
        when "ref"
          return check_cache_ref(name, type)
        end
      end
      false
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

    def default_types
      ret = {}
      TYPES.each do |type|
        ret[type] = true
      end
      ret
    end

    def default_method
      config.get("recache-method") ? config.get("recache-method") : 'all'
    end

    def set_recache_types(types)
      unless types.class == Array
        log.puts("set_recache_types is faild [#{types}]")
        return
      end
      offtypes = (TYPES - types)
      offtypes.each do |type|
        @recache_types[type] = false
      end
    end

    def set_recache_method(method)
      @recache_method = method
    end
  end
end

def recache
  EndlessDNS::Recache.instance
end
