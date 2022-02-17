# frozen_string_literal: true

require 'spec_helper'

module Attach

  RSpec.describe ModelExtension do
    context 'when an attachment has been defined on a model' do
      describe '.attachment' do
        it 'adds the has_many relationship' do
          expect(UserWithPhoto.reflect_on_all_associations(:has_many).map(&:name)).to include :attachments
        end

        it 'defines an instance method on the class' do
          expect(UserWithPhoto.new.respond_to?(:photo)).to be true
        end
      end

      describe '{attachment_name}' do
        it 'allows an attachment to be set and an attachment returned' do
          instance = UserWithPhoto.new
          instance.photo = 'hello'
          expect(instance.photo).to be_a Attach::Attachment
          expect(instance.photo.blob.read).to eq 'hello'
        end
      end

      describe '.includes_attachment' do
        it 'allows an attachment data to be preloaded' do
          user1 = UserWithPhoto.create!
          user2 = UserWithPhoto.create!
          user3 = UserWithPhoto.create!
          UserWithPhoto.create! # another user without an attachment
          create(:attachment, owner: user1)
          create(:attachment, owner: user2)
          create(:attachment, owner: user3)
          users = nil
          expect { users = UserWithPhoto.includes_attachment(:photo) }.to_not make_database_queries
          expect { users = users.to_a }.to make_database_queries(count: 2)
          expect { users.map(&:photo) }.to_not make_database_queries
        end

        it 'allows child attachments to be preloaded too' do
          user1 = UserWithPhoto.create!
          user2 = UserWithPhoto.create!
          user3 = UserWithPhoto.create!
          attachment1 = create(:attachment, owner: user1)
          create(:attachment, owner: user3, parent: attachment1, role: 'thumb500')
          attachment2 = create(:attachment, owner: user2)
          create(:attachment, owner: user3, parent: attachment2, role: 'thumb500')
          attachment3 = create(:attachment, owner: user3)
          create(:attachment, owner: user3, parent: attachment3, role: 'thumb500')
          users = nil
          expect { users = UserWithPhoto.includes_attachment(photo: :thumb500) }.to_not make_database_queries
          expect { users = users.to_a }.to make_database_queries(count: 3)
          expect { users.map(&:photo).map { |p| p.child(:thumb500) } }.to_not make_database_queries
        end
      end

      it 'saves the attachment' do
        instance = UserWithPhoto.new
        instance.photo = 'hello'
        expect(instance.save).to be true
        expect(instance.photo).to be_a Attach::Attachment
        expect(instance.photo).to be_persisted
      end

      it 'allows attachments to be deleted' do
        instance = UserWithPhoto.new
        instance.photo = 'hello'
        instance.save!
        attachment = instance.photo
        instance.photo_delete = 1
        instance.save!
        expect { attachment.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when an attachment has been defined with a validator' do
      it 'runs the validations when saving the model' do
        instance = UserWithValidatedPhoto.new
        instance.photo = 'invalid'
        expect(instance.valid?).to be false
        expect(instance.errors[:photo]).to eq ['is invalid']
      end
    end
  end

end
