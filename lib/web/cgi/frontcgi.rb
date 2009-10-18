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

  def send(obj, cmd)
    #eval("@front.#{obj} '#{cmd}'")
    begin
      ret = @front.send(obj, cmd)
    rescue => e
      # TODO:
      # エラーメッセージを返す
    end
    ret
  end
end

def frontcgi
  FrontCGI.instance
end
