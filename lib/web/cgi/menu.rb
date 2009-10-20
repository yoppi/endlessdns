#
# Main menuの管理
#
require 'erb'

module MenuHelper
  MENUS = %w[Home Statistics Config]

  def render_main_menu
    menu_src
  end

  def menu_src
    <<-EOF
<ul>
<% MENUS.each do |menu| %>
  <li><a href="<%= make_link %>"><%= menu %></a></li>
<% end %>
</ul>
    EOF
  end

  def make_link(menu)
    menu.downcase + ".rb"
  end
end
