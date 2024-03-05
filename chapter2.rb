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
  gem 'cli-ui' # https://github.com/Shopify/cli-ui
end

require 'active_record'
require 'logger'
require 'sqlite3'
require 'colorize'
require 'cli/ui'

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
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
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

def seed_comments(count:)
  ActiveRecord::Base.logger = nil

  post_ids = Post.pluck(:id)
  user_ids = User.pluck(:id)
  (1..count).each do |i|
    post_id = post_ids.sample
    user_id = user_ids.sample
    comment = Comment.create(body: "Comment #{i}", post_id:, user_id:)
    Post.find(post_id).update(user_id:)
    CommentVote.create(comment_id: comment.id, voter_id: user_id)
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

seed_posts(count: 2)
seed_users(count: 2)
seed_comments(count: 10)

banner = <<~BANNER
  From page 27, add votes to comments. First without preloading
  which makes 27 queries,
BANNER
puts banner.red

Post.all.each do |post|
  puts
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Commenters: #{post.comments.map { |comment| comment.user.first_name }}"
  top_comment = post.comments.max_by { |comment| comment.votes.size }
  puts "Top comment: #{top_comment.body}"
  puts "Top comment votes: #{top_comment.votes.size}"
end

banner = <<~BANNER
  Now we'll preload the comments and votes. This will result in 4 queries.
BANNER
puts banner.yellow

posts = Post.limit(5).preload(comments: %i[user votes])
posts.each do |post|
  puts
  puts "Post: #{post.title}"
  puts "Comments count: #{post.comments.size}"
  puts "Commenters: #{post.comments.map { |comment| comment.user.first_name }}"
  top_comment = post.comments.max_by { |comment| comment.votes.size }
  puts "Top comment: #{top_comment.body}"
  puts "Top comment votes: #{top_comment.votes.size}"
end
