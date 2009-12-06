#
# DNSパケットの統計情報を扱う
#
require 'pstore'

module EndlessDNS
  class Statistics

    INTERVAL = 60 * 5 # 5分をデフォルトにする
    STAT_DIR = "stat"

    class << self
      def instance
        @instance ||= self.new
      end
    end

    attr_reader :stat_dir

    def initialize
      @stat_dir = config.get("statdir") ? config.get("statdir") : default_statdir()
      @stats_interval = config.get("stats-interval") ? config.get("stats-interval") : INTERVAL

      @mutex = Mutex.new
    end

    def default_statdir
      EndlessDNS::APP_DIR + "/" + STAT_DIR
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
            query.clear_localdns_query
            query.clear_localdns_response
            query.clear_outside_response
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
      now = Time.new.tv_sec
      stat = collect_stat()

      # pstoreで各統計情報毎にdumpする
      update_cache(now, stat['num_of_cache'])
      update_negative_cash(now, stat['num_of_negative'])
      update_hit_rate(now, stat['hit_rate'])
      update_query(now, stat['num_of_query'])
      update_recache()
    end

    def update_cache(date, cache)
      db = PStore.new(cache_db())
      begin
        db.transaction do
          db[date] = cache
        end
      rescue => e
        log.puts(e, "warn")
      end
    end

    def update_negative_cash(date, negative_cache)
      db = PStore.new(negative_cache_db())
      begin
        db.transaction do
          db[date] = negative_cache
        end
      rescue => e
        log.puts(e, "warn")
      end
    end

    def update_hit_rate(date, hit_rate)
      db = PStore.new(hit_rate_db())
      begin
        db.transaction do
          db[date] = hit_rate
        end
      rescue => e
        log.puts(e, "warn")
      end
    end

    def update_query(date, query)
      db = PStore.new(query_db())
      begin
        db.transaction do
          db[date] = query
        end
      rescue => e
        log.puts(e, "warn")
      end
    end

    def update_recache
      db = PStore.new(recache_db())
      begin
        db.transaction do
          recache.recaches.each do |r, n|
            db[r] ||= n
            db[r] += n
          end
        end
      rescue => e
        log.puts(e, "warn")
      end
      recache.clear_recache
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

    def recache_db
      @stat_dir + '/' + 'recache.db'
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
      client_query = query.client_query
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
      cache_tmp = cache.cache
      cache_tmp.each do |name_type, val|
        ret['num_of_cache'] ||= {}
        ret['num_of_cache'][name_type[1]] ||= 0
        ret['num_of_cache'][name_type[1]] += val.size
      end
      ncache_ref = cache.negative_cache_ref
      ncache_ref.each do |name_type, cnt|
        ret['num_of_negative'] ||= {}
        ret['num_of_negative'][name_type[1]] ||= 0
        ret['num_of_negative'][name_type[1]] += cnt
      end
      ret
    end

    def hit_rate_stat
      ret = {}
      total_h = query.total_hit_query.values.inject({}) {|ret, e| ret.merge e }
      total_q = query.client_query_num.values.inject({}) {|ret, e| ret.merge e }
      total_h.each do |type, n|
        hitrate = (total_q[type] == 0) ? 0 : n.to_f / total_q[type]
        ret['hit_rate'] ||= {}
        ret['hit_rate'][type] = hitrate
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
      when 'recache'
        recache_db
      end
    end
  end
end

def statistics
  EndlessDNS::Statistics.instance
end
