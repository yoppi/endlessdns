module EndlessDNS
  class Timer
    include Observable

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      #@running = false  
      @cnt = 0
      @mutex = Mutex.new
      #run
    end

    def run
      @timer_th = Thread.new do
        sleep @cnt
        changed
        notify_observers(@expire)
      end
      #  loop do
      #    while @cnt > 0
      #      if @running
      #        sleep 1
      #        @cnt -= 1
      #      end
      #    end
      #    stop
      #    changed
      #    notify_observers(@expire)
      #    end
      #  end
      #end
    end

    def run?
      #@runnning
      case @timer_th.status
      when "run"
        return true
      when "sleep"
        return true
      when "aborting"
        return false
      else
        return false
      end
    end

    def start
      #@mutex.synchronize do
      #  @running = true
      #end
      run
    end

    def stop
      #@mutex.synchronize do
      #  @running = false
      #end
      @timer_th.kill
    end

    def set(cnt, expire)
      @mutex.synchronize do
        @cnt = cnt
        @expire = expire
      end
    end
  end
end

def timer
  EndlessDNS::Timer.instance
end
