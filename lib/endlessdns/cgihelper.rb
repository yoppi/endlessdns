#
# CGIセットアップ
#
require 'drb/drb'

module EndlessDNS
  class CGIHelper
    FRONT_PORT = 9997

    def initialize
      # TODO: must be secure!
      @front_addr = "0.0.0.0"
      @front_port = FRONT_PORT
    end

    def setup
      setup_webserver
      setup_front
    end

    def setup_webserver
      if defined? JRUBY_VERSION
        Thread.new do
          require EndlessDNS::LIB_DIR + "/" + "web/webserver"
          docroot = EndlessDNS::LIB_DIR + "/" + "web"
          webserver = WebServer.new(docroot)
          webserver.setup
          webserver.start
        end
      else
        fork do
          exec(EndlessDNS::LIB_DIR + "/" + "web/webserver.rb")
        end
      end
      log.info("launching webserver")
    end

    def setup_front
      front = Front.new
      DRb.start_service("druby://#{@front_addr}:#{@front_port}", front)
      log.info("start service for cgi")
    end
  end
end
