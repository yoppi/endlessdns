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

  def get_statistics
    now = Time.now
    period = get_period()
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

  def get_period
    # GETかPOSTで表示期間が指定されていればそれを使う
    @cgi[]
  end
end

cgi = CGI.new
stats = Home.new(cgi)
stats.get_statistics
stats.setup
stats.out
