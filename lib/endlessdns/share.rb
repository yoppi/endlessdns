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
      start_master_service(@serv_addr, @serv_port)
    end

    def slave_setup
      master = DRbObject.new_with_uri("druby://#{@master_addr}:#{@master_port}")
      @self_host = EndlessDNS::Slave.new(master)
      @self_host.run

      # loopを抜けたらmasterとの通信が切れ自身がmasterになる
      start_master_service(config.get['dnsip'], PORT)
    end

    def start_master_service(addr, port)
      @self_host = EndlessDNS::Master.new
      DRb.start_service("druby://#{addr}:#{port}", @self_host)
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
        @self_host.set_interval(interval.to_i)
      end
    end
  end # Share end

  class Host
    def dnscache_process_status
      pid = config.get('dnspid')
      if pid
        process_status(pid)
      else
        log.warn("cannot get pid")
        "undefined"
      end
    end

    # CPU使用率やメモリ使用率も必要か?
    # topコマンドを使うと遅いが回収可能
    def process_status(pid)
      _ = `ps p #{pid}`.split("\n")
      if _[1] && _[1].split(" ")[0] == pid
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
      @priorities = {}
      refresh_self_status
    end

    def get_cache
      cache.deep_copy_cache
    end

    def add_cache(diff)
      diff.each do |name_type|
        name, type = name_type.split(':')
        recache.force_invoke(name, type)
      end
    end

    def update_slave_status(status)
      @slave_statuses.delete_if do |slave_status|
        slave_status[:ip] == status[:ip]
      end
      @slave_statuses << status
    end

    def update_priority(ip, priority)
      @priorities[ip] = priority
      if @priorities.size == 1
        return @priorities.keys[0]
      else
        elect_priority()
      end
    end

    def elect_priority
      min = @priorities.min {|a, b| a[1] <=> b[1] }
      mins = @priorities.select {|_, val| min[1] == val }
      if mins.size == 1
        return mins.shift[0]
      else
        # TODO: より適切なmetric値を選ぶ
        return mins[rand(mins.size)][0]
      end
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
    RETRY_SEC = 300
    SHARE_INT = 300
    PRIORITY = 10
    RETRY_MAX = 5

    def initialize(master)
      @master = master
      @share_interval = default_share_interval()
      @retry_sec = default_retry_sec()
      @priority = default_priority()
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
      @retry_num = 0
      @next_master = nil
      refresh_self_status
    end

    def run
      catch(:exit) do
        loop do
          sleep @share_interval
          begin
            update_cache
            update_status
            update_priority
          rescue => e
            log.warn("cannot connect master server!")
            update_conectivity("down")

            sleep @retry_sec
            @retry_num += 1

            if @retry_num > RETRY_MAX
              change_master
            end

            retry
          end
          update_conectivity(Time.now)
        end
      end
      log.warn("master is down. self to be master")
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

    def update_priority
      @next_master = @master.update_priority(host_ipaddr(), @priority)
    end

    def change_master
      if @next_master
        if @next_master != host_ipaddr()
          @master = DRbObject.new_with_uri("druby://#{@next_master}:#{EndlessDNS::Share::PORT}")
          log.warn("master is down. change master[#{@next_master}]")
        else
          throw :exit
        end
      end
    end

    def update_conectivity(arg)
      @master_conectivity = arg
    end

    # hash1 - hash2
    def diff_cache(h1, h2)
      h1_keys = h1.keys
      h2_keys = h2.keys
      h1_keys - h2_keys
    end

    def update_self_cashe(diff)
      diff.each do |name_type|
        name, type = name_type.split(':')
        recache.force_invoke(name, type)
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
        @another_statuses << s if s[:ip] != host_ipaddr()
      end
    end

    def refresh_self_status
      @status[:host_type] = "slave"
      @status[:ip] = host_ipaddr()
      @status[:cache] = dnscache_process_status()
      @status[:mcon] = master_conectivity()
      @status[:update] = Time.now
      @status[:priority] = priority()
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

    def default_share_interval
      config.get['share']['share-interval'] ? config.get['share']['share-interval'] : SHARE_INT
    end

    def retry_sec
      @retry_sec
    end

    def set_retry_sec(retry_sec)
      @retry_sec = retry_sec
    end

    def default_retry_sec
      config.get['share']['retry'] ? config.get['share']['retry'] : RETRY_SEC
    end

    def priority
      @priority
    end

    def set_priority(priority)
      @priority = priority
    end

    def default_priority
      config.get['share']['priority'] ? config.get['share']['priority'] : PRIORITY
    end
  end # Slave END
end # EndlessDNS END

def share
  EndlessDNS::Share.instance
end
