#
# EndlessDNSのFrontと通信する
#
require 'drb/drb'

class FrontCGI
  FRONT_SERV_ADDR = "127.0.0.1"
  FRONT_SERV_PORT = 9997

  def self.instance
    @instance ||= self.new
  end

  def initialize
    @front = DRbObject.new_with_uri("druby://#{FRONT_SERV_ADDR}:#{FRONT_SERV_PORT}")
  end

  def call(obj, cmd, args=nil)
    begin
      if args
        ret = @front.call(obj, cmd, args)
      else
        ret = @front.call(obj, cmd)
      end
    rescue => e
      # TODO:
      # 詳細なエラーメッセージを返す
      puts e
    end
    ret
  end
end

def frontcgi
  FrontCGI.instance
end
