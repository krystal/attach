# frozen_string_literal: true

module Attach
  class AttachmentBinary < ActiveRecord::Base

    self.table_name = 'attachment_binaries'

    belongs_to :attachment

  end
end
