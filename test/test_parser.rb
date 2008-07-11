require 'test/unit'
require File.dirname(__FILE__) + '/../lib/youtube_g'  

class TestParser < Test::Unit::TestCase
  
  def setup
    @parser = YouTubeG::Parser::UploadErrorParser.new(well_formed_errors_xml)
    @result = @parser.parse               
  end
                    
  def test_feed_parser_error_for_empty_xml          
    assert_raise YouTubeG::Parser::FeedParserError do
      parser = YouTubeG::Parser::UploadErrorParser.new("")
    end
  end     
  
  def test_construction_of_upload_error_model     
    assert_instance_of(Array, @result)       
    assert_equal(2,@result.length)
    
    @result.each_with_index do |error, i|                        
      assert_instance_of(YouTubeG::Model::UploadError, error)
      assert_equal(YT_VALIDATION,error.domain)
      assert_equal(REQUIRED,error.code)
      assert_equal(i == 0 ? TEXT_XPATH : DESC_XPATH,error.location)      
    end
    
    
  end                                         
  
  YT_VALIDATION = "yt:validation"      
  REQUIRED = "required"                                   
  TEXT_XPATH = "media:group/media:title/text()"           
  DESC_XPATH = "media:group/media:description/text()"
      
  def well_formed_errors_xml   
    errors_xml = ''
    errors_xml << "<?xml version='1.0' encoding='UTF-8'?>"
    errors_xml << "<errors>"
    errors_xml << "  <error>"
    errors_xml << "    <domain>#{YT_VALIDATION}</domain>"
    errors_xml << "    <code>#{REQUIRED}</code>"
    errors_xml << "    <location type='xpath'>#{TEXT_XPATH}</location>"
    errors_xml << "  </error>"
    errors_xml << "  <error>"
    errors_xml << "    <domain>#{YT_VALIDATION}</domain>"
    errors_xml << "    <code>#{REQUIRED}</code>"
    errors_xml << "    <location type='xpath'>#{DESC_XPATH}</location>"
    errors_xml << "  </error>"
    errors_xml << "</errors>"      
  end   
  
  def malformed_errors_xml   
    errors_xml = ''
    errors_xml << "<errors>"
    errors_xml << "  <error>"
    errors_xml << "    <domain>yt:validation</domain>"
    errors_xml << "    <code>required</code>"
    errors_xml << "    <location type='xpath'>media:group/media:title/text()</location>"
    errors_xml << "</errors>"      
  end   
  
                       
end