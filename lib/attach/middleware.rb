require 'attach/attachment'

module Attach
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      if env['PATH_INFO'] =~ /\A\/attachment\/([a-f0-9\-]{36})\/(.*)/
        if attachment = Attach::Attachment.where(:serve => true).find_by_token($1)
          [200, {
            'Content-Length' => attachment.file_size.to_s,
            'Content-Type' => attachment.file_type,
            'Cache-Control' => "#{attachment.cache_type || 'private'}, immutable, maxage=#{attachment.cache_max_age || 30.days.to_i}",
            'Content-Disposition' => "#{attachment.disposition || 'attachment'}; filename=\"#{attachment.file_name}\","
            },
          [attachment.binary]]
        else
          [404, {}, ["Attachment not found"]]
        end
      else
        @app.call(env)
      end
    end

  end
end
