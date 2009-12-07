#
# Log処理
#
module EndlessDNS
  class Log
    LOG_LEVEL = Logger::WARN
    LOG_DIR = "log"
    LOG_NAME = "endlessdns.log"

    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
    end

    def setup
      @logdir = config.get("logdir") ? config.get("logdir") : default_logdir()
      unless File.exist? @logdir
        Dir.mkdir @logdir
      end
      @logname = config.get("logname") ? config.get("logname") : LOG_NAME
      @logger = Logger.new("#{@logdir}/#{@logname}", 'daily')
      @loglevel = config.get("loglevel") ? config.get("loglevel") : LOG_LEVEL
      @logger.level = @loglevel
    end

    def default_logdir
      EndlessDNS::APP_DIR + "/" + LOG_DIR
    end

    def puts(msg, level)
      eval("@logger.#{level}('#{msg}')")
    end

    def debug(msg)
      @logger.debug(msg)
    end

    def info(msg)
      @logger.info(msg)
    end

    def warn(msg)
      @logger.warn(msg)
    end

    def error(msg)
      @logger.error(msg)
    end

    def fatal(msg)
      @logger.fatal(msg)
    end

    def loglevel=(level)
      @logger.level = level
    end

    def loglevel
      @logger.level
    end
  end
end

def log
  EndlessDNS::Log.instance
end
