require 'test/unit'
require File.dirname(__FILE__) + '/../lib/youtube_g'

class TestClient < Test::Unit::TestCase
  
  def setup
    @uploader = YouTubeG::Upload::VideoUpload.new(@user,@pswd,@dev_key)               
    @uploader.auth_token = "auth_token_for_testing" 
    @response = nil   
    @user = "user"
    @pswd = "pswd"
    @dev_key = "dev_key"
    @client_id = "client_id"
  end

  def test_logger_still_active_without_rails_default       
    if Object.const_defined?(@uploader.get_rails_default_logger_name)
      assert_not_nil "Expected a #{@uploader.get_rails_default_logger_name}", @uploader.init_logger
    else
      assert_not_nil "Expected a Logger.new", @uploader.init_logger            
    end  
  end 
  
  def test_passing_auth_token_in_constructor         
    upload = YouTubeG::Upload::VideoUpload.new(@user,@pswd,@dev_key)
    assert_nil upload.auth_token  
    
    upload = YouTubeG::Upload::VideoUpload.new(@user,@pswd,@dev_key,@client_id, :test_token)
    assert_equal :test_token, upload.auth_token
  end   
                        
  def test_authentication_error_raised_for_403           
    Net::HTTP.module_eval do 
      def post(post,data,header)
        response =  Net::HTTPForbidden.new("403","403","403")
      end                                
    end

    assert_raise YouTubeG::Upload::AuthenticationError do          
      @response = @uploader.upload("a_file")
    end                                          
  end     
  
  def test_upload_error_raised_for_400
    Net::HTTP.module_eval do 
      def post(post,data,header)
        response =  YTErrors.new("400","400","400")
      end                                
    end

    assert_raise YouTubeG::Upload::UploadError do          
      response = @uploader.upload("a_file")
    end
  end    
     
  def test_get_auth_header_for_auth_sub                                           
    token = "1234554321"
    upload = YouTubeG::Upload::VideoUpload.new(@user,@pswd,@dev_key,@client_id, token)
    assert_equal YouTubeG::Upload::AUTH_SUB_HEADER+token, upload.get_auth_header
  end

  def test_get_auth_header_for_client_login  
    token = "1234554321"
    # YouTubeG::Upload.module_eval do 
    #   def derive_auth_token()
    #     token
    #   end                                
    # end          
    
    # mock the result of derive_auth_token
    upload = YouTubeG::Upload::VideoUpload.new(@user,@pswd,@dev_key,@client_id)
    upload.auth_token = token                                   
    assert_equal YouTubeG::Upload::CLIENT_LOGIN_HEADER+token, upload.get_auth_header
  end
   
              
  # stubs
  class Net::HTTPForbidden < Net::HTTPClientError # 403
    def body
      return "ERROR=redefined_body_for_testing_only"
    end
  end 
  
  class YTErrors < Net::HTTPClientError
    def body   
      errors_xml = ''
      errors_xml << "<?xml version='1.0' encoding='UTF-8'?>"
      errors_xml << "<errors>"
      errors_xml << "  <error>"
      errors_xml << "    <domain>yt:validation</domain>"
      errors_xml << "    <code>required</code>"
      errors_xml << "    <location type='xpath'>media:group/media:title/text()</location>"
      errors_xml << "  </error>"
      errors_xml << "  <error>"
      errors_xml << "    <domain>yt:validation</domain>"
      errors_xml << "    <code>required</code>"
      errors_xml << "    <location type='xpath'>media:group/media:description/text()</location>"
      errors_xml << "  </error>"
      errors_xml << "</errors>"      
    end
  end 
  
                       
end