#
# Main menuの管理
#
require 'erb'

module MenuHelper
  MENUS = %w[Home Statistics Config]

  def render_main_menu
    ERB.new(menu_erb).result(binding)
  end

  def menu_erb
    <<-EOF
<ul>
<% MENUS.each do |menu| %>
  <% if menu.downcase == @selected %>
    <li><a class="selected" href="<%= make_link(menu) %>"><%= menu %></a></li>
  <% else%>
    <li><a href="<%= make_link(menu) %>"><%= menu %></a></li>
  <% end %>
<% end %>
</ul>
    EOF
  end

  def make_link(menu)
    menu.downcase
  end
end

if __FILE__ == $0
  include MenuHelper
  puts render_main_menu
end
