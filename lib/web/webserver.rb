#!/usr/bin/env ruby
#
# CGIWebサーバ
#
require 'webrick'
require 'yaml'
require 'rbconfig'

class WebServer
  CONF_DIR = File.expand_path "~/.endlessdns/conf"
  CONF_FILE = CONF_DIR + "/" + "webserver.conf"
  CONF_ITEMS = [
    {'item' => 'port',
     'banner' => 'Web server port',
     'default' => 9999},
    {'item' => 'logfile',
     'banner' => 'Web server logfile',
     'default' => '~/.endlessdns/log/webserver.log'}
  ]

  def initialize(docroot)
    @docroot = docroot
    load_config
  end

  def start
    @server.start
  end

  def stop
    @server.stop
  end

  def load_config
    unless File.exist? CONF_FILE
      raise "no config file"
      exit
    else  
      @conf = YAML.load_file(CONF_FILE)
    end
  end

  def setup
    rubybin = Config::CONFIG['bindir'] + '/' + Config::CONFIG['ruby_install_name']
    accesslog_io = File.open(@conf['accesslog'], 'a+')
    accesslog_io.sync = true
    @server = WEBrick::HTTPServer.new({
      :DocumentRoot => @docroot,
      :BindAddress => '0.0.0.0',
      :Port => @conf['port'],
      :CGIInterpreter => rubybin,
      :Logger => WEBrick::Log.new(@conf['serverlog'], WEBrick::BasicLog::DEBUG),
      :AccessLog => [
        [accesslog_io, WEBrick::AccessLog::COMBINED_LOG_FORMAT]
      ]
    })
    mount_cgi(@docroot)
    signal_setup
  end

  def mount_cgi(docroot)
    Dir["#{docroot}/cgi/*.rb"].each do |cgi|
      @server.mount("/cgi/#{File.basename(cgi)}", WEBrick::HTTPServlet::CGIHandler, docroot + "/cgi/" + File.basename(cgi))
    end
  end

  def signal_setup
    ['INT', 'TERM'].each do |signal|
      Signal.trap(signal) { @server.shutdown }
    end
  end
end

docroot = File.expand_path(File.dirname(__FILE__))
webserver = WebServer.new(docroot)
webserver.setup
webserver.start
