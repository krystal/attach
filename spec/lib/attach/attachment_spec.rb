# frozen_string_literal: true

require 'spec_helper'

module Attach

  RSpec.describe Attachment, type: :model do
    subject { build(:attachment) }

    it { should belong_to :owner }
    it { should belong_to :parent }

    it { should validate_presence_of :file_name }
    it { should validate_presence_of :file_type }
    it { should validate_uniqueness_of(:token).case_insensitive }

    context 'when saving' do
      it 'generates a random token' do
        subject.save!
        expect(subject.token).to match(/\A[a-f0-9-]{36}\z/)
      end

      it 'calcuates the digest on save' do
        subject.save!
        expect(subject.digest).to eq 'd3486ae9136e7856bc42212385ea797094475802'
      end

      it 'adds the file size' do
        subject.save!
        expect(subject.file_size).to eq 12
      end

      it 'allows a blob to be set' do
        subject.blob = BlobTypes::Raw.new('Some other content')
        subject.save!
        expect(subject.blob.read).to eq 'Some other content'
        expect(subject.file_size).to eq 18
      end

      it 'writes the binary to the backend' do
        expect(Attach.backend).to receive(:write)
        subject.save!
      end

      it 'allows a local file to be provided' do
        subject.blob = BlobTypes::File.new(File.new(File.expand_path('../../../Gemfile', __dir__)))
        subject.save!
        expect(subject.blob.read).to match(/\A# frozen_string_literal/)
      end

      it 'removes all attachments of the same role with the parent' do
        subject.save!
        create(:attachment, owner: subject.owner)
        expect { subject.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'runs any processors dictated by the owner' do
        user = UserWithProcessor.create!
        attachment = create(:attachment, owner: user, role: 'photo')
        expect(attachment.custom['processor']).to eq '12345'
      end
    end

    describe '#blob' do
      it 'returns whatever was set as the blob' do
        subject.blob = BlobTypes::Raw.new('hello')
        expect(subject.blob.read).to eq 'hello'
      end

      it 'raises an error if the blob is not nil, or an accepted blob type' do
        expect { subject.blob = 'string' }.to raise_error ArgumentError
        expect { subject.blob = 1234 }.to raise_error ArgumentError
        expect { subject.blob = Tempfile.new }.to raise_error ArgumentError
        expect { subject.blob = nil }.to_not raise_error
        expect { subject.blob = BlobTypes::File.new(Tempfile.new) }.to_not raise_error
        expect { subject.blob = BlobTypes::Raw.new('Example') }.to_not raise_error
      end

      it 'returns nil if nothing has been set' do
        attachment = described_class.new
        expect(attachment.blob).to be nil
      end

      it 'reads the value of the binary from the backend if none exists' do
        subject.save
        new_subject = described_class.find(subject.id)
        expect(Attach.backend).to receive(:read).and_return(BlobTypes::Raw.new('From the backend'))
        expect(new_subject.blob.read).to eq 'From the backend'
      end
    end
  end

end
