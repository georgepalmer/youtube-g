require 'test/unit'
require File.dirname(__FILE__) + '/../lib/youtube_g'

class TestClient < Test::Unit::TestCase
  def setup
    @upload = YouTubeG::Upload::VideoUpload.new("user","pswd","dev_key")
  end

  def test_logger_still_active_without_rails_default       
    if Object.const_defined?(@upload.get_rails_default_logger_name)
      assert_not_nil "Expected a #{@upload.get_rails_default_logger_name}", @upload.logger            
    else
      assert_not_nil "Expected a Logger.new", @upload.logger            
    end  
  end 
  
  def test_passing_auth_token_in_constructor         
    upload = YouTubeG::Upload::VideoUpload.new("user","pswd","dev_key")
    assert_nil upload.auth_token  
    
    upload = YouTubeG::Upload::VideoUpload.new("user","pswd","dev_key","client_id", :test_token)
    assert_equal :test_token, upload.auth_token
  end
end