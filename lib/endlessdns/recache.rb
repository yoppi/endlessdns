#
# レコードの再cache
#
module EndlessDNS
  class Recache
    class << self
      def instance
        @instance ||= self.new
      end
    end

    def initialize
      @resolver = Net::DNS::Resolver.new
      @resolver.res = config.get(:localip)
    end

    def run(name, type)
      need_recache?(name, type)
      ret = @resolver.search(name, type)
    end

    def need_recache?(name, type)
      # 統計データからfalseかtrue
      true
    end
  end
end

def recache
  EndlessDNS::Recache.instance
end
