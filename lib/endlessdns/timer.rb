module EndlessDNS
  class Timer
    include Observable

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      @running = false
      @cnt = 0
      @force_stop = false
      @mutex = Mutex.new
      run
    end

    def run
      @timer_th = Thread.new do
        loop do
          if @running
            while @running && @cnt > 0
              sleep 1
              @cnt -= 1
            end
            unless @force_stop
              stop
              changed
              notify_observers(@expire)
            end
          end
          sleep 1
        end
      end
    end

    def run?
      @runnning
    end

    def start
      @mutex.synchronize do
        @running = true
        @force_stop = false
      end
    end

    def stop
      @mutex.synchronize do
        @running = false
        @force_stop = true
      end
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
