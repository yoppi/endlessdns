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
  include ERB::Util

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
      graph.convert_to_flot
      graph.write_datasets
      #graph.embed_js
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
    base = File.read("base.rhtml")
    embeded = embed_menu(base)
    embeded = embed_contents(embeded)
    @erb = ERB.new(embeded)
  end

  def embed_menu(text)
    text.gsub(/render_main_menu/, render_main_menu)
  end

  def embed_contents(text)
    text.gsub(/render_content/, render_content)
  end

  def render_content
    File.read("statistics.rhtml")
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

  def initialize(period=nil)
    @period = period || get_period()
    init_db
  end

  def get_period
    e = Time.now
    s = e - DEFAULT_PERIOD
    e = e.tv_sec
    s = s.tv_sec
    [s, e]
  end

  def get_keys
    all_dates = get_all_dates()
    @selected_keys = select_date(all_dates).sort
  end

  def get_statistics
    @statistics = {}
    @db.transaction do
      @selected_keys.each do |key|
        @statistics[key] = @db[key]
      end
    end
  end

  # グラフライブラリであるflotのデータ形式に変換
  def convert_to_flot
    @flot = {}
    @statistics.each do |key, types|
      if types
        types.each do |type, n|
          @flot[type] ||= []
          @flot[type] << [key * 1000, n] # flotではミリ秒でx軸を描画する
        end
      end
    end
    @flot.each do |type, val|
      val.sort! {|a, b| a[0] <=> b[0] }
    end
  end

  def write_datasets
    _ = "var #{self.class.to_s.downcase}_datasets = {"
    @flot.each do |type, data|
      _ << "#{type.downcase}: {
        label: \"#{type}\",
        data: #{data.inspect}
      },"
    end
    _ << "};"
    trg = "js/#{self.class.to_s.downcase}_datasets.js"
    File.open(trg, 'w') do |io|
      io.puts _
    end
  end

  def get_all_dates
    date_sets = nil
    @db.transaction do
      date_sets = @db.roots
    end
    date_sets
  end

  def select_date(date_sets)
    ret = []
    date_sets.select do |date|
      ret << date if @period[0] <= date && date <= @period[1]
    end
    ret
  end

  def convert_time(time)
    ret = ""
    ret << sprintf("%04d", time.year)
    ret << sprintf("%02d", time.month)
    ret << sprintf("%02d", time.day)
    ret << sprintf("%04d", time.hour)
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
end

class NegativeCache < Graph
  def initialize(period=nil)
    super(period)
  end
end

class HitRate < Graph
  def initialize(period=nil)
    super(period)
  end
end

class Query < Graph
  def initialize(period=nil)
    super(period)
  end
end

cgi = CGI.new
stats = Statistics.new(cgi)
stats.do_request
stats.setup
stats.out
