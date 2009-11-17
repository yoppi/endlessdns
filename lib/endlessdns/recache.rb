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

    attr_reader :recache, :recache_types, :recache_method
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

    def invoke(name, type)
      delete_cache(name, type)
      if need_recache?(name, type)
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

    def select_type_class(type)
      case type
      when 'A'
        return Resolv::DNS::Resource::IN::A
      when 'AAAA'
        return Resolv::DNS::Resource::IN::AAAA
      when 'ANY'
        return Resolv::DNS::Resource::IN::ANY
      when 'CNAME'
        return Resolv::DNS::Resource::IN::CNAME
      when 'HINFO'
        return Resolv::DNS::Resource::IN::HINFO
      when 'MINFO'
        return Resolv::DNS::Resource::IN::MINFO
      when 'MX'
        return Resolv::DNS::Resource::IN::MX
      when 'NS'
        return Resolv::DNS::Resource::IN::NS
      when 'PTR'
        return Resolv::DNS::Resource::IN::PTR
      when 'SOA'
        return Resolv::DNS::Resource::IN::SOA
      when 'TXT'
        return Resolv::DNS::Resource::IN::TXT
      when 'WKS'
        return Resolv::DNS::Resource::IN::WKS
      else
        return nil
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
      reset_recache_types
      unless types.class == Array
        log.puts("set_recache_types is faild [#{types}]")
        return
      end
      offtypes = (TYPES - types)
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
