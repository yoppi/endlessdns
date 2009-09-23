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

      @mutex = Mutex.new
    end

    def hit
      @@hit += 1
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
      refresh = config.get("refresh") ? config.get("refresh") : REFRESH
      Thread.new do
        loop do
          sleep refresh
          Thread.new do # 統計情報を吐くのに時間がかかるとtimerがずれる
            update_statistics
          end
        end
      end
    end

    def update_statistics
      now = Time.now
      stat = collect_stat()
      File.open(stat_file_name(now), 'w') do |io|
        io.puts YAML.dump(stat)
      end
    end

    def stat_file_name(now)
      stat_dir = config.get("statdir") ? config.get("statdir") : EndlessDNS::STAT_DIR
      stat_file_name = stat_dir + "/#{now.year}#{now.month}#{now.day}#{now.hour}#{now.min}.stat"
    end

    def collect_stat
      stat = {}
      stat.merge client_query_stat()
      stat.merge cache_stat()
      stat.merge hit_rate_stat()
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
        ret["num_of_cache"][name_type[1]] += val[:rdata].size
      end
      negative_cache_tmp = deep_copy(cache.negative_cache)
      negative_cache_tmp.each do |dst, val|
        val.each do |name_type, cnt|
          ret["num_of_negative"] ||= {}
          ret["num_of_negative"][name_type[1]] += cnt
        end
      end
      ret
    end

    def hit_rate_stat
      ret = {}
      ret["hit_rate"] = @hit.fdiv @client_query_num 
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
