#
# DNS資源レコードをキャッシュ
#
module EndlessDNS
  class Cache
    DEFAULT_MAINTAIN = "all"

    class << self
      def instance
        @instance ||= self.new
      end
    end

    attr_reader :cache, :negative_cache

    def initialize
      # {[name, type] => [rdata1, rdata2, ...], ...}
      @cache = {}
      # {[name, type] => n }
      @cache_ref = {}
      # {dst => {[name, type] =>  n}, ...}
      @negative_cache = {}
      @mutex = Mutex.new
    end

    def add(name, type, rdata)
      @mutex.synchronize do
        key = make_key(name, type)
        @cache[key] ||= []
        unless @cache[key].include? rdata
          @cache[key] << rdata
        end
      end
    end

    def add_negative(dst, name, type)
      @mutex.synchronize do
        key = make_key(name, type)
        @negative_cache[dst] ||= Hash.new
        @negative_cache[dst][key] ||= 0
        @negative_cache[dst][key] += 1
      end
    end

    def delete(name, type)
      @mutex.synchronize do
        key = make_key(name, type)
        if @cache.has_key? key
          @cache.delete key
        end
      end
    end

    def make_key(name, type)
      [name, type]
    end

    # NOTE: [name, type]のペアが存在すればhit
    # なければnameとCNAMEで検索
    # CNAMEでhitすれば、さらにその正規名とtypeで検索
    # hitしなければ存在しない
    def cached?(name, type)
      @mutex.synchronize do
        if @cache.has_key? [name, type]
          return true
        elsif check_cname(name, type)
          return true
        else
          return false
        end
      end
    end

    def check_cname(name, type)
      if @cache.has_key? [name, "CNAME"]
        cnames = @cache[[name, "CNAME"]]
        cnames.each do |cname|
          if @cache.has_key? [cname, type]
            return true
          end
          return check_cname(cname, type)
        end
      else
        return false
      end
    end

    def refcnt(name, type)
      @mutex.synchronize do
        key = make_key(name, type)
        @cache_ref[key] ||= 0
        @cache_ref[key] += 1
      end
    end

    def check_cache_ref(name, type)
      @mutex.synchronize do
        @cache_ref[[name, type]]
      end
    end

    def init_cache_ref(name, type)
      @mutex.synchronize do
        @cache_ref[[name, type]] = 0 if @cache_ref[[name, type]]
      end
    end
  end
end

def cache
  EndlessDNS::Cache.instance
end
