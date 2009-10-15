#
# CGIセットアップ
#
require 'drb/drb'

module EndlessDNS
  class CGIHelper
    FRONT_PORT = 9997
    WEBSERVER = EndlessDNS::LIB_DIR + "/" + "web/webserver.rb" 

    def initialize
      @front_addr = config.get("dnsip")
      @front_port = FRONT_PORT
    end

    def setup
      setup_webserver
      setup_front
    end

    def setup_webserver
      fork do
        exec(WEBSERVER)
      end
      log.puts("launching webserver", "info")
    end

    def setup_front
      front = Front.new
      DRbObject.start_service("druby://#{@front_addr}:#{@front_port}", front)
      log.puts("start cgi service")
    end
  end
end
