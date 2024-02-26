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

def seed(user_count:, comment_count:)
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

banner = <<~BANNER
  Joins by themselves do not preload. By itself it
  does an inner join.
BANNER
puts banner.yellow

# puts <<~HEREDOC
#   \e[31mThis text is red.\e[0m
#   \e[32mThis text is green.\e[0m
#   \e[33mThis text is yellow.\e[0m
#   \e[34mThis text is blue.\e[0m
# HEREDOC

puts <<~HEREDOC
  \e[31mWith 1 Post and 2 comments, we make 3 calls to the database.
  The first call is to get the posts, the second call is to get
  the first comment, and the third call is to get the second comment.\e[0m
HEREDOC
seed_posts(post_count: 1, comment_count: 2)
posts = Post.joins(:comments)
puts posts.map(&:comments).to_a

reset_tables

puts <<~HEREDOC
  \e[31mWith 2 posts each match with 1 comment matching the
  where condition, we still get 3 calls.\e[0m
HEREDOC
seed_posts(post_count: 2, comment_count: 1)
posts = Post.joins(:comments).where('comments.body = ?', 'Comment 1')
puts posts.map(&:comments).to_a

reset_tables

puts <<~HEREDOC
  \e[31mWith 2 posts each with 1 comment
  and preloaded, we get 2 calls.\e[0m
HEREDOC
seed_posts(post_count: 2, comment_count: 1)
posts = Post.joins(:comments).preload(:comments)
puts posts.map(&:comments).to_a

reset_tables

puts <<~HEREDOC
  \e[31mWith 2 posts each match with 1 comment matching the where
  where condition, with preloading we get 2 calls.\e[0m
HEREDOC
seed_posts(post_count: 2, comment_count: 1)
posts = Post.joins(:comments).where('comments.body = ?', 'Comment 1').preload(:comments)
puts posts.map(&:comments).to_a
