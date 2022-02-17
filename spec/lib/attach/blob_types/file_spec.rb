# frozen_string_literal: true

require 'spec_helper'

module Attach
  module BlobTypes

    RSpec.describe File do
      subject(:file) { File.new(::File.new(::File.expand_path('../../../fixtures/file.txt', __dir__))) }

      describe '#read' do
        it 'returns the contents of the file on each call' do
          expect(file.read).to match(/\AHello world!/)
        end
      end

      describe '#size' do
        it 'returns the size of the file' do
          expect(file.size).to eq 73
        end
      end

      describe '#digest' do
        it 'calculates the SHA1 digest of the file' do
          expect(file.digest).to eq 'c8a083b737668ce12694d46ad6fefe91f4fe2f41'
        end
      end

      describe '#file' do
        it 'returns the underlying file object' do
          expect(file.file).to be_a ::File
        end
      end
    end

  end
end
