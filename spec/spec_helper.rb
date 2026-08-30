# frozen_string_literal: true

require 'logger'
require 'active_record'
require 'shoulda-matchers'
require 'factory_bot'
require 'db-query-matchers'
require 'database_cleaner/active_record'
require 'attach'
require 'attach/model_extension'
ActiveRecord::Base.include Attach::ModelExtension

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
migration_context_args = [File.expand_path('../db/migrate', __dir__)]
# Active Record < 7.1 needs the schema migration class; 7.1+ takes it from the connection
migration_context_args << ActiveRecord::SchemaMigration if ActiveRecord.version < Gem::Version.new('7.1')
ActiveRecord::MigrationContext.new(*migration_context_args).migrate(nil)
ActiveRecord::Migration.create_table :users do |t|
  t.string :name
  t.datetime :suspended_at
  t.timestamps null: false
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
    with.library :active_model
  end
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    FileUtils.rm_rf(File.expand_path('./tmp', __dir__))
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
