require 'test/unit'
require File.dirname(__FILE__) + '/../lib/youtube_g'  

class TestParser < Test::Unit::TestCase           
  
  UPLOAD_XML = File.new(File.dirname(__FILE__) +"/upload.xml")                        
  SEARCH_XML = File.new(File.dirname(__FILE__) +"/search.xml")
             
  YT_VALIDATION = "yt:validation"      
  REQUIRED = "required"                                   
  TEXT_XPATH = "media:group/media:title/text()"           
  DESC_XPATH = "media:group/media:description/text()"  
  
  def setup
    @ue_parser = YouTubeG::Parser::UploadErrorParser.new(well_formed_errors_xml)
    @ue_parser_result = @ue_parser.parse               
    
    @vf_parser = YouTubeG::Parser::VideoFeedParser.new(UPLOAD_XML.path)
    @vf_parser_result = @vf_parser.parse               
    
    @vfs_parser = YouTubeG::Parser::VideosFeedParser.new(SEARCH_XML.path)
    @vfs_parser_result = @vfs_parser.parse               
  end
                    
  def test_feed_parser_error_for_empty_xml          
    assert_raise YouTubeG::Parser::FeedParserError do
      parser = YouTubeG::Parser::UploadErrorParser.new("")
    end
  end     
  
  def test_upload_error_parser     
    assert_instance_of(Array, @ue_parser_result)       
    assert_equal(2,@ue_parser_result.length)
    
    @ue_parser_result.each_with_index do |error, i|                        
      assert_instance_of(YouTubeG::Model::UploadError, error)
      assert_equal(YT_VALIDATION,error.domain)
      assert_equal(REQUIRED,error.code)
      assert_equal(i == 0 ? TEXT_XPATH : DESC_XPATH,error.location)      
    end
  end                                         
   
  def test_videos_feed_parser        
    assert_instance_of(YouTubeG::Response::VideoSearch, @vfs_parser_result)       
    assert_equal("http://gdata.youtube.com/feeds/api/users/speechboxmatt/uploads",@vfs_parser_result.feed_id)
    assert_equal(25,@vfs_parser_result.max_result_count)
    assert_equal(1,@vfs_parser_result.offset)
    assert_equal(1,@vfs_parser_result.total_result_count)
    assert_equal(Time.parse("2008-06-28T16:34:33.062Z"),@vfs_parser_result.updated_at)
    assert_equal(1,@vfs_parser_result.videos.length)
    
    @vfs_parser_result.videos.each_with_index do |video, i|                        
      assert_instance_of(YouTubeG::Model::Video, video)
      # assert_equal(15,video.duration)
      assert_equal(false,video.noembed)
      assert_equal(false,video.racy)
      assert_equal("http://gdata.youtube.com/feeds/api/videos/32_mQ0PRT9I",video.video_id)
      assert_equal(Time.parse("2008-06-28T09:01:58.000-07:00"),video.published_at)
      assert_equal(Time.parse("2008-06-28T09:03:18.000-07:00"),video.updated_at)
                     
      # Categories
      assert_equal(1,video.categories.length)
      assert_equal("People & Blogs",video.categories[0].label)
      assert_equal("People",video.categories[0].term)
      # Keywords
      assert_equal(3,video.keywords.length)  
      assert_equal("test",video.keywords[0]) 
      assert_equal("blah",video.keywords[1])
      assert_equal("cool",video.keywords[2])
      
      assert_equal("Speechbox test Uploaded on 06/28/2008 at 05:01PM",video.description)
      assert_equal("Speechbox Test",video.title)
      assert_equal("Speechbox test Uploaded on 06/28/2008 at 05:01PM",video.html_content)
      assert_equal("speechboxmatt",video.author.name)
      assert_equal("http://gdata.youtube.com/feeds/api/users/speechboxmatt",video.author.uri)
      
      # Media Content
      assert_equal(1,video.media_content.length)
      assert_equal(true,video.media_content[0].default) 
      assert_equal(15,video.media_content[0].duration)     
      assert_equal("application/x-shockwave-flash",video.media_content[0].mime_type) 
                           
      # Thumbs                     
      assert_equal(4,video.thumbnails.length)
      # first thumb
      assert_equal("http://img.youtube.com/vi/32_mQ0PRT9I/2.jpg",video.thumbnails[0].url)
      assert_equal(97,video.thumbnails[0].height)
      assert_equal(130,video.thumbnails[0].width)
      assert_equal("00:00:07.500",video.thumbnails[0].time)
      # forth thumb
      assert_equal("http://img.youtube.com/vi/32_mQ0PRT9I/0.jpg",video.thumbnails[3].url)
      assert_equal(240,video.thumbnails[3].height)
      assert_equal(320,video.thumbnails[3].width)
      assert_equal("00:00:07.500",video.thumbnails[3].time)
      
      assert_equal("http://www.youtube.com/watch?v=32_mQ0PRT9I",video.player_url)
    end
  end
 
  def test_video_feed_parser_derives_content_source_as_url
    vf_parser = YouTubeG::Parser::VideoFeedParser.new(UPLOAD_XML.path)
    assert_equal(true,vf_parser.url_based?)
  end
             
  def test_video_feed_parser_derives_content_source_as_string
    vf_parser = YouTubeG::Parser::VideoFeedParser.new(UPLOAD_XML.read)
    assert_equal(false,vf_parser.url_based?)
  end
             
  def test_video_feed_parser             
    video = @vf_parser_result
    assert_instance_of(YouTubeG::Model::Video, video)       

    assert_equal(false,video.noembed)
    assert_equal(false,video.racy)
    assert_equal("http://gdata.youtube.com/feeds/api/videos/7ARaD731I24",video.video_id)
    assert_equal(Time.parse("2008-07-11T05:02:24.501-07:00"),video.published_at)
    assert_equal(Time.parse("2008-07-11T05:02:24.501-07:00"),video.updated_at) 
    
    # App control - state of the upload
    assert_equal("yes", video.app_control.draft)
    assert_equal("processing", video.app_control.state)
                   
    # Categories
    assert_equal(1,video.categories.length)
    assert_equal("People & Blogs",video.categories[0].label)
    assert_equal("People",video.categories[0].term)
    # Keywords
    assert_equal(3,video.keywords.length)  
    assert_equal("test",video.keywords[0]) 
    assert_equal("blah",video.keywords[1])
    assert_equal("cool",video.keywords[2])
    
    assert_equal("Speechbox test Uploaded on 07/11/2008 at 01:02PM",video.description)
    assert_equal("Speechbox Test 07/11/2008 at 01:02PM",video.title)
    assert_equal("Speechbox test Uploaded on 07/11/2008 at 01:02PM",video.html_content)
    assert_equal("speechboxmatt",video.author.name)
    assert_equal("http://gdata.youtube.com/feeds/api/users/speechboxmatt",video.author.uri)
    
    # Media Content
    assert_equal(1,video.media_content.length)
    assert_equal(true,video.media_content[0].default) 
    assert_equal("application/x-shockwave-flash",video.media_content[0].mime_type) 
  end
          
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