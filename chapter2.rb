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
  Preloading belongs_to associations can be done with
  `preloads`, `includes`, or `eager_load`.
BANNER
puts banner.yellow





banner = <<~BANNER
  The following will produce n+1. For 2 posts
  with 2 comments each, we get 5 db calls.
BANNER
puts banner.red
seed_posts_and_comments(post_count: 2, comment_count: 2)
comments = Comment.all
comments.each do |comment|
  puts "Comment: #{comment.body}"
  puts "Post: #{comment.post.title}"
end

reset_tables

banner = <<~BANNER
  Let's do the same with preloads on the comment association,
  which results in 2 db calls instead of 5 as above.
BANNER
puts banner.red
seed_posts_and_comments(post_count: 2, comment_count: 2)
comments = Comment.preload(:post)
puts(comments.map { |comment| comment.post })
comments.each do |comment|
  puts "#{comment.body}, #{comment.post.title}"
end

reset_tables

banner = <<~BANNER
  Let's do the same with includes on the comment association,
  which results in 2 db calls instead of 5 as above.
BANNER
puts banner.red
seed_posts_and_comments(post_count: 2, comment_count: 2)
comments = Comment.includes(:post)
comments.each do |comment|
  puts "#{comment.body}, #{comment.post.title}"
end

reset_tables

banner = <<~BANNER
  \e[31mLet's do the same with eager_load on the comment association,
  which results in 1 db call i with a LEFT OUTER JOIN.\e[0m
BANNER
puts banner.red
seed_posts_and_comments(post_count: 2, comment_count: 2)
comments = Comment.eager_load(:post)
comments.each do |comment|
  puts "#{comment.body}, #{comment.post.title}"
end
