require 'resolv'
#
# レコードの再キャッシュ
#   o 統計情報からそのexpireされたレコードを再cache(DNSキャッシュサーバに問い合わせる)かどうか
#   を判断する
#   o TYPE別に再キャッシュするかどうか判断
#
module EndlessDNS
  class Recache

    # 再キャッシュするタイプ
    TYPES = {
      'A' => Resolv::DNS::Resource::IN::A,
      'AAAA' => Resolv::DNS::Resource::IN::AAAA,
      'ANY' => Resolv::DNS::Resource::IN::ANY,
      'CNAME' => Resolv::DNS::Resource::IN::CNAME,
      'HINFO' => Resolv::DNS::Resource::IN::HINFO,
      'MINFO' => Resolv::DNS::Resource::IN::MINFO,
      'MX' => Resolv::DNS::Resource::IN::MX,
      'NS' => Resolv::DNS::Resource::IN::NS,
      'PTR' => Resolv::DNS::Resource::IN::PTR,
      'SOA' => Resolv::DNS::Resource::IN::SOA,
      'TXT' => Resolv::DNS::Resource::IN::TXT,
      'WKS' => Resolv::DNS::Resource::IN::WKS
    }

    METHODS = [
      'no',
      'all',
      'ref',
      'prob'
    ]

    class << self
      def instance
        @instance ||= self.new
      end
    end

    attr_reader :recaches, :recache_types, :recache_method
    attr_accessor :top_view

    def initialize
      @resolver = Resolv::DNS.new(:nameserver => config.get('dnsip'),
                                  :search => nil,
                                  :ndots => 1)
      @recache_method = default_method()
      @recache_types = default_types()
      # {[name, type] => n, ...}
      @recaches = {}
      @top_view = 20

      @mutex = Mutex.new
    end

    def invoke(name, type, query)
      delete_cache(name, type)
      if need_recache?(name, type, query)
        type_class = select_type_class(type)
        begin
          @resolver.getresource(name, type_class)
        rescue => e
          log.puts("#{e}", "warn")
        end
        add_recache(name, type)
      end
    end

    def add_recache(name, type)
      @mutex.synchronize do
        @recaches[[name, type]] ||= 0
        @recaches[[name, type]] += 1
      end
    end

    def clear_recache
      @mutex.synchronize do
        @recaches.clear
      end
    end

    def delete_cache(name, type)
      cache.delete(name, type)
    end

    def need_recache?(name, type, query)
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
        when "prob"
          return check_query_prob(name, type, query)
        end
      end
      false
    end

    def select_type_class(type)
      TYPES[type]
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

    def check_query_prob(name, type, query)
      return true
    end

    def default_types
      ret = {}
      TYPES.keys.each do |type|
        ret[type] = true
      end
      ret
    end

    def default_method
      config.get("recache-method") ? config.get("recache-method") : 'all'
    end

    def set_recache_types(types)
      reset_recache_types
      unless types.class == Array
        log.puts("set_recache_types is faild [#{types}]")
        return
      end
      offtypes = (TYPES.keys - types)
      offtypes.each do |type|
        @recache_types[type] = false
      end
    end

    def reset_recache_types
      @recache_types.each do |type, _|
        @recache_types[type] = true
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
