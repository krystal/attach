# frozen_string_literal: true

FactoryBot.define do
  factory :attachment, class: 'Attach::Attachment' do
    association :owner, factory: :user
    file_name { 'example.txt' }
    file_type { 'text/plain' }
    role { 'photo' }
    blob { Attach::BlobTypes::Raw.new('Hello world!') }
  end
end
