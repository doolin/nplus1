#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'
require 'logger'
require 'sqlite3'
require 'query_count'

require_relative 'setup'

# Define post model
class Post < ApplicationRecord
  has_many :comments

  def latest_comment
    # sort_by will sort in ruby, uses memory instead of database calls.
    comments.sort_by(&:created_at).last
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

# Page 7, sorting in Ruby
seed(post_count: 1, comment_count: 1)
ActiveRecord::Base.logger = Logger.new($stdout)
Post.includes(:comments).find_each do |post|
  puts post.latest_comment
end
