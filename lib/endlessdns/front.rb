#
# CGI用frontサーバ
#   o cache
#   o statistics
#   o recach
#   o snoop
# にアクセスする
module EndlessDNS
  class Front
    SERVICE_INSTANCES = %w[cache statistics recach snoop share]
    def initialize
    end

    def method_missing(instance, cmd)
    end

    def send(instance, cmd, args=nil)
      if SERVICE_INSTANCES.include?(instance)
        o = eval(instance)
        if args
          o.__send__(cmd, args)
        else
          o.__send__(cmd)
        end
      else
        log.puts("no #{instance}", "warn")
      end
    end
  end
end
