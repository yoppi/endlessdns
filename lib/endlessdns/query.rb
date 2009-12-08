module EndlessDNS
  class Query

    QUERY_INTERVAL = 1000

    attr_reader :query_info, :client_query_num
    attr_reader :localdns_query, :localdns_query_num
    attr_reader :timebase_hit_query, :pktbase_hit_query, :total_hit_query
    attr_reader :total_query_num
    attr_accessor :interval_query_num

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # { 'name:type' => {
      #     'begin_t' => Time, # 初めてこのクエリが出現した日時
      #     'qnum' => Integer, # このクエリが索かれた回数
      #     'qnday' => Integer,# クエリが出現した日数
      #     'qntz' => Set,     # クエリが出現した時間帯
      #     'qntz_total' => Integer # クエリが出現した時間帯の総数
      #                               qndayを使って平均値を計算に使う
      #     'today' => Time    # 今日の日付
      # }}
      @query_info = {}
      @client_query_num = {}
      @interval_query_num = {}

      @localdns_query = {}
      @localdns_query_num = 0

      @timebase_hit_query = {}
      @pktbase_hit_query = {}
      @total_hit_query = {}

      @total_hit_query_num = 0
      @total_query_num = 0

      @mutex = Mutex.new
    end

    def add_client_query(src, name, type, time)
      @mutex.synchronize do
        t = Time.at(time)
        key = name + ":" + type

        # 初回かどうか
        if !@query_info[key]
          o = {}
          o['begin_t'] = t
          o['today'] = t.to_s.split(' ')[0]
          o['qnum'] = 1
          o['qnday'] = 1
          o['qntz'] = Set.new
          o['qntz'] << t.hour
          @query_info[key] = o
        # 変更
        elsif t.to_s.split(' ')[0] == @query_info[key]['today']
          @query_info[key]['qnum'] += 1
          @query_info[key]['qntz'] << t.hour
        # 日付更新
        else
          o = @query_info[key]
          o['today'] = t.to_s.split(' ')[0]
          o['qnum'] += 1
          o['qnday'] += 1
          o['qntz_total'] ||= 0
          o['qntz_total'] += o['qntz'].size
          o['qntz'].clear
        end

        @client_query_num[src] ||= {}
        @client_query_num[src][type] ||= 0
        @client_query_num[src][type] += 1

        @interval_query_num[src] ||= 0
        @interval_query_num[src] += 1

        @total_query_num += 1
      end

      if interval?
        hitrate_stats()
        cache_stats()
        recache_stats()
      end
    end

    def hitrate_stats(src=nil)
      if src
        io = File.open("#{statistics.stat_dir}/hitrate_querybase_total_#{src}.log", "a+")
        if total_hit_query(src)
          total_hit_query(src).each do |type, n|
            if type == "A"
              hitrate = (client_query_num(src)[type] == 0) ? 0 : n.to_f / client_query_num(src)[type]
              io.puts "#{interval_query_num(src)} #{hitrate}"
            end
          end
        end
        io.close
      else
        io = File.open("#{statistics.stat_dir}/hitrate_querybase_total.log", "a+")
        io.puts "#{@total_query_num} #{@total_hit_query_num / @total_query_num.to_f}"
        io.close
      end
    end

    def cache_stats
      io = File.open("#{statistics.stat_dir}/cache_querybase_total.log", "a+")
      total_cache = cache.cache.values.inject(0) {|ret, e| ret += e.size }
      io.puts "#{@total_query_num} #{total_cache}"
      io.close
    end

    def recache_stats
      io = File.open("#{statistics.stat_dir}/recache_querybase_total.log" "a+")
      total_recache = recache.recaches.values.inject(0) {|ret, e| ret += e }
      io.puts "#{@total_query_num} #{total_recache}"
      io.close
    end

    def clear_client_query
      @mutex.synchronize do
        @client_query_num.clear
      end
    end

    def add_localdns_query(src, name, type)
      @mutex.synchronize do
        @localdns_query[src] ||= {}
        @localdns_query[src][[name, type]] ||= 0
        @localdns_query[src][[name, type]] += 1
        @localdns_query_num += 1
      end
    end

    def clear_localdns_query
      @mutex.synchronize do
        @localdns_query.clear
        @localdns_query_num = 0
      end
    end

    def add_hit_query(src, type)
      @mutex.synchronize do
        @total_hit_query[src] ||= {}
        @total_hit_query[src][type] ||= 0
        @total_hit_query[src][type] += 1

        @total_hit_query_num += 1

        #@timebase_hit_query[src] ||= {}
        #@timebase_hit_query[src][type] ||= 0
        #@timebase_hit_query[src][type] += 1

        #@pktbase_hit_query[src] ||= {}
        #@pktbase_hit_query[src][type] ||= 0
        #@pktbase_hit_query[src][type] += 1
      end
    end

    def clear_total_hit_query
      @mutex.synchronize do
        @total_hit_query.clear
      end
    end

    def clear_timebase_hit_query
      @mutex.synchronize do
        @timebase_hit_query.clear
      end
    end

    def clear_pktbase_hit_query
      @mutex.synchronize do
        @pktbase_hit_query.clear
      end
    end

    def interval?(src=nil)
      if src
        if @interval_query_num[src] && @interval_query_num[src] > 0
          return @interval_query_num[src] % QUERY_INTERVAL == 0
        else
          return false
        end
      else
        return @total_query_num % QUERY_INTERVAL == 0
      end
    end

    def query_info(query)
      @query_info[query]
    end

    def total_hit_query(src=nil)
      src ? @total_hit_query[src] : @total_hit_query
    end

    def client_query_num(src=nil)
      src ? @client_query_num[src] : @client_query_num
    end

    def interval_query_num(src=nil)
      src ? @interval_query_num[src] : @interval_query_num
    end
  end
end

def query
  EndlessDNS::Query.instance
end
