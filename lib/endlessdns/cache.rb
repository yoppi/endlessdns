#
# DNS資源レコードをキャッシュ
#
module EndlessDNS
  class Cache
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # {[name, type] => {:rdata => [rdata1, rdata2, ...] :ref => n}, ...}
      @cache = {}
      # {dst => {[name, type] =>  n}, ...}
      @negative_cache = {}
      @mutex = Mutex.new
    end

    def add(name, type, rdata)
      @mutex.synchronize do
        key = make_key(name, type)
        @cache[key] ||= Hash.new
        @cache[key][:rdata] ||= []
        unless @cache[key][:rdata].include? rdata
          @cache[key][:rdata] << rdata
        end
        @cache[key][:ref] ||= 0
        @cache[key][:ref] += 1
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
    # CNAMEでhitすれば、さらにその正規名とAで検索
    # hitしなければ存在しない
    def cached?(name, type)
      @mutex.synchronize do
        if @cache.has_key? [name, type]
          return true
        elsif @cache.has_key? [name, "CNAME"]
          cname = @cache[[name, "CNAME"]][:rdata][0]
          if @cache.has_key? [cname, "A"]
            return true
          else
            return false
          end
        else
          return false
        end
      end
    end

    def refcnt(name, type)
      @mutex.synchronize do
        key = make_key(name, type)
        if @cache.has_key? key
          @cache[key][:ref] += 1
        end
      end
    end
  end
end

def cache
  EndlessDNS::Cache.instance
end
