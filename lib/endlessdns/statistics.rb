#
# DNSパケットの統計情報を扱う
#
module EndlessDNS
  class Statistics

    REFRESH = 60 * 5 # 5分をデフォルトにする

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # {src => {[name, type] => n}, ...}
      @client_query = {}
      @localdns_query = {}

      # {dst => {[name, type] => n}, ...}
      @outside_response = {}
      @localdns_response = {}

      @client_query_num = 0
      @localdns_query_num = 0
      @localdns_response_num = 0
      @outside_response_num = 0
      @hit = 0

      @stat_dir = config.get("statdir") ? config.get("statdir") : EndlessDNS::STAT_DIR

      @mutex = Mutex.new
    end

    def hit
      @hit += 1
    end

    def add_client_query(src, name, type)
      @mutex.synchronize do
        @client_query[src] ||= Hash.new
        @client_query[src][[name, type]] ||= 0
        @client_query[src][[name, type]] += 1
        @client_query_num += 1
      end
    end

    def add_localdns_query(src, name, type)
      @mutex.synchronize do
        @localdns_query[src] ||= Hash.new
        @localdns_query[src][[name, type]] ||= 0
        @localdns_query[src][[name, type]] += 1
        @localdns_query_num += 1
      end
    end

    def add_localdns_response(dst, name, type)
      @mutex.synchronize do
        @localdns_response[dst] ||= Hash.new
        @localdns_response[dst][[name, type]] ||= 0
        @localdns_response[dst][[name, type]] += 1
        @localdns_response_num += 1
      end
    end

    def add_outside_response(dst, name, type)
      @mutex.synchronize do
        @outside_response[dst] ||= Hash.new
        @outside_response[dst][[name, type]] ||= 0
        @outside_response[dst][[name, type]] += 1
        @outside_response_num += 1
      end
    end

    def setup
      unless File.exist? @stat_dir
        Dir.mkdir @stat_dir
      end
      Thread.new do
        loop do
          sleep refresh()
          Thread.new do # 統計情報を吐くのに時間がかかるとtimerがずれる
            update_statistics
          end
        end
      end
    end

    def refresh
      config.get("refresh") ? config.get("refresh") : REFRESH
    end

    def update_statistics
      now = Time.now
      stat = collect_stat()
      File.open(stat_file_name(now), 'w') do |io|
        # NOTE: Hashなので吐きだされた統計情報は項目の順番がばらばら
        #       項目の順番を決定するか?
        io.puts YAML.dump(stat)
        log.puts("stat: update", "info")
      end
    end

    def stat_file_name(now)
      ret = ""
      ret << @stat_dir + "/"
      ret << sprintf("%04d", now.year)
      ret << sprintf("%02d", now.month)
      ret << sprintf("%02d", now.day)
      ret << sprintf("%02d", now.hour)
      ret << sprintf("%02d", now.min)
      ret << ".stat"
      ret
    end

    def collect_stat
      stat = {}
      stat.merge! client_query_stat()
      stat.merge! cache_stat()
      stat.merge! hit_rate_stat()
      stat
    end

    # NOTE: 最初からこの形で統計情報を集めるか?
    def client_query_stat
      ret = {} 
      client_query = deep_copy(@client_query)
      client_query.each do |src, val|
        ret["num_of_client"] ||= 0
        ret["num_of_client"] += 1
        val.each do |name_type, cnt|
          ret["num_of_query"] ||= {}
          ret["num_of_query"][name_type[1]] ||= 0
          ret["num_of_query"][name_type[1]] += cnt
        end
      end
      ret
    end

    def cache_stat
      ret = {}
      cache_tmp = deep_copy(cache.cache)
      cache_tmp.each do |name_type, val|
        ret["num_of_cache"] ||= {}
        ret["num_of_cache"][name_type[1]] ||= 0
        ret["num_of_cache"][name_type[1]] += val.size
      end
      ncache_ref = deep_copy(cache.negative_cache_ref)
      ncache_ref.each do |name_type, cnt|
        ret["num_of_negative"] ||= {}
        ret["num_of_negative"][name_type[1]] ||= 0
        ret["num_of_negative"][name_type[1]] += cnt
      end
      ret
    end

    def hit_rate_stat
      ret = {}
      hit_rate = (@client_query_num == 0) ? 0 : @hit.fdiv(@client_query_num)
      ret["hit_rate"] = hit_rate 
      ret
    end

    def deep_copy(obj)
      @mutex.synchronize do
        Marshal.load(Marshal.dump(obj))
      end
    end
  end
end

def statistics
  EndlessDNS::Statistics.instance
end
