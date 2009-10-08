#
# キャッシュの分散共有
#
require 'drb/drb'

module EndlessDNS
  class Sharing
    RETRY_SEC = 300

    def initialize
    end

    def setup
      # masterかslaveかを決定
      check_master_or_slave
      if @host == "master"
        # masterであればDRbServerを起動
        master_setup
      else
        # slaveであればDRbServerに対してリクエストを送る
        slave_setup
      end
    end

    def check_master_or_slave
      share = config.get("share") ? config.get("share") : default_share
      @host_type = share['host-type']
      if @host_type == "master"
        @serv_addr = share['serv-addr']
        raise "must be set serv-addr" unless @serv_addr
        @serv_port = share['serv-port']
        raise "must be set serv-port" unless @serv_port
      elsif @host_type == "slave"
        @master_addr = share['master-addr']
        raise "must be set master-addr" unless @master_addr 
        @master_port = share['master-port']
        raise "must be set master-port" unless @master_port
        @refresh = share['refresh']
        raise "must be set refresh" unless @refresh
      else
        raise "Unknown host type [#{@host_type}]"
      end
    end

    def default_share
      share = {}
      share['host-type'] = "master"
      share['serv-addr'] = config.get("dnsip")
      share['serv-port'] = 12345
      share
    end
  
    def master_setup
      front = EndlessDNS::Master.new
      DRb.start_service("druby://#{@host}:#{@port}", front)
    end

    def slave_setup
      begin
        master = DRbObject.new_with_uri("druby://#{@master_addr}:#{@master_port}")
        #この時点ではdrbサーバが起動していないくてもエラーにならない。
        # objectに対してメソッドをsendして初めて分かる
      rescue
        sleep RETRY_SEC
        retry
      end
      Thread.new do
        slave = EndlessDNS::Slave.new(master, @refresh)
        slave.run
      end
    end
  end

  class Master
    def initialize
    end

    def pull
      cache.deep_copy_cache
    end

    def push(diff)
      diff.each do |name_type, rdatas| 
        rrdatas.each do |rdata| 
          cache.add(name_type[0], name_type[1], rdata)
        end
      end
    end
  end

  class Slave
    def initialize(master, refresh)
      @master = master
      @refresh = refresh
    end

    def run
      loop do
        sleep @refresh 
        master_cache = @master.pull
        self_cache = cache.deep_copy_cache

        diff_self = get_diff(master_cache, self_cache)
        diff_master = get_diff(self_cache, master_cache)
        update_self_cashe(diff_self)
        update_master_cache(diff_master)
      end
    end

    # hash1 - hash2
    def get_diff(h1, h2)
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
        rrdatas.each do |rdata| 
          cache.add(name_type[0], name_type[1], rdata)
        end
      end
    end

    def update_master_cache(diff)
      @master.push(diff)
    end
  end 
end
