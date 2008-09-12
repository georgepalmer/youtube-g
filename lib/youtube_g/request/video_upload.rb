class YouTubeG

  module Upload
    
    CLIENT_LOGIN_HEADER = "GoogleLogin auth="
    AUTH_SUB_HEADER = "AuthSub token=" 
    
    class UploadError < Exception; end
    class AuthenticationError < Exception; end

    # require 'youtube_g'
    #
    # uploader = YouTubeG::Upload::VideoUpload.new("user", "pass", "dev-key")
    # uploader.upload File.open("test.m4v"), :title => 'test',
    #                                        :description => 'cool vid d00d',
    #                                        :category => 'People',
    #                                        :keywords => %w[cool blah test]

    class VideoUpload
      
      attr_accessor :auth_token

      def initialize user, pass, dev_key, client_id = 'youtube_g', auth_sub_token = nil
        @user, @pass, @dev_key, @client_id, @auth_sub_token = user, pass, dev_key, client_id, auth_sub_token
        @auth_token = @auth_sub_token != nil ? @auth_sub_token : nil
        @logger = init_logger
      end         
        
      # TODO merge this in with logger.rb or replace logger.rb
      def init_logger      
        if not Object.const_defined?(get_rails_default_logger_name)
           Logger.new(STDOUT)
        else
           eval(get_rails_default_logger_name)
        end                                                                                                             
      end
      
      def logger
        @logger        
      end  
      
      def get_rails_default_logger_name
         "RAILS_DEFAULT_LOGGER"
      end

      #
      # Upload "data" to youtube, where data is either an IO object or
      # raw file data.
      # The hash keys for opts (which specify video info) are as follows:
      #   :mime_type
      #   :filename
      #   :title
      #   :description
      #   :category
      #   :keywords
      #   :private
      # Specifying :private will make the video private, otherwise it will be public.
      #
      # When one of the fields is invalid according to YouTube,
      # an UploadError will be returned. Its message contains a list of newline separated
      # errors, containing the key and its error code.
      # 
      # When the authentication credentials are incorrect, an AuthenticationError will be raised.
      def upload data, opts = {}
        data = data.respond_to?(:read) ? data.read : data
        @opts = { :mime_type => 'video/mp4',
                  :filename => Digest::MD5.hexdigest(data),
                  :title => '',
                  :description => '',
                  :category => '',
                  :keywords => [] }.merge(opts)

        upload_body = generate_upload_body(boundary, video_xml, data)

        upload_header = {
        "Authorization"  => get_auth_header,
        "X-GData-Client" => "#{@client_id}",
        "X-GData-Key"    => "key=#{@dev_key}",
        "Slug"           => "#{@opts[:filename]}",
        "Content-Type"   => "multipart/related; boundary=#{boundary}",
        "Content-Length" => "#{upload_body.length}",
        }

        direct_upload_url = "/feeds/api/users/#{@user}/uploads"
        logger.debug("upload_header [#{upload_header}]")

        Net::HTTP.start(base_url) do |upload|
          response = upload.post(direct_upload_url, upload_body, upload_header)
          # todo parse this out also
          if response.code.to_i == 403                      
            logger.error("ERROR: #{response.code}")
            raise AuthenticationError, response.body[/<TITLE>(.+)<\/TITLE>/, 1]
          elsif response.code.to_i != 201               
            logger.error("ERROR: #{response.code}")
            logger.debug("response: #{response.body}")
            upload_errors = YouTubeG::Parser::UploadErrorParser.new(response.body).parse
            logger.debug("upload_errors: #{upload_errors}")
            raise UploadError, upload_errors.inspect
          end 
          return YouTubeG::Parser::VideoFeedParser.new(response.body).parse
        end

      end   
       
      def get_auth_header 
        logger.debug("@auth_sub_token [#{@auth_sub_token}]") 
        if @auth_sub_token
          return YouTubeG::Upload::AUTH_SUB_HEADER+derive_auth_token
        else
          return YouTubeG::Upload::CLIENT_LOGIN_HEADER+derive_auth_token
        end 
      end  

      private

      def base_url #:nodoc:
        "uploads.gdata.youtube.com"
      end

      def boundary #:nodoc:
        "An43094fu"
      end

      def derive_auth_token #:nodoc:    
        unless @auth_token
          http = Net::HTTP.new("www.google.com", 443)
          http.use_ssl = true
          body = "Email=#{CGI::escape @user}&Passwd=#{CGI::escape @pass}&service=youtube&source=#{CGI::escape @client_id}"
          logger.debug("auth body [#{body}]")
          response = http.post("/youtube/accounts/ClientLogin", body, "Content-Type" => "application/x-www-form-urlencoded")
          raise UploadError, response.body[/Error=(.+)/,1] if response.code.to_i != 200
          logger.debug("response.body [#{response.body}]")
          @auth_token = response.body[/Auth=(.+)/, 1]

        end
        logger.debug "auth_token [#{@auth_token}]"
        @auth_token
      end

      def video_xml #:nodoc:
        video_xml = ''
        video_xml << '<?xml version="1.0"?>'
        video_xml << '<entry xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:yt="http://gdata.youtube.com/schemas/2007">'
        video_xml << '<media:group>'
        video_xml << '<media:title type="plain">%s</media:title>'               % @opts[:title]
        video_xml << '<media:description type="plain">%s</media:description>'   % @opts[:description]
        video_xml << '<media:keywords>%s</media:keywords>'                      % @opts[:keywords].join(",")
        video_xml << '<media:category scheme="http://gdata.youtube.com/schemas/2007/categories.cat">%s</media:category>' % @opts[:category]
        video_xml << '<yt:private/>' if @opts[:private]
        video_xml << '</media:group>'
        video_xml << '</entry>'
      end

      def generate_upload_body(boundary, video_xml, data) #:nodoc:
        uploadBody = ""
        uploadBody << "--#{boundary}\r\n"
        uploadBody << "Content-Type: application/atom+xml; charset=UTF-8\r\n\r\n"
        uploadBody << video_xml
        uploadBody << "\r\n--#{boundary}\r\n"
        uploadBody << "Content-Type: #{@opts[:mime_type]}\r\nContent-Transfer-Encoding: binary\r\n\r\n"
        uploadBody << data
        uploadBody << "\r\n--#{boundary}--\r\n"
      end

    end
  end
end
