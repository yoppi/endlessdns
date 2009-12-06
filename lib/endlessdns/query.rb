class Query

  PKT_INTERVAL = 1000

  attr_reader :client_query, :client_query_num
  attr_reader :localdns_query, :localdns_query_num
  attr_reader :timebase_hit_query, :pktbase_hit_query, :total_hit_query
  attr_accessor :interval_pkt_num

  def initialize
    @client_query = {}
    @client_query_num = {}

    @interval_pkt_num = {}

    @localdns_query = {}
    @localdns_query_num = 0

    @timebase_hit_query = {}
    @pktbase_hit_query = {}
    @total_hit_query = {}

    @mutex = Mutex.new
  end

  def add_client_query(src, name, type)
    @mutex.synchronize do
      @client_query[src] ||= Hash.new
      @client_query[src][[name, type]] ||= 0
      @client_query[src][[name, type]] += 1

      @client_query_num[src] ||= {}
      @client_query_num[src][type] ||= 0
      @client_query_num[src][type] += 1

      @interval_pkt_num[src] ||= 0
      @interval_pkt_num[src] += 1
    end
  end

  def clear_client_query
    @mutex.synchronize do
      @client_query.clear
      @client_query_num.clear
    end
  end

  def add_localdns_query(src, name, type)
    @mutex.synchronize do
      @localdns_query[src] ||= Hash.new
      @localdns_query[src][[name, type]] ||= 0
      @localdns_query[src][[name, type]] += 1
      @localdns_query_num += 1
    end
  end

  def clear_localdns_query
    @mutex.synchronize do
      @localdns_query.clear
      @localdns_query_num = 0
    end
  end

  def add_hit_query(src, type)
    @mutex.synchronize do
      @total_hit_query[src] ||= {}
      @total_hit_query[src][type] ||= 0
      @total_hit_query[src][type] += 1

      #@timebase_hit_query[src] ||= {}
      #@timebase_hit_query[src][type] ||= 0
      #@timebase_hit_query[src][type] += 1

      #@pktbase_hit_query[src] ||= {}
      #@pktbase_hit_query[src][type] ||= 0
      #@pktbase_hit_query[src][type] += 1
    end
  end

  def clear_total_hit_query
    @mutex.synchronize do
      @total_hit_query.clear
    end
  end

  def clear_timebase_hit_query
    @mutex.synchronize do
      @timebase_hit_query.clear
    end
  end

  def clear_pktbase_hit_query
    @mutex.synchronize do
      @pktbase_hit_query.clear
    end
  end

  def interval?(src)
    if @interval_pkt_num[src] && @interval_pkt_num[src] > 0
      @interval_pkt_num[src] % PKT_INTERVAL == 0
    else
      false
    end
  end

  def total_hit_query(src)
    if src
      @total_hit_query[src]
    else
      @total_hit_query
    end
  end

  def client_query_num(src)
    if src
      @client_query_num[src]
    else
      @client_query_num
    end
  end
end
