# frozen_string_literal: true

module Attach
  class Railtie < Rails::Engine # :nodoc:

    engine_name 'attach'

    initializer 'attach.initialize' do |app|
      require 'attach/middleware'
      app.config.middleware.use Attach::Middleware

      ActiveSupport.on_load(:active_record) do
        require 'attach/model_extension'
        ::ActiveRecord::Base.include Attach::ModelExtension
      end
    end

  end
end
