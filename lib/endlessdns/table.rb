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
        @min_expire_time = expire_time
        # 管理テーブルに追加して、timerをセットする
        add_table(expire_time, name, type)
        set_timer(ttl, expire_time, [[name, type]])
        start_timer
      elsif @min_expire_time > expire_time
        @min_expire_time = expire_time
        if run_timer?
          stop_timer
        end
        set_timer(ttl, expire_time, [[name, type]])
        start_timer
        add_table(expire_time, name, type)
      elsif @min_expire_time <= expire_time 
        add_table(expire_time, name, type)
      end
    end

    def update(expire_time, name, type)
      @mutex.synchronize do
        Thread.new do
          delete_table(expire_time)
          records.each do |record|
            puts "update! #{expire_time}: #{record[0]}, #{record[1]}"      
          end

          if @table.size > 0
            keys = @table.keys
            # NOTE: ここが遅いしかも大量にttlテーブルは存在するので現実的ではない
            # memoizeか、B木, red black treeなど、高速に最小値を探索できるものを実装する
            # ruby1.9だとhashに100万個データがあっても0.08secで終了する
            min = keys.sort[0]
            @min_expire_time = min
            records = @table[min] # [[name, type], [name, type], ...]
            set_timer(min - Time.now.tv_sec, min, records)
            start_timer
          end
        end
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

    def set_timer(cnt, expire_time, records)
      timer.set(cnt, expire_time, records)
    end

    def add_table(expire_time, name, type)
      @mutex.synchronize do
        @table[expire_time] ||= []
        @table[expire_time] << [name, type]
      end
    end

    def delete_table(expire_time)
      @mutex.synchronize do
        @table.delete(expire_time)
      end
    end
  end
end

def table 
  EndlessDNS::Table.instance
end
