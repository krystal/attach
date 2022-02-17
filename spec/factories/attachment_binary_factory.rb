# frozen_string_literal: true

FactoryBot.define do
  factory :attachment_binary, class: 'Attach::AttachmentBinary' do
    association :attachment
    data { 'My binary!' }
  end
end
