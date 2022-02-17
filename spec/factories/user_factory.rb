# frozen_string_literal: true

class User < ActiveRecord::Base

  attachment :avatar

end

class UserWithPhoto < ActiveRecord::Base

  self.table_name = 'users'

  attachment :photo

end

class UserWithValidatedPhoto < ActiveRecord::Base

  self.table_name = 'users'

  attachment :photo do
    validator do |attachment, errors|
      errors.add :photo, 'is invalid' if attachment.blob.read == 'invalid'
    end
  end

end

class UserWithProcessor < ActiveRecord::Base

  self.table_name = 'users'

  attachment :photo do
    processor do |attachment|
      attachment.custom['processor'] = '12345'
    end
  end

end

FactoryBot.define do
  factory :user, class: User do
    name { 'Joe Smith' }
  end
end
