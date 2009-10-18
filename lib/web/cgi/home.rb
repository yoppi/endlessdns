#
# Home
#   o Master情報
#   o Slave情報
#   接続したサーバをトップに表示する
#
require 'cgi'
require 'erb'
require 'frontcgi'
require 'menu'

class Home
  include MenuHelper
  include CGI::Util

  def initialize(cgi)
    @cgi = cgi
  end

  def get_statuses
    @self_status = get_self_status
    @another_status = get_another_status
  end

  def get_self_status
    frontcgi.send('share', 'self_status')
  end

  def get_another_status
    frontcgi.send('share', 'another_status')
  end

  def render_contents
    # base.rhtmlを読みこむ
    base = File.read("base.rthml")
    @erb = Erb.new(base)
  end

  def out
    @cgi.out {
      to_html
    }
  end

  def content_erb
    <<-EOS
<h2>self host status</h2>
<h3><%= @self_status[:host_type] %></h3>
<table>
  <tr>
    <th>IP Address</th>
    <th>DNS Cache Server Status</th>
    <% if @self_status[:host_type] == "master" %>
      <th>Slave Number</th>
    <% else %>
      <th>Master Conectivity</th>
    <% end %>
    <th>Update</th>
  </tr>
  <tr>
    <td><%= @self_status[:ip] %></td>
    <td><%= @self_status[:cache] %></td>
    <% if @self_status[:host_type] == "master" %>
      <td><%= @self_status[:snum] %></td>
    <% else %>
      <td><%= @self_status[:mcon] %></td>
    <% end %>
    <td><%=  @self_status[:update] %></td>
  </tr>
</table>
<h2>another host status</h2>
<h3></h3>
    EOS
  end

  def to_html
    @erb.result(binding)
  end
end

cgi = CGI.new
home = Home.new(cgi)
home.get_statuses
home.render_contents
home.out
