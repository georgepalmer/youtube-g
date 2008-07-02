require 'net/https'
require 'digest/md5'
require 'rexml/document'
require 'cgi'

class YouTubeG

  module Upload
    class UploadError < Exception; end

    # require 'youtube_g'
    #
    # uploader = YouTubeG::Upload::VideoUpload.new("user", "pass", "dev-key")
    # uploader.upload File.open("test.m4v"), :title => 'test',
    #                                        :description => 'cool vid d00d',
    #                                        :category => 'People',
    #                                        :keywords => %w[cool blah test]

    class VideoUpload

      def initialize user, pass, dev_key, client_id = 'youtube_g'
        @user, @pass, @dev_key, @client_id = user, pass, dev_key, client_id
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
      #

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
        "Authorization"  => "GoogleLogin auth=#{auth_token}",
        "X-GData-Client" => "#{@client_id}",
        "X-GData-Key"    => "key=#{@dev_key}",
        "Slug"           => "#{@opts[:filename]}",
        "Content-Type"   => "multipart/related; boundary=#{boundary}",
        "Content-Length" => "#{upload_body.length}",
        }
        puts("MSP upload_header [#{upload_header}]")

        direct_upload_url = "/feeds/api/users/#{@user}/uploads"
        puts("MSP direct_upload_url [#{direct_upload_url}]")

        Net::HTTP.start(base_url) do |upload|
          response = upload.post(direct_upload_url, upload_body, upload_header)
          xml = REXML::Document.new(response.body)
          if (xml.elements["//id"])
            puts("MSP response xml [#{xml}]")
            return xml.elements["//id"].text[/videos\/(.+)/, 1]
          else
            return xml
          end


        end

      end

      private

      def base_url
        "uploads.gdata.youtube.com"
      end

      def boundary
        "An43094fu"
      end

      def auth_token
        unless @auth_token
          http = Net::HTTP.new("www.google.com", 443)
          http.use_ssl = true
          body = "Email=#{CGI::escape @user}&Passwd=#{CGI::escape @pass}&service=youtube&source=#{CGI::escape @client_id}"
          puts("MSP auth body [#{body}]")
          response = http.post("/youtube/accounts/ClientLogin", body, "Content-Type" => "application/x-www-form-urlencoded")
          raise UploadError, "MSP "+response.body[/Error=(.+)/,1] if response.code.to_i != 200
          puts("MSP response.body [#{response.body}]")
          @auth_token = response.body[/Auth=(.+)/, 1]

        end
        puts "MSP auth_token [#{@auth_token}]"
        @auth_token
      end

      def video_xml
        %[<?xml version="1.0"?>
           <entry xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:yt="http://gdata.youtube.com/schemas/2007">
           <media:group>
           <media:title type="plain">#{@opts[:title]}</media:title>
           <media:description type="plain">#{@opts[:description]}</media:description>
           <media:category scheme="http://gdata.youtube.com/schemas/2007/categories.cat">#{@opts[:category]}</media:category>
           <media:keywords>#{@opts[:keywords].join ","}</media:keywords>
           </media:group></entry> ]
      end

      def generate_upload_body(boundary, video_xml, data)
        upload_body = ""
        upload_body << "--#{boundary}\r\n"
        upload_body << "Content-Type: application/atom+xml; charset=UTF-8\r\n\r\n"
        upload_body << video_xml
        upload_body << "\r\n--#{boundary}\r\n"
        upload_body << "Content-Type: #{@opts[:mime_type]}\r\nContent-Transfer-Encoding: binary\r\n\r\n"
        upload_body << data
        upload_body << "\r\n--#{boundary}--\r\n"
      end

    end
  end
end