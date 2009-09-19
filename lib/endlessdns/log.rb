require 'logger'

module EndlessDNS
  class Log
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
    end

    def setup
      @logdir = config.get("logdir") ? config.get("logdir") :
                                      EndlessDNS::LOG_DIR
      unless File.exist? @logdir
        Dir.mkdir @logdir
      end
      @logname = config.get("logname") ? config.get("logname") :
                                         EndlessDNS::LOG_NAME
      @logger = Logger.new("#{@logdir}/#{@logname}")
    end
  end
end

def log
  EndlessDNS::Log.instance
end
