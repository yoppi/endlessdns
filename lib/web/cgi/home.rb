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

  def out
    @cgi.out {
      to_html
    }
  end

  def render_content
    content_erb
  end

  def content_erb
    File.read("home.rhtml")
  end

  def html_title
    "Home"
  end

  def to_html
    @erb.result(binding)
  end
end

cgi = CGI.new
home = Home.new(cgi)
home.get_statuses
home.setup
home.out
