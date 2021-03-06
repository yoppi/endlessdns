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

    attr_reader :cache, :cache_ref
    attr_reader :negative_cache, :negative_cache_ref, :negative_cache_client

    def initialize
      # {name:type => [rdata1, rdata2, ...], ...}
      @cache = {}
      # {name:type => n }
      @cache_ref = {}

      # { name:type, ...}
      @negative_cache = Set.new
      # { name:type => n }
      #@negative_cache_ref = {}
      # {src(client) => { name:type => n } }
      #@negative_cache_client = {}

      # {record => [query, query], ..}
      @record_info = {}

      @mutex = Mutex.new
    end

    # name:typeに対するレコードは複数保持すべきか?
    # CNAMEが複数存在することがある
    #   hoge.example.com. CNAME foo.ns.com.
    #   hoge.example.com. CNAME hoge.ns.com.
    #   foo.ns.com. A ...
    #   hoge.ns.com. A ...
    # tableで管理しているTTLはname:typeに対するTTLなので一つでよい．
    # それにexpireを付ける
    # 上書きしても良いか?
    #   hoge.example.com. CNAME foo.ns.com.
    # がまずキャッシュされる
    # その次に同じname:typeのレコードを処理する場合
    #   hoge.example.com. CNAME fuga.ns.com.
    # すでにhoge.example.com.:CNAMEでキャッシュされているのでaddメソッドが呼ばれることはない．
    def add(name, type, rdata, ttl)
      key = make_key(name, type)
      @mutex.synchronize do
        @cache[key] ||= rdata
      end
    end

    def add_negative(name, type)
      key = make_key(name, type)
      @mutex.synchronize do
        @negative_cache << key
      end
    end

    def add_negative_cache_client(client, name, type)
      key = make_key(name, type)
      @mutex.synchronize do
        @negative_cache_client[client] ||= {}
        @negative_cache_client[client][key] ||= 0
        @negative_cache_client[client][key] += 1
      end
    end

    def add_negative_cache_ref(name, type)
      key = make_key(name, type)
      @mutex.synchronize do
        @negative_cache_ref[key] ||= 0
        @negative_cache_ref[key] += 1
      end
    end

    def add_record_info(name, type, query)
      key = make_key(name, type)
      @mutex.synchronize do
        @record_info[key] ||= Set.new
        @record_info[key] << query
      end
    end

    def record_info(name, type)
      key = make_key(name, type)
      @record_info[key]
    end

    def delete(name, type)
      key = make_key(name, type)
      @mutex.synchronize do
        @cache.delete key
      end
    end

    def make_key(name, type)
      name + ":" + type
    end

    # NOTE: [name, type]のペアが存在すればhit
    # なければnameとCNAMEで検索
    # CNAMEでhitすれば、さらにその正規名とtypeで検索
    # hitしなければ存在しない
    def cached?(name, type)
      key = make_key(name, type)
      if @cache.has_key? key
        return true
      elsif check_cname(name, type, [])
        return true
      elsif check_negative(name, type)
        #add_negative_cache_ref(name, type)
        return true
      else
        return false
      end
    end

    def check_cname(name, type, visited)
      k = name + ":" + "CNAME"
      if @cache.has_key? k
        cname = @cache[k]
        return false if visited.include? cname
        visited << cname
        if @cache.has_key? cname + ":" + type
          return true
        else
          return check_cname(cname, type, visited)
        end
      else
        return false
      end
    end

    def check_negative(name, type)
      @negative_cache.include? name + ":" + type
    end

    def add_cache_ref(name, type)
      key = make_key(name, type)
      @mutex.synchronize do
        @cache_ref[key] ||= 0
        @cache_ref[key] += 1
      end
    end

    def check_cache_ref(name, type)
      @mutex.synchronize do
        @cache_ref[name  + ":" + type]
      end
    end

    def init_cache_ref(name, type)
      key = make_key(name, type)
      @mutex.synchronize do
        @cache_ref[key] = 0 if @cache_ref[key]
      end
    end

    def deep_copy_cache
      deep_copy(@cache)
    end

    def deep_copy(obj)
      @mutex.synchronize do
        Marshal.load(Marshal.dump(obj))
      end
    end
  end
end

def cache
  EndlessDNS::Cache.instance
end
