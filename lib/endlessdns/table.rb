module EndlessDNS
  class Table
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      # { expire_time => [key, ...], ...}
      @table = {}
      @min_expire_time = nil
      @mutex = Mutex.new
      timer.add_observer(self)
    end

    def add(name, type, ttl)
      now = Time.now.tv_sec
      expire_time = ttl + now
      if @min_expire_time == nil
        set_min_expire(expire_time)
        add_table(expire_time, name, type)
        set_timer(ttl, expire_time)
        start_timer
      elsif @min_expire_time > expire_time
        set_min_expire(expire_time)
        add_table(expire_time, name, type)
        if run_timer?
          stop_timer
        end
        set_timer(ttl, expire_time)
        start_timer
      elsif @min_expire_time <= expire_time
        add_table(expire_time, name, type)
      end
    end

    def update(expire_time)
      do_recache(expire_time)
      set_next_expire
    end

    def do_recache(expire)
      records = @table[expire] # [[name, type], [name, type], ...]
      delete_table(expire)
      records.each do |record|
        # ここがrecache処理のエントリポイントになる
        # NOTE: Log処理
        puts "update! #{expire}: #{record[0]}, #{record[1]}"
        Thread.new do
          recache.invoke(record[0], record[1])
        end
      end
    end

    def set_next_expire
      Thread.new do
        if @table.size > 0
          # FIXME: ここが遅いしかも大量にttlテーブルは存在するので現実的ではない
          #       memoizeか、B木, red black treeなど、高速に最小値を探索できる
          #       ものを実装する
          #       ruby1.9だとhashに100万個データがあっても0.08secで終了する
          # NOTE: min(expire_time)をテーブルから取得したとき、すでにexpireの時
          #       間、もしくは過ぎていることがある
          #       時間を過ぎていたらただちにrecache処理にうつる
          min = @table.keys.sort[0]
          if past? min
            do_recache(min)
            set_next_expire
          else
            set_min_expire(min)
            set_timer(min - Time.now.tv_sec, min)
            start_timer
          end
        end
      end
    end

    def set_min_expire(min)
      @mutex.synchronize do
        @min_expire_time = min
      end
    end

    def start_timer
      timer.start
    end

    def stop_timer
      timer.stop
    end

    def run_timer?
      timer.run?
    end

    def set_timer(cnt, expire_time)
      timer.set(cnt, expire_time)
    end

    def add_table(expire_time, name, type)
      @mutex.synchronize do
        @table[expire_time] ||= []
        unless @table[expire_time].include? [name, type]
          @table[expire_time] << [name, type]
        end
      end
    end

    def delete_table(expire_time)
      @mutex.synchronize do
        @table.delete(expire_time)
      end
    end

    def past?(expire)
      expire <= Time.now.tv_sec
    end
  end
end

def table
  EndlessDNS::Table.instance
end
