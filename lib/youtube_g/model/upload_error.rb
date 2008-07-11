class YouTubeG
  module Model
    class UploadError < YouTubeG::Record
      attr_reader :domain
      attr_reader :code
      attr_reader :location     
      
      def to_s
        "location: [#{location}] domain: [#{domain}] code: [#{code}]"
      end  
    end
  end
end