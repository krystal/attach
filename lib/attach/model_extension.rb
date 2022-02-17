# frozen_string_literal: true

require 'attach/model_extension/class_methods'
require 'attach/model_extension/instance_methods'

module Attach
  module ModelExtension

    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      include InstanceMethods
    end

  end
end
