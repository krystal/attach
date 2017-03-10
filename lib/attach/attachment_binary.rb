require 'securerandom'
require 'digest/sha1'

module Attach
  class AttachmentBinary < ActiveRecord::Base

    # Set the table name
    self.table_name = 'attachment_binaries'

  end
end
