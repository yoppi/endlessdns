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
      @ttl_table = PQueue.new(proc {|x, y| x < y})
      @min_expire_time = nil

      @mutex = Mutex.new

      timer.add_observer(self)
    end

    def add(name, type, ttl)
      now = Time.now.tv_sec
      expire_time = ttl + now
      if @min_expire_time == nil or @min_expire_time > expire_time
        set_min_expire(expire_time)
        add_table(expire_time, name, type)
        add_ttl(expire_time)
        if run_timer?
          stop_timer
        end
        set_timer(ttl, expire_time)
        start_timer
      elsif @min_expire_time <= expire_time
        add_table(expire_time, name, type)
        add_ttl(expire_time) if @min_expire_time != expire_time
      end
    end

    def update(expire_time)
      do_recache(expire_time)
      set_next_expire
    end

    def do_recache(expire)
      records = @table[expire] # [[name, type], [name, type], ...]
      delete_table(expire)
      if records
        records.each do |record|
          # ここがrecache処理のエントリポイントになる
          log.puts("update! #{expire}: #{record[0]}, #{record[1]}", "info")
          #puts "update! #{expire}: #{record[0]}, #{record[1]}"
          Thread.new do
            recache.invoke(record[0], record[1])
          end
        end
      else
        log.puts("no records[#{expire}]", "warn")
      end
    end

    def set_next_expire
      if @table.size > 0 and @ttl_table.size > 0
        min = @ttl_table.pop
        # priority queueに同一valueが含まれるため
        loop do
          break if min != @ttl_table.top
          @ttl_table.pop
        end
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

    def add_ttl(expire_time)
      @mutex.synchronize do
        @ttl_table.push(expire_time)
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
