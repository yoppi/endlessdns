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
      # {[domain, type] => {:rr => rr, :ref => n}, ...}
      @cache = Hash.new(0)
      # {dst => {[domain, type] =>  n}, ...}
      @negative_cache = Hash.new(0)
    end

    def add(domain, type, rr)
      key = make_key(domain, type)
      @cache[key] ||= Hash.new
      @cache[key][:rr] = rr
      @cache[key][:ref] ||= 0
      @cache[key][:ref] += 1
    end

    def add_negative(dst, domain, type)
      @negative_cache[dst] ||= Hash.new 
      @negative_cache[dst][[domain, type]] ||= 0
      @negative_cache[dst][[domain, type]] += 0
    end

    def delete(domain, type)

    end

    def make_key(domain, type)
      [domain, type]
    end

    # NOTE: [domain, type]のペアが存在すればhit
    # なければdomainとCNAMEで検索
    # CNAMEでhitすれば、さらにその正規名とAで検索
    # hitしなければ存在しない
    def cached?(domain, type)
      if @cache.has_key? [domain, key]
        return true
      elsif @cache.has_key? [domain, Net::DNS::CNAME]
        cname = @cache[[domain, Net::DNS::CNAME]].cname
        if @cache.has_key? [cname, Net::DNS::A]
          return true
        else
          return false
        end
      else
        return false
      end
    end

    def refcnt(domain, type)
      if @cache.has_key? [domain, type]
        @cache[[domain, type]][:ref] += 1
      end
    end
  end
end

def cache
  EndlessDNS::Cache.instance
end
