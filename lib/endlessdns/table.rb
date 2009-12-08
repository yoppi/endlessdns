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

    def add(name, type, ttl, query)
      now = Time.now.tv_sec
      expire_time = ttl + now
      if @min_expire_time == nil or @min_expire_time > expire_time
        set_min_expire(expire_time)
        add_table(expire_time, name, type, query)
        add_ttl(expire_time)
        if run_timer?
          stop_timer
        end
        set_timer(ttl, expire_time)
        start_timer
      elsif @min_expire_time <= expire_time
        add_table(expire_time, name, type, query)
        add_ttl(expire_time) if @min_expire_time != expire_time
      end
    end

    def update(expire_time)
      do_recache(expire_time)
      set_next_expire
    end

    def do_recache(expire)
      records = @table[expire] # [[name, type, query], ...]
      delete_table(expire)
      if records
        records.each do |record|
          #log.info("update! #{expire}: #{record[0]}, #{record[1]}")
          Thread.new do
            recache.invoke(record[0], record[1], record[2])
          end
        end
      else
        log.warn("no records[#{expire}]")
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

    def add_table(expire_time, name, type, query)
      @mutex.synchronize do
        @table[expire_time] ||= Set.new
        @table[expire_time] << [name, type, query]
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
