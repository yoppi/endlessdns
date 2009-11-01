#
# Config
#   o TYPE別にキャッシュする
#   o 再キャッシュの方法(all, nonref, no)
#   o snoopingの停止/再開
#   o 統計情報のdumpする間隔の設定
#   o masterとslaveの通信間隔の設定
require 'erb'
require 'cgi'
require 'menu'
require 'frontcgi'

class Config
  include MenuHelper
  include ERB::Util

  def initialize(cgi)
    @cgi = cgi
    @selected = 'config'
    # { :recache_types => { :a => true, :aaaa => true, ...},
    #   :recache_method => 'no' or 'all' or 'ref',
    #   :snooping => 'start' or 'stop',
    #   :stats_interval => 300,
    #   :share_interval => 300
    # }
    @configs = {}
  end

  def do_request
    if post?
      do_post
    else
      do_get
    end
  end

  def post?
    @cgi.request_method == "POST"    
  end

  def do_post
    # ユーザからの設定の変更を処理してその値を設定したページを返す
    # また他の設定項目の情報を取得する
  end

  def do_get
    # 現在の設定を取得する
    @configs = collect_configs()
  end

  def setup
    base = File.read("base.rhtml")
    @erb = ERB.new(base)
  end

  def render_content
    ERB.new(File.read("config.rhtml")).result(binding)
  end

  def collect_configs
    configs = {}
    configs.merge! collect_recache_configs()
    configs.merge! collect_snoop_configs()
    configs.merge! collect_stats_configs()
    configs.merge! collect_share_configs()
    configs
  end

  def collect_recache_configs
    ret = {}
    ret[:recache_types] = frontcgi.call('recache', 'recache_types')
    ret[:recache_method] = frontcgi.call('recache', 'recache_method')
    ret
  end

  def collect_snoop_configs
    ret = {}
    ret[:snooping] = frontcgi.call('snoop', 'status')
    ret
  end

  def collect_stats_configs
    ret = {}
    ret[:stats_interval] = frontcgi.call('statistics', 'interval')
    ret
  end

  def collect_share_configs
    ret = {}
    ret[:share_interval] = frontcgi.call('share', 'interval')
    ret
  end

  def out
    @cgi.out {
      to_html
    }
  end

  def to_html
    @erb.result(binding)
  end

  def html_title
    "Config"
  end
end

cgi = CGI.new
config = Config.new(cgi)
config.do_request
config.setup
config.out
