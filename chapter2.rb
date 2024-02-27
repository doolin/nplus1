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

  has_many :comments
end

# Define comment model
class Comment < ApplicationRecord
  belongs_to :user
end

def seed_users(user_count:, comment_count:)
  (1..user_count).each do |i|
    user = User.create(first_name: "Name#{i}")
    (1..comment_count).each do |j|
      user.comments.create(body: "Comment #{j}")
    end
  end
end

def reset_tables
  ActiveRecord::Base.logger = nil
  Comment.delete_all
  Post.delete_all
  User.delete_all
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

##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

banner = <<~BANNER
  Preloading direct associations can be done with
  `preloads`, `includes`, or `eager_load`.
BANNER
puts banner.yellow

puts <<~HEREDOC
  \e[31mThe following will produce n+1. For 2 posts
  with 2 comments each, we get 5 db calls.\e[0m
HEREDOC
seed_posts(post_count: 2, comment_count: 2)
posts = Post.all
posts.each do |post|
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Comment sample: #{post.comments.sample.body}"
end

reset_tables

puts <<~HEREDOC
  \e[31mLet's do the same with preloads on the comment association,
  which results in 2 db calls instead of 5 as above.\e[0m
HEREDOC
seed_posts(post_count: 2, comment_count: 2)
posts = Post.all.preload(:comments)
puts posts.map { |post| post.comments.to_a }
posts.each do |post|
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Comment sample: #{post.comments.sample.body}"
end

reset_tables

puts <<~HEREDOC
  \e[31mLet's do the same with includes on the comment association,
  which results in 2 db calls instead of 5 as above.\e[0m
HEREDOC
seed_posts(post_count: 2, comment_count: 2)
posts = Post.all.includes(:comments)
puts posts.map { |post| post.comments.to_a }
posts.each do |post|
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Comment sample: #{post.comments.sample.body}"
end

reset_tables

puts <<~HEREDOC
  \e[31mLet's do the same with eager_load on the comment association,
  which results in 1 db call i with a LEFT OUTER JOIN.\e[0m
HEREDOC
seed_posts(post_count: 2, comment_count: 2)
posts = Post.all.eager_load(:comments)
puts posts.map { |post| post.comments.to_a }
posts.each do |post|
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Comment sample: #{post.comments.sample.body}"
end
