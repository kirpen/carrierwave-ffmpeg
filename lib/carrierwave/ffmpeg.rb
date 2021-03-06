require 'carrierwave'
require 'streamio-ffmpeg'

module CarrierWave
  module FFmpeg
    module ClassMethods
      def encode format, opts = {}
        process encode: [ format, opts ]
      end

      def movie path
        ::FFMPEG::Movie.new path
      end
    end

    def encode format, opts = {}
      tmp_path = File.join File.dirname(current_path), "tmp_file.#{format}"
      file = movie current_path
      file.transcode tmp_path, options(format, file, opts), transcoder_options
      connection do |sftp|
#         sftp.mkdir_p!(::File.dirname(full_path))
        sftp.upload!(file.path, full_path)
      end
#       File.rename tmp_path, full_path
    end

    def codec format
      case format
      when :mp4
        { video_codec: 'libx264',   
          audio_codec: 'aac' }
      when :webm
        { video_codec: 'libvpx',    
          audio_codec: 'libvorbis' }
      when :ogv
        { video_codec: 'libtheora', 
          audio_codec: 'libvorbis' }
      else
        raise CarrierWave::ProcessingError.new("Unsupported video format. Error: #{e}")
      end
    end

    def options format, file, opts = {}
      opts[:resolution]    = file.resolution unless opts[:resolution]
      opts[:video_bitrate] = file.bitrate unless opts[:video_bitrate]
      opts[:video_bitrate_tolerance] = (opts[:video_bitrate].to_i / 10).to_i
      opts[:threads] = 6 unless opts[:threads]
      opts.merge!(codec(format))
    end

    def transcoder_options 
      { preserve_aspect_ratio: :height }
    end

    def movie path
      ::FFMPEG::Movie.new path
    end
    
    def full_path
      "#{@uploader.sftp_folder}/#{path}"
    end

    
    def connection
      sftp = Net::SFTP.start(
        @uploader.sftp_host,
        @uploader.sftp_user,
        @uploader.sftp_options
      )
      yield sftp
      sftp.close_channel
    end
    
  end
end
