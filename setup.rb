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

  create_table :users do |table|
    table.column :first_name, :string
    table.column :last_name, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end

  create_table :comments do |table|
    table.column :post_id, :integer
    table.column :user_id, :integer
    table.column :body, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end

  create_table :comment_votes do |table|
    table.column :comment_id, :integer
    table.column :voter_id, :integer
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end
end

# Make rubocop happy
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

def reset_tables
  ActiveRecord::Base.logger = nil
  Comment.delete_all
  Post.delete_all
  User.delete_all
  CommentVote.delete_all
  ActiveRecord::Base.logger = Logger.new($stdout)
end

def seed_posts(post_count:, comment_count:)
  ActiveRecord::Base.logger = nil
  (1..post_count).each do |i|
    post = Post.create(title: "Post #{i}")
    (1..comment_count).each do |j|
      post.comments.create(body: "Comment #{j}")
    end
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

def seed_users(user_count:, comment_count:)
  (1..user_count).each do |i|
    user = User.create(first_name: "Name#{i}")
    (1..comment_count).each do |j|
      user.comments.create(body: "Comment #{j}")
    end
  end
end
