#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

# From https://greg.molnar.io/blog/a-single-file-rails-application/
# Necessary for single file Rails application, not sure how I want
# to handle this yet.
gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
  gem 'sqlite3'
  gem 'colorize'
  gem 'pg_query'
end

require 'active_record'
require 'logger'
require 'sqlite3'
require 'colorize'
# puts <<~HEREDOC
#   \e[31mThis text is red.\e[0m
#   \e[32mThis text is green.\e[0m
#   \e[33mThis text is yellow.\e[0m
#   \e[34mThis text is blue.\e[0m
# HEREDOC

require_relative 'setup'

# Define user modela
class User < ApplicationRecord
  # self.strict_loading_by_default = true

  has_many :comments
end

# Define post modela
class Post < ApplicationRecord
  # self.strict_loading_by_default = true
  belongs_to :author, class_name: 'User'
  has_many :comments
end

# Define comment model
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :votes, class_name: 'CommentVote'
end

# Define comment vote model
class CommentVote < ApplicationRecord
  belongs_to :voter, class_name: 'User'
  belongs_to :comment
end

##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

banner = <<~BANNER
  From page 25: "Imagine that you want to be able to show a
  list of posts with its comments count and the names of
  all of its commenters."

  That is, we want to be able to handle nested associations.
BANNER
puts banner.yellow

def seed_comments(count:)
  ActiveRecord::Base.logger = nil

  post_ids = Post.pluck(:id)
  user_ids = User.pluck(:id)
  (1..count).each do |i|
    Comment.create(body: "Comment #{i}", post_id: post_ids.sample, user_id: user_ids.sample)
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

banner = <<~BANNER
  The first example is showing the queries when not preloading.
  We'll use 2 posts and 2 users, then 15 comments and randomly assign.
  This will result in 20 queries.
BANNER
puts banner.red

seed_posts(count: 2)
seed_users(count: 2)
seed_comments(count: 15)


Post.all.each do |post|
  puts
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Commenters: #{post.comments.map { |comment| comment.user.first_name }}"
end

banner = <<~BANNER
  The next example is showing the queries when preloading.
  We'll use 2 posts and 2 users, then 15 comments and randomly assign.
  This will result in 3 queries.
BANNER
puts banner.yellow

posts = Post.limit(5).preload(comments: :user)
posts.each do |post|
  puts
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Commenters: #{post.comments.map { |comment| comment.user.first_name }}"
end
