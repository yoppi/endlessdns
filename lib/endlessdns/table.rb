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

    def add(name, type, ttl, now)
      @mutex.synchronize do
        expire_time = ttl + now
        if @min_expire_time == nil
          @min_expire_time = expire_time
          # 管理テーブルに追加して、timerをセットする
          add_table(expire_time, name, type)
          set_timer(ttl)
          run_timer
        elsif @min_expire_time > expire_time
          @min_expire_time = expire_time
          if run_timer?
            stop_timer
          end
          set_timer(ttl, [name, type])
          run_timer
          add_table(expire_time, name, type)
        elsif @min_expire_time < expire_time 
          add_table(expire_time, name, type)
        end
      end
    end

    def run_timer
      timer.start
    end

    def run_timer?
      timer.run?
    end

    def stop_timer
      timer.stop
    end

    def set_timer(cnt)
      timer.set(cnt)
    end

    def add_table(expire_time, name, type)
      @table[expire_time] ||= []
      @table[expire_time] << [name, type]
    end

    def update(name, type)
    end
  end
end

def table 
  EndlessDNS::Table.instance
end

