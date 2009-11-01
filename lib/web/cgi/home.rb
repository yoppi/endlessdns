#
# Home
#   o Master情報
#   o Slave情報
#
require 'cgi'
require 'erb'
require 'frontcgi'
require 'menu'

class Home
  include MenuHelper
  include ERB::Util

  def initialize(cgi)
    @cgi = cgi
    @selected = 'home'
    @self_status = nil
    @another_status = nil
  end

  def get_statuses
    @self_status = get_self_status
    @another_status = get_another_status
  end

  def get_self_status
    frontcgi.call('share', 'self_status')
  end

  def get_another_status
    frontcgi.call('share', 'another_status')
  end

  def setup
    base = File.read("base.rhtml")
    @erb = ERB.new(base)
  end

  def out
    @cgi.out {
      to_html
    }
  end

  def render_content
    ERB.new(content_erb).result(binding)
  end

  def content_erb
    File.read("home.rhtml")
  end

  def to_html
    @erb.result(binding)
  end

  def html_title
    "Home"
  end
end

cgi = CGI.new
home = Home.new(cgi)
home.get_statuses
home.setup
home.out
