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
      @resolver.nameservers = config.get(:localip) # localDNSを探索リストに追加
    end

    def invoke(name, type)
      delete_cache(name, type)
      if need_recache?(name, type)
        puts "recache: #{name}, #{type}"
        ret = @resolver.search(name, type)
      end
    end

    def delete_cache(name, type)
      cache.delete(name, type)
    end

    def need_recache?(name, type)
      # 統計データからfalseかtrueを判断
      true
    end
  end
end

def recache
  EndlessDNS::Recache.instance
end
