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
      @mutex = Mutex.new
      run
    end

    def run
      Thread.new do
        loop do
          if @running
            while @cnt > 0
              sleep 1
              @cnt -= 1
            end
          end
          stop
          changed
          notify_observers(@expire)
        end
      end
    end

    def run?
      @runnning
    end

    def start
      @mutex.synchronize do
        @running = true
      end
    end

    def stop
      @mutex.synchronize do
        @running = false
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
