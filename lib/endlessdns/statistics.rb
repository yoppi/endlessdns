#
# DNSパケットの統計情報を扱う
#
require 'pstore'

module EndlessDNS
  class Statistics

    INTERVAL = 60 * 5 # 5分をデフォルトにする

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

      # {type => n, ...}
      @client_query_num = {}

      @localdns_query_num = 0
      @localdns_response_num = 0
      @outside_response_num = 0

      # { type => n, ...}
      @hit = {}

      @stat_dir = config.get("statdir") ? config.get("statdir") : EndlessDNS::STAT_DIR
      @stats_interval = config.get("stats-interval") ? config.get("stats-interval") : INTERVAL

      @mutex = Mutex.new
    end

    def hit(type)
      @hit[type] ||= 0
      @hit[type] += 1
    end

    # TODO: client_queryを統計情報を書き出すときにクリアする
    def add_client_query(src, name, type)
      @mutex.synchronize do
        @client_query[src] ||= Hash.new
        @client_query[src][[name, type]] ||= 0
        @client_query[src][[name, type]] += 1
        @client_query_num[type] ||= 0
        @client_query_num[type] += 1
      end
    end

    # TODO: localdns_queryを統計情報を書き出すときに書き出しクリアする
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
          sleep @stats_interval
          Thread.new do # 統計情報を吐くのに時間がかかるとtimerがずれる
            update_statistics
          end
        end
      end
    end

    def interval
      @stats_interval
    end

    def set_interval(interval)
      if interval.to_i >= 60
        @stats_interval = interval.to_i
      end
    end

    def update_statistics
      #now = current_time()
      now = Time.new.tv_sec
      stat = collect_stat()

      # pstoreで各統計情報毎にdumpする
      update_cache(now, stat['num_of_cache'])
      update_negative_cash(now, stat['num_of_negative'])
      update_hit_rate(now, stat['hit_rate'])
      update_query(now, stat['num_of_query'])
    end

    def update_cache(date, cache)
      db = PStore.new(cache_db())
      db.transaction do
        db[date] = cache
      end
    end

    def update_negative_cash(date, negative_cache)
      db = PStore.new(negative_cache_db())
      db.transaction do
        db[date] = negative_cache
      end
    end

    def update_hit_rate(date, hit_rate)
      db = PStore.new(hit_rate_db())
      db.transaction do
        db[date] = hit_rate
      end
    end

    def update_query(date, query)
      db = PStore.new(query_db())
      db.transaction do
        db[date] = query
      end
    end

    def cache_db
      @stat_dir + '/' + 'cache.db'
    end

    def negative_cache_db
      @stat_dir + '/' + 'negative_cache.db'
    end

    def hit_rate_db
      @stat_dir + '/' + 'hit_rate.db'
    end

    def query_db
      @stat_dir + '/' + 'query.db'
    end

    def current_time
      now = Time.now
      ret = ""
      ret << sprintf("%04d", now.year)
      ret << sprintf("%02d", now.month)
      ret << sprintf("%02d", now.day)
      ret << sprintf("%02d", now.hour)
      ret << sprintf("%02d", now.min)
      ret
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
        ret['num_of_client'] ||= 0
        ret['num_of_client'] += 1
        val.each do |name_type, cnt|
          ret['num_of_query'] ||= {}
          ret['num_of_query'][name_type[1]] ||= 0
          ret['num_of_query'][name_type[1]] += cnt
        end
      end
      ret
    end

    def cache_stat
      ret = {}
      cache_tmp = deep_copy(cache.cache)
      cache_tmp.each do |name_type, val|
        ret['num_of_cache'] ||= {}
        ret['num_of_cache'][name_type[1]] ||= 0
        ret['num_of_cache'][name_type[1]] += val.size
      end
      ncache_ref = deep_copy(cache.negative_cache_ref)
      ncache_ref.each do |name_type, cnt|
        ret['num_of_negative'] ||= {}
        ret['num_of_negative'][name_type[1]] ||= 0
        ret['num_of_negative'][name_type[1]] += cnt
      end
      ret
    end

    def hit_rate_stat
      ret = {}
      @hit.each do |type, n|
        hit_rate = (@client_query_num[type] == 0) ? 0 : n.fdiv(@client_query_num[type])
        ret['hit_rate'] ||= {}
        ret['hit_rate'][type] = hit_rate
      end
      ret
    end

    def deep_copy(obj)
      @mutex.synchronize do
        begin
          Marshal.load(Marshal.dump(obj))
        rescue => e
          log.puts(e, "warn")
        end
      end
    end

    def db_name(info)
      case info
      when 'cache'
        cache_db
      when 'negativecache'
        negative_cache_db
      when 'hitrate'
        hit_rate_db
      when 'query'
        query_db
      end
    end
  end
end

def statistics
  EndlessDNS::Statistics.instance
end
