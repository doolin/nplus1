#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'
require 'logger'
require 'sqlite3'
require 'query_count'

require_relative 'setup'

# Something to note: ActiveRecord is typically used to
# retrieve whole objects, not just attributes. This is
# because it is an ORM (Object Relational Mapper).
# This is not always efficient.

# Define post model
class Post < ApplicationRecord
  has_many :comments

  def latest_comment
    comments.order(:created_at).last
  end
end

# Define comment model
class Comment < ApplicationRecord
  belongs_to :post
end

def seed(post_count:, comment_count:)
  (1..post_count).each do |i|
    post = Post.create(title: "Example Post #{i}")
    (1..comment_count).each do |j|
      post.comments.create(body: "Comment #{j}")
    end
  end
end

# Page 4-6.
seed(post_count: 1, comment_count: 1)
ActiveRecord::Base.logger = Logger.new($stdout)
# The `includes` is ignored here.
Post.includes(:comments).find_each do |post|
  # But here rails will "ignore" your includes and run a query
  # for each post (n+1 queries). The overall result is n+2 queries.
  puts post.latest_comment
end
