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
require 'pstore'

class Statistics
  include MenuHelper

  def initialize(cgi)
    @cgi = cgi
    @selected = "statistics"
  end

  # Ajaxによるデータの変更なのかチェック
  def do_request
    if from_ajax?
      # そのままJSON形式でリターンする
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
    graphs = make_all_graphs()
    graphs.each do |graph|
      graph.get_keys
      graph.get_statistics
      graph.convert_flot
      graph.embed_js
    end
  end

  def make_all_graphs
    ret = []
    ret << Cache.new
    ret << NegativeCache.new
    ret << HitRate.new
    ret << Query.new
    ret
  end

  # jsonで指定された区間データを返却
  def do_ajax
    # どのグラフかをクエリから判断してその指定された区間データを集め返却 
    graph = which_graph?()
  end

  def which_graph?
    # CGIのクエリから判断
  end

  def setup
    @base = File.read("base.rhtml")
    embeded = embed_menu(base)
    @erb = ERB.new(embeded)
  end

  def embed_menu(text)
    text.gusb(/render_main_menu/, render_main_menu)
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
    "Statistics"
  end
end

# abstract class
class Graph
  DEFAULT_PERIOD = 60 * 60 * 12

  def initialize(period)
    @period = period || get_period()
    init_db
  end

  def get_period
    e = Time.now
    s = e - DEFAULT_PERIOD
    e = convert_time(e)
    s = convert_time(e)
    [s, e]
  end

  def get_keys
    all_dates = get_all_dates()
    @selected_keys = select_date_sets(all_dates).sort
  end

  def get_statistics
    @statistics = {}
    @db.transaction do
      @selected_keys.each do |key|
        data[key] = @db[key]
      end
    end
  end

  def convert_flot
    @flot = {}
    @statistics.each do |key, types|
      types.each do |type, n|
        @flot[type] ||= []
        @flot[type] << [key, n]
      end
    end
  end

  def get_all_dates
    date_sets = nil
    @db.transaction do
      date_sets = @db.roots
    end
    date_sets
  end

  def select_date_sets(date_sets)
    ret = []
    date_sets.select do |date|
      ret << date if @period[0] <= date && date <= @period[1]
    end
    ret
  end

  def convert_time(time)
    ret = ""
    ret << sprintf("%04d", time.year)
    ret << spritnf("%02d", time.month)
    ret << sprintf("%02d", time.day)
    ret << sprintf("%02d", time.hour)
    ret << sprintf("%02d", time.min)
    ret
  end

  def init_db
    @db = PStore.new(db_name())
  end

  def db_name
    frontcgi.call("statistics", "db_name", self.class.to_s.downcase)
  end
end

class Cache < Graph
  def initialize(period=nil)
    super(period)
  end

  def get_statistics
  end
end

class NegativeCache < Graph
  def initialize(period=nil)
    super(period)
  end

  def get_statistics
  end
end

class HitRate < Graph
  def initialize(period=nil)
    super(period)
  end

  def get_statistics
  end
end

class Query < Graph
  def initialize(period=nil)
    super(period)
  end

  def get_statistics
  end
end

cgi = CGI.new
stats = Statistics.new(cgi)
stats.do_request
stats.setup
stats.out
