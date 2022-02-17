# frozen_string_literal: true

require 'spec_helper'
require 'attach/backends/file_system'

module Attach
  module Backends

    RSpec.describe FileSystem do
      subject(:backend) { described_class.new(root: File.expand_path('../../../tmp', __dir__)) }

      describe '#read' do
        it 'return a file blob' do
          attachment = create(:attachment, backend: backend, blob: BlobTypes::Raw.new('hello fs'))
          blob = backend.read(attachment)
          expect(blob).to be_a BlobTypes::File
          expect(blob.read).to eq 'hello fs'
        end
      end

      describe '#write' do
        it 'writes raw data to the disk' do
          attachment = create(:attachment, backend: backend, blob: BlobTypes::Raw.new('hello fs'))
          path = backend.write(attachment, BlobTypes::Raw.new('hello fs 2'))
          expect(File.file?(path)).to be true
          expect(File.read(path)).to eq 'hello fs 2'
        end

        it 'moves a file if given a file blob' do
          original_path = File.expand_path('../../../tmp/move-me', __dir__)
          File.write(original_path, 'new file to move')
          attachment = create(:attachment, backend: backend, blob: BlobTypes::Raw.new('hello fs'))
          path = backend.write(attachment, BlobTypes::File.new(File.new(original_path)))
          expect(File.file?(path)).to be true
          expect(File.read(path)).to eq 'new file to move'
          expect(File.file?(original_path)).to be false
        end
      end

      describe '#delete' do
        it 'removes the file from the disk' do
          attachment = create(:attachment, backend: backend, blob: BlobTypes::Raw.new('delete me'))
          path = backend.read(attachment).file.path
          expect(File.file?(path)).to be true
          backend.delete(attachment)
          expect(File.file?(path)).to be false
        end
      end
    end

  end
end
