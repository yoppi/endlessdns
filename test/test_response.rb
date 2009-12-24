# -*- encoding: utf-8 -*-
#
require File.dirname(__FILE__) + '/test_helper'

class TestResponse < Test::Unit::TestCase
  context "再キャッシュするレコード数が制限されている場合" do
    should "LRUResponseオブジェクトが生成される" do
      @response = EndlessDNS::Response._new(10)
      assert_equal(EndlessDNS::LRUResponse, @response.class)
      @response2 = EndlessDNS::Response._new("unlimited")
      assert_equal(EndlessDNS::LRUResponse, @response2.class)
    end

    should "Responseのインスタンス変数にもアクセスできる" do
      @response = EndlessDNS::Response._new(10)
      assert_equal({}, @response.localdns_response)
      assert_equal(0, @response.localdns_response_num)
      assert_equal({}, @response.outside_response)
      assert_equal(0, @response.outside_response_num)
    end
  end
end
