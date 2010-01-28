#
# 再キャッシュするレコードを管理するLRUテーブル
#
module EndlessDNS
  class LRU
    include Enumerable

    attr_reader :size, :keys
    def initialize(max_elements = 100)
      @max_elements = max_elements
      @keys = LinkedList.new
      @map = {}
      @size = 0
    end

    def clear!
      new(@max_elements)
    end
    
    def max?
      @size == @max_elements
    end

    def each
      @map.each do |key, el|
        yield key, el.value
      end
    end

    def [](key)
      get(key)
    end

    def get(key)
      if el = @map[key]
        @keys.move_to_head(el)
        return el.value
      elsif block_given?
        return put(key, yield)
      end
      return nil
    end

    def []=(key, value)
      put(key, value)
    end

    def put(key, value)
      el = @map[key]
      if el
        el.value = value
        @keys.move_to_head(el)
      else
        el = @keys.add(key, value)
        @size += 1
      end
      @map[key] = el
      if @size > @max_elements
        delete_element(@keys.last)
        @size -= 1
      end
      value
    end

    def delete(key)
      if el = @map[key]
        delete_element(el)
        @size -= 1
      else
        nil
      end
    end

    private
    def delete_element(el)
      @keys.remove_element(el)
      @map.delete(el.key)
      el.value
    end
  end

  class LinkedList

    attr_reader :last
    def initialize
      @head = @last = nil
    end

    def add(key, value)
      add_element(Element.new(key, value, @head))
    end

    def add_element(el)
      @head.previouse_element = el if @head
      el.next_element = @head
      el.previouse_element = nil
      @head = el
      @last = el unless @last
      el
    end

    def move_to_head(el)
      remove_element(el)
      add_element(el)
    end

    def remove_element(el)
      el.previouse_element.next_element = el.next_element if el.previouse_element
      el.next_element.previouse_element = el.previouse_element if el.next_element
      @last = el.previouse_element if el == @last
      @head = el.next_element if el == @head
    end

    def pp
      s = ''
      el = @head
      while el
        s << ', ' if s.size > 0
        s << el.to_s
        el = el.next_element
      end
    end

    class Element
      attr_accessor :key, :value, :previouse_element, :next_element
      def initialize(key, value, next_element)
        @key = key
        @value = value
        @next_element = next_element
        @previouse_element = nil
      end

      def inspect
        to_s
      end

      def to_s
        p = @previouse_element ? @previouse_element.key : 'nil'
        n = @next_element ? @next_element.key : 'nil'
        "[#{@key}: #{@value.inspect}, previouse: #{p}, next:#{n}]"
      end
    end
  end
end

if __FILE__ == $0
  lru = EndlessDNS::LRU.new(5)
  lru.put("www.google.com.:A", true)
  lru.put("www.google.com.:AAAA", true)
  lru.put("www.google.com.:PTR", true)
  lru.put("www.google.com.:NS", true)
  lru.put("www.google.com.:SOA", true)
  p lru.size
  p lru.get("www.google.com.:A")
end
