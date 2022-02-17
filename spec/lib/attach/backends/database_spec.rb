# frozen_string_literal: true

require 'spec_helper'
require 'attach/backends/database'

module Attach
  module Backends

    RSpec.describe Database do
      subject(:backend) { described_class.new({}) }

      describe '#read' do
        it 'returns a raw blob with the data stored in the database' do
          attachment = create(:attachment)
          AttachmentBinary.destroy_all
          create(:attachment_binary, data: 'Hello binary!', attachment: attachment)
          blob = backend.read(attachment)
          expect(blob).to be_a BlobTypes::Raw
          expect(blob.read).to eq 'Hello binary!'
        end
      end

      describe '#write' do
        it 'writes a new binary object in the database' do
          attachment = create(:attachment)
          AttachmentBinary.destroy_all
          backend.write(attachment, BlobTypes::Raw.new('New file'))
          expect(AttachmentBinary.first.data).to eq 'New file'
        end

        it 'updates an existing object if it exists' do
          attachment = create(:attachment)
          backend.write(attachment, BlobTypes::Raw.new('New data'))
          expect(AttachmentBinary.first.data).to eq 'New data'
        end
      end

      describe '#delete' do
        it 'removes the binary from the database' do
          attachment = create(:attachment)
          backend.delete(attachment)
          expect(AttachmentBinary.count).to eq 0
        end
      end
    end

  end
end
