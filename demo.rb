#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'
require 'logger'
require 'sqlite3'
require 'query_count'

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
def seed_one_post
  post = Post.create(title: 'Example Post 1')
  id = post.id
  post.comments.create(body: 'This is a comment')
  post.comments.create(body: 'This is another comment')

  (1..10).each do |i|
    post.comments.create(body: "Comment #{i}")
  end

  id
end

def seed_two_posts
  count = 1
  post = Post.create(title: 'Example Post 1')
  # id = post.id
  # post.acomments.create(body: 'This is a comment')
  # post.comments.create(body: 'This is another comment')
  (0..count).each do |i|
    post.comments.create(body: "Comment #{i}")
  end

  post = Post.create(title: 'Example Post 2')
  (0..count).each do |i|
    post.comments.create(body: "Comment #{i}")
  end
end

def seed(post_count:, comment_count:)
  (1..post_count).each do |i|
    post = Post.create(title: "Example Post #{i}")
    (1..comment_count).each do |j|
      post.comments.create(body: "Comment #{j}")
    end
  end
end

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

def without_includes(post_id)
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

# This does not do n+1
# post_id = seed_one_post
# without_includes(post_id)

# post_id = seed_two_posts

seed(post_count: 1000, comment_count: 1)
ActiveRecord::Base.logger = Logger.new($stdout)
# Post.all.each do |post|
# QueryCount::Counter.reset_counter
#
# Run this ./demo > tmp/out.txt
# Check with grep "SELECT" tmp/out.txt | wc -l
Post.limit(1000).find_each do |post|
    post.comments.each do |comment|
    puts comment.body
  end
  # puts "Query count: #{QueryCount::Counter.counter}"
end
# puts "Query count: #{QueryCount::Counter.counter}"
