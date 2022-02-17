# frozen_string_literal: true

require 'attach/attachment'

module Attach
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      unless env['PATH_INFO'] =~ /\A\/attachment\/([a-f0-9\-]{36})\/(.*)/
        return @app.call(env)
      end

      attachment = Attach::Attachment.where(serve: true).find_by(token: Regexp.last_match(1))
      if attachment.nil?
        return [404, {}, ['Attachment not found']]
      end

      [200, headers_for_attachment(attachment), [attachment.binary]]
    end

    private

    def headers_for_attachment(attachment)
      max_age = attachment.cache_max_age || 30.days.to_i
      {
        'Content-Length' => attachment.file_size.to_s,
        'Content-Type' => attachment.file_type,
        'Cache-Control' => "#{attachment.cache_type || 'private'}, immutable, max-age=#{max_age}",
        'Content-Disposition' => "#{attachment.disposition || 'attachment'}; filename=\"#{attachment.file_name}\""
      }
    end

  end
end
