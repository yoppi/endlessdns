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

  def call(obj, cmd)
    #eval("@front.#{obj} '#{cmd}'")
    begin
      ret = @front.call(obj, cmd)
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
