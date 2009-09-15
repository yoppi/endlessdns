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
    end

    def run?
      @runnning
    end

    def start
      while @cnt > 0
        if @running
          sleep 1
          @cnt -= 1
        end
      end
      changed
      notify_observers()
    end

    def stop
      @running = false
    end

    def set(cnt)
      @cnt = cnt
    end
  end
end

def timer
  EndlessDNS::Timer.instance
end
