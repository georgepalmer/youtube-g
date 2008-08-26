require 'test/unit'
require File.dirname(__FILE__) + '/../lib/youtube_g'  

class TestVideo < Test::Unit::TestCase           
    
  def test_processed_method_for_nil_state
    # we assume no app_control from YT means processed.              
    video = YouTubeG::Model::Video.new({})
    assert_equal(true, video.processed?)
  end

  def test_processed_method_for_processing_state
    video = YouTubeG::Model::Video.new({:app_control => YouTubeG::Model::Video::AppControl.new({:state => 'processing'})})
    assert_equal(false, video.processed?)
  end

  def test_processed_method_for_rejected_state
    video = YouTubeG::Model::Video.new({:app_control => YouTubeG::Model::Video::AppControl.new({:state => 'rejected'})})
    assert_equal(false, video.processed?)
  end

  def test_processed_method_for_failed_state
    video = YouTubeG::Model::Video.new({:app_control => YouTubeG::Model::Video::AppControl.new({:state => 'failed'})})
    assert_equal(false, video.processed?)
  end       
end  
