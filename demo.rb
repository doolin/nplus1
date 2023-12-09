#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'
require 'logger'
require 'sqlite3'

# Something to note: ActiveRecord is typically used to
# retrieve whole objects, not just attributes. This is
# because it is an ORM (Object Relational Mapper).
# This is not always efficient.

# Database Setup
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = Logger::INFO  # Or another level, like Logger::WARN

# Define Schema
ActiveRecord::Schema.define do
  create_table :posts do |table|
    table.column :title, :string
  end

  create_table :comments do |table|
    table.column :post_id, :integer
    table.column :body, :string
  end
end

# Make rubocop happy
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

# Define post model
class Post < ApplicationRecord
  has_many :comments
end

# Define comment model
class Comment < ApplicationRecord
  belongs_to :post
end

# Seeding Data
post = Post.create(title: 'Example Post')
post.comments.create(body: 'This is a comment')
post.comments.create(body: 'This is another comment')

(1..10).each do |i|
  post.comments.create(body: "Comment #{i}")
end

ActiveRecord::Base.logger = Logger.new($stdout)

def with_includes
  # Querying Data

  post_id = post.id # Use the ID of the post you want to retrieve

  # This is 2 database calls.
  # queried_post = Post.includes(:comments).find(post_id)

  queried_post = Post.eager_load(:comments).find(post_id)

  # binding.irb

  # This doesn't work because the comments are not preloaded.
  # queried_post = Post.find(post_id).includes(:comments)

  puts "Post: #{queried_post.title}"
  queried_post.comments.each do |comment|
    puts " - Comment: #{comment.body}"
  end
rescue ActiveRecord::RecordNotFound
  puts "Post with id #{post_id} not found."
end

def without_includes(post)
  # Querying Data

  post_id = post.id # Use the ID of the post you want to retrieve

  queried_post = Post.find(post_id)

  # binding.irb

  # This doesn't work because the comments are not preloaded.
  # queried_post = Post.find(post_id)

  puts "Post: #{queried_post.title}"
  queried_post.comments.each do |comment|
    puts " - Comment: #{comment.body}"
  end
rescue ActiveRecord::RecordNotFound
  puts "Post with id #{post_id} not found."
end

without_includes(post)
