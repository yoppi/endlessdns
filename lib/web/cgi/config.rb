#
# Config
#   o TYPE別にキャッシュする
#   o 再キャッシュ
#   o snoopingの停止/再開
require 'cgi'
require 'menu'

class Config
  include MenuHelper
  include ERB::Util

  def initialize(cgi)
    @cgi = cgi
    @selected = 'config'
  end

  def do_request
    if post?
      do_post
    else
      do_get
    end
  end

  def do_post
    # ユーザからの設定の変更を処理してそのままページを返す
  end

  def do_get
    # 現在の設定を返す
  end

  def setup

  end

  def out
    @cgi.out {
      to_html
    }
  end

  def to_html
  end
end

cgi = CGI.new
config = Config.new(cgi)
config.do_request
config.setup
config.out
