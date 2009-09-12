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
      # {[name, type] => {:rr => rr, :ref => n}, ...}
      @cache = Hash.new(0)
      # {dst => {[name, type] =>  n}, ...}
      @negative_cache = Hash.new(0)
    end

    def add(name, type, rr)
      key = make_key(name, type)
      @cache[key] ||= Hash.new
      @cache[key][:rr] = rr
      @cache[key][:ref] ||= 0
      @cache[key][:ref] += 1
    end

    def add_negative(dst, name, type)
      @negative_cache[dst] ||= Hash.new 
      @negative_cache[dst][[name, type]] ||= 0
      @negative_cache[dst][[name, type]] += 0
    end

    def delete(name, type)

    end

    def make_key(name, type)
      [name, type]
    end

    # NOTE: [name, type]のペアが存在すればhit
    # なければnameとCNAMEで検索
    # CNAMEでhitすれば、さらにその正規名とAで検索
    # hitしなければ存在しない
    def cached?(name, type)
      if @cache.has_key? [name, key]
        return true
      elsif @cache.has_key? [name, Net::DNS::CNAME]
        cname = @cache[[name, Net::DNS::CNAME]].cname
        if @cache.has_key? [cname, Net::DNS::A]
          return true
        else
          return false
        end
      else
        return false
      end
    end

    def refcnt(name, type)
      if @cache.has_key? [name, type]
        @cache[[name, type]][:ref] += 1
      end
    end
  end
end

def cache
  EndlessDNS::Cache.instance
end
