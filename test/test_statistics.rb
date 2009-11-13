require File.dirname(__FILE__) + '/test_helper'

class TestStatistics < Test::Unit::TestCase
  context "クエリの追加テスト" do
    should "1つのクライアントのクエリが追加されている" do
      statistics.add_client_query("192.168.0.1", "example.co.jp", "A")
      client_query = statistics.client_query
      assert_equal({["example.co.jp", "A"] => 1}, client_query["192.168.0.1"])
      client_query_num = statistics.client_query_num
      assert_equal(1, client_query_num["A"])
    end

    should "1つのローカルDNSのクエリが追加されている" do
      statistics.add_localdns_query("192.168.0.1", "example.co.jp", "A")
      query = statistics.localdns_query
      assert_equal({["example.co.jp", "A"] => 1}, query["192.168.0.1"])
      num = statistics.localdns_query_num
      assert_equal(1, num)
    end

    teardown do
      statistics.clear_client_query
      statistics.clear_localdns_query
    end
  end

  context "レスポンスの追加テスト" do
    should "1つのローカルDNSのレスポンスが追加されている" do
      statistics.add_localdns_response("192.168.0.1", "example.co.jp", "A")
      response = statistics.localdns_response
      assert_equal({["example.co.jp", "A"] => 1}, response["192.168.0.1"])
      num = statistics.localdns_response_num
      assert_equal(1, num)
    end

    should "1つの外部DNSのレスポンスが追加されている" do
      statistics.add_outside_response("192.168.0.1", "example.co.jp", "A")
      response = statistics.outside_response
      assert_equal({["example.co.jp", "A"] => 1}, response["192.168.0.1"])
      num = statistics.outside_response_num
      assert_equal(1, num) 
    end

    teardown do
      statistics.clear_localdns_response
      statistics.clear_outside_response
    end
  end

  context "統計情報のテスト" do
    should "1つのクライアントのクエリの統計" do
      statistics.add_client_query("192.168.0.1", "example.co.jp", "A")
      stat = statistics.client_query_stat
      assert_equal({'num_of_client' => 1, 'num_of_query' => {"A" => 1}}, stat)
    end
  end
end
