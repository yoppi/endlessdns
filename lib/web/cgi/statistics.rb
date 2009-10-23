#
# Statistics
#   o キャッシュをタイプ別に表示
#   o ネガティブキャッシュの表示
#     - 表にトップ10くらいを表示
#   o hit率
#   o クエリの散布図
require 'cgi'
require 'erb'
require 'frontcgi'
require 'menu'

class Statistics
  include MenuHelper
  PERIOD = 60 * 60 * 12

  def initialize(cgi)
    @cgi = cgi
    @selected = "statistics"
  end

  # Ajaxによるデータの変更なのかチェック
  def do_request
    if from_ajax?
      do_ajax
    else
      do_top
    end
  end

  def from_ajax?
    @cgi.request_method == "POST"
  end

  # main menuからアクセスした場合
  def do_top
    # 各グラフの現在からデフォルトの期間分の区間統計データを取得する 
    # jsを生成してhtmlに埋めこんで返す
    graphs = make_graphs()
    graphs.each do |graph|
      graph.get_statistics
    end
  end

  def make_graphs
    ret = []
    ret << Cache.new
    ret << NegativeCache.new
    ret << HitRate.new
    ret << Query.new
    ret
  end

  # jsonで指定された区間データを返却
  def do_ajax
    # どのグラフかをクエリから判断してそのオブジェクトから指定された区間データを集め返却 
  end

  def setup
    @base = File.read("base.rhtml")
  end

  def out
    @cgi.out {
      to_html
    }
  end

  def to_html

  end

  def html_title
    "Statistics"
  end
end

# abstract class
class Graph
  def initialize
  end

  def get_period
    # GETかPOSTで表示期間が指定されていればそれを使う
  end

  def get_statistics
    now = Time.now
    period = get_period()
  end

  def db_name
    frontcgi.call("statistics", "db_name", self.class.to_s.downcase)
  end
end

class Cache < Graph
  def initialize
    init_db
  end

  def get_statistics
  end

  def init_db
    @db = PStore.new(db_name())
  end
end

class NegativeCache < Graph
  def initialize
  end

  def get_statistics
  end
end

class HitRate < Graph
  def initialize
  end

  def get_statistics
  end
end

class Query < Graph
  def initialize
  end

  def get_statistics
  end
end

cgi = CGI.new
stats = Home.new(cgi)
stats.do_request
#stats.setup
stats.out
