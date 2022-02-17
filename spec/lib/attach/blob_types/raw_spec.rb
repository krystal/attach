# frozen_string_literal: true

require 'spec_helper'

module Attach
  module BlobTypes

    RSpec.describe Raw do
      subject(:raw) { Raw.new('Hello world!') }

      describe '#read' do
        it 'returns the contents of the data on each call' do
          expect(raw.read).to eq 'Hello world!'
        end
      end

      describe '#size' do
        it 'returns the size of the raw' do
          expect(raw.size).to eq 12
        end
      end

      describe '#digest' do
        it 'calculates the SHA1 digest of the raw' do
          expect(raw.digest).to eq 'd3486ae9136e7856bc42212385ea797094475802'
        end
      end
    end

  end
end
