# frozen_string_literal: true

# Database Setup
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = Logger::INFO  # Or another level, like Logger::WARN

# Define Schema
ActiveRecord::Schema.define do
  create_table :posts do |table|
    table.column :title, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end

  create_table :comments do |table|
    table.column :post_id, :integer
    table.column :body, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end
end

# Make rubocop happy
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
