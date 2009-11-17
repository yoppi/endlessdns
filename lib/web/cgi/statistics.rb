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
    #@cgi.out {
    #  "{debug: function() {alert('ok');}}"
    #}
    else
      do_top
      setup
      out
    end
  end

  def from_ajax?
    @cgi.request_method == "POST"
  end

  def do_ajax
    # どのグラフなのか?
    graph = make_graph(@cgi['graph'])
    # 期間は?
    start_time, end_time = get_time()
    graph.set_period(start_time, end_time)
    # dbからデータを集める
    graph.get_keys
    graph.get_statistics
    graph.convert_to_flot
    graph.convert_to_json
    # jsonデータを出力する
    @cgi.out {
      graph.json
    }
  end

  def get_time
    s_time = get_start_time()
    e_time = get_end_time()
    return [s_time, e_time]
  end

  def get_start_time
    s_year = @cgi['year_from']
    s_month = @cgi['month_from']
    s_day = @cgi['day_from']
    s_hour = @cgi['hour_from']
    Time.local(s_year, s_month, s_day, s_hour)
  end

  def get_end_time
    e_year =  @cgi['year_to']
    e_month = @cgi['month_to']
    e_day = @cgi['day_to']
    e_hour = @cgi['hour_to']
    Time.local(e_year, e_month, e_day, e_hour)
  end

  # main menuからアクセスした場合
  def do_top
    # 各グラフの現在からデフォルトの期間分の区間統計データを取得する
    # jsを生成してhtmlに埋めこんで返す
    @graphs = make_all_graphs()
    @graphs.each do |graph|
      graph.get_keys
      graph.get_statistics
      graph.convert_to_flot
      graph.write_datasets
      graph.date_range
    end
  end

  def make_graph(graph)
    case graph
    when "cache"
      return Cache.new
    when "negativecache"
      return NegativeCache.new
    when "hitrate"
      return HitRate.new
    when "query"
      return Query.new
    end
  end

  def make_all_graphs
    ret = []
    ret << @cache = Cache.new
    ret << @ncache = NegativeCache.new
    ret << @hitrate =  HitRate.new
    ret << @query = Query.new
    ret
  end

  def setup
    base = File.read("base.rhtml")
    @erb = ERB.new(base)
  end

  def render_content
    ERB.new(content_erb).result(binding)
  end

  def content_erb
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

  attr_reader :start_time, :end_time
  attr_reader :period_sec, :period_time
  attr_reader :year_range
  attr_reader :json
  attr_reader :selected_keys

  def initialize(period=nil)
    @period_sec = period || get_period()
    init_db
  end

  def get_period
    e_time = Time.now
    s_time = e_time - DEFAULT_PERIOD
    @period_time = [s_time, e_time]
    e_sec = e_time.tv_sec
    s_sec = s_time.tv_sec
    [s_sec, e_sec]
  end

  def set_period(s_time, e_time)
    s_sec = s_time.tv_sec
    e_sec = e_time.tv_sec
    @period_sec = [s_sec, e_sec]
  end

  def get_keys
    all_dates = get_all_dates()
    @start_sec, @end_sec = get_minmax(all_dates)
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

  def convert_to_json
    @json = " {datasets: {"
    @flot.each do |type, data|
      @json << "#{type.downcase}: {
        label: \"#{type}\",
        data: #{data.inspect}
      },"
    end
    @json << "}}"
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

  def date_range
    # 各グラフが保持するデータの期間
    @start_time = Time.at(@start_sec)
    @end_time   = Time.at(@end_sec)
    @year_range = @start_time.year..@end_time.year
  end

  def get_all_dates
    date_sets = nil
    @db.transaction do
      date_sets = @db.roots
    end
    date_sets
  end

  def get_minmax(date_sets)
    min = max = date_sets[0]
    for data in date_sets[1..-1]
      if min > data
        min = data
      end
      if max < data
        max = data
      end
    end
    return [min, max]
  end

  def select_date(date_sets)
    ret = []
    date_sets.select do |date|
      ret << date if @period_sec[0] <= date && date <= @period_sec[1]
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
