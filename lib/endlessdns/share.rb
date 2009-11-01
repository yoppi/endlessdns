#
# キャッシュの分散共有
#
require 'drb/drb'

module EndlessDNS
  class Share
    PORT = 9998

    def self.instance
      @instance ||= self.new
    end

    def initialize
    end

    def setup
      # masterかslaveかを決定
      check_master_or_slave
      if @host_type == "master"
        # masterであればDRbServerを起動
        master_setup
      else
        # slaveであればDRbServerに対してリクエストを送る
        slave_setup
      end
    end

    def check_master_or_slave
      share = config.get("share") ? config.get("share") : default_share()
      @host_type = share['host-type']
      case @host_type
      when "master"
        @serv_addr = share['serv-addr']
        raise "must be set serv-addr" unless @serv_addr
        @serv_port = share['serv-port']
        raise "must be set serv-port" unless @serv_port
      when "slave"
        @master_addr = share['master-addr']
        raise "must be set master-addr" unless @master_addr
        @master_port = share['master-port']
        raise "must be set master-port" unless @master_port
        @share_interval = share['share-interval']
        raise "must be set share-interval" unless @share_interval
      else
        raise "Unknown host type [#{@host_type}]"
      end
    end

    def default_share
      share = {}
      share['host-type'] = "master"
      share['serv-addr'] = config.get("dnsip")
      share['serv-port'] = PORT
      share
    end

    def master_setup
      @self_host = EndlessDNS::Master.new
      DRb.start_service("druby://#{@serv_addr}:#{@serv_port}", @self_host)
    end

    def slave_setup
      master = DRbObject.new_with_uri("druby://#{@master_addr}:#{@master_port}")
      @self_host = EndlessDNS::Slave.new(master, @share_interval)
      @self_host.run
    end

    def self_status
      @self_host.status
    end

    def another_status
      @self_host.another_status
    end

    # slaveのみ
    def interval
      if @host_type == "master"
        return nil
      else
        @self_host.share_interval
      end
    end

    def set_interval(interval)
      if @host_type == "master"
        return nil
      else
        @self_host.set_share_interval(interval)
      end
    end
  end

  class Host
    def dnscache_process_status
      pid = config.get('dnspid')
      if pid
        process_status(pid)
      else
        log.puts("cannot get pid")
        "undefined"
      end
    end

    # CPU使用率やメモリ使用率も必要か?
    # topコマンドを使うと遅いが回収可能
    def process_status(pid)
      _ = `ps p #{pid}`.split("\n")
      if _[1].split(" ")[0] == pid
        "up"
      else
        "down"
      end
    end

    def host_ipaddr
      config.get('dnsip')
    end
  end

  class Master < Host
    def initialize
      # status => {
      #   :host_type => 'master'
      #   :ip => host's ip address,
      #   :cache => 'up' or 'down'
      #   :snum => num of slaves
      #   :update => request time
      # }
      @status = {}
      @slave_statuses = []
      refresh_self_status
    end

    def get_cache
      cache.deep_copy_cache
    end

    def add_cache(diff)
      diff.each do |name_type, rdatas|
        rdatas.each do |rdata|
          recache.invoke(name_type[0], name_type[1])
        end
      end
    end

    def update_slave_status(status)
      @slave_statuses.delete_if do |slave_status|
        slave_status[:ip] == status[:ip]
      end
      @slave_statuses << status
    end

    def connected?
      true
    end

    def refresh_self_status
      @status[:host_type] = "master"
      @status[:ip] = host_ipaddr()
      @status[:cache] = dnscache_process_status()
      @status[:snum] = @slave_statuses.size
      @status[:update] = Time.now
    end

    def status
      refresh_self_status
      @status
    end

    def another_status
      @slave_statuses
    end
  end

  class Slave < Host
    def initialize(master, share_interval)
    RETRY_SEC = 300

      @master = master
      @share_interval = share_interval
      # status => {
      #   :host_type => 'slave'
      #   :ip => ip address,
      #   :cache  => 'up' or 'down'
      #   :mcon => nil or time
      #   :update => user access time
      # }
      @status = {}
      @master_status = nil
      @another_statuses = [] # 他のslaveのステータス
      @master_conectivity = nil # 前回に通信した時間
      refresh_self_status
    end

    def run
      loop do
        sleep @share_interval
        begin
          update_cache
          update_status
        rescue => e
          log.puts("cannot connect master server!", "warn")
          update_conectivity("down")

          sleep RETRY_SEC

          retry
        end
        update_conectivity(Time.now)
      end
    end

    def update_cache
      master_cache = @master.get_cache
      self_cache = cache.deep_copy_cache
      diff_self = diff_cache(master_cache, self_cache)
      diff_master = diff_cache(self_cache, master_cache)
      update_self_cashe(diff_self)
      update_master_cache(diff_master)
    end

    def update_status
      update_self_status(@status)
      update_master_status
      update_another_status
    end

    def update_conectivity(arg)
      @master_conectivity = arg
    end

    # hash1 - hash2
    def diff_cache(h1, h2)
      diff = {}
      h1.each do |key, val|
        if h2.has_key?(key)
          val_diff = h1[key] - h2[key]
          diff[key] = val_diff
        else
          diff[key] = h1[key]
        end
      end
      diff
    end

    def update_self_cashe(diff)
      diff.each do |name_type, rdatas|
        rdatas.each do |rdata|
          recache.invoke(name_type[0], name_type[1])
        end
      end
    end

    def update_master_cache(diff)
      @master.add_cache(diff)
    end

    def update_self_status(status)
      refresh_self_status
      @master.update_slave_status(status)
    end

    def update_master_status
      @master_status = @master.status
    end

    def update_another_status
      _ = @master.another_status
      _.each do |s|
        @another_statuses << if s[:ip] != host_ipaddr()
      end
    end

    def refresh_self_status
      @status[:host_type] = "slave"
      @status[:ip] = host_ipaddr()
      @status[:cache] = dnscache_process_status()
      @status[:mcon] = master_conectivity()
      @status[:update] = Time.now
    end

    def status
      @status
    end

    def master_conectivity
      @master_conectivity
    end

    def another_status
      { :master => @master_status, :another => @another_statuses }
    end

    def interval
      @share_interval
    end

    def set_interval(interval)
      @share_interval = interval
    end
  end # Slave END
end # Share END

def share
  EndlessDNS::Share.instance
end
