#
# ReCacheした情報の一覧
#
require 'erb'
require 'cgi'
require 'pstore'
require 'menu'
require 'frontcgi'

class ReCache
  include MenuHelper
  include ERB::Util

  def initialize(cgi)
    @cgi = cgi
    @selected = 'recache'
  end

  def do_request
    collect_top_recache
    setup
    out
  end

  def setup
    base = File.read("base.rhtml")
    @erb = ERB.new(base)
  end

  def render_content
    ERB.new(content_erb).result(binding)
  end

  def content_erb
    File.read("recache.rhtml")
  end

  def out
    @cgi.out {
      to_html
    }
  end

  def to_html
    @erb.result(binding)
  end

  def collect_top_recache
    init
    name_types = get_nametypes()
    all_data = get_values(name_types)
    @top_data = get_topdata(all_data)
  end

  def get_nametypes()
    ret = nil
    @db.transaction do
      ret = @db.roots
    end
    ret
  end

  def get_values(keys)
    ret = {}
    @db.transaction do
      keys.each do |key|
        ret[key] = @db[key]
      end
    end
    ret
  end

  def get_topdata(all_data)
    all_data.to_a.sort {|a, b| b[1] <=> a[1] }.take(@top)
  end

  def init
    @db = PStore.new(db_name())
    @top = top_view()
  end

  def db_name
    frontcgi.call("statistics", "db_name", "recache")
  end

  def top_view
    frontcgi.call("recache", "top_view")
  end

  def html_title
    "ReCache"
  end
end

cgi = CGI.new
recache = ReCache.new(cgi)
recache.do_request

