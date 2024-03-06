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

def print_posts(posts)
  posts.each do |post|
    puts
    puts "Post: #{post.title}"
    puts "Comments count: #{post.comments.size}"
    puts "Commenters: #{post.comments.map { |comment| comment.user.first_name }}"
    top_comment = post.comments.sort_by { |comment| comment.votes.size }.last
    puts "Top comment: #{top_comment.body}"
    puts "Top comment votes: #{top_comment.votes.size}"
    puts "Top comment voters: #{top_comment.votes.map { |vote| vote.voter.first_name }}"
  end
end

banner = <<~BANNER
  From page 28, using Post.all results in 28 queries.
BANNER
puts banner.red
posts = Post.all
print_posts(posts)

BANNER = <<~BANNER
  Now we'll use Post.limit(5).preload(comments: [:user, votes: [:voter]]).
  This will result in 4 queries.
BANNER
puts BANNER.yellow
posts = Post.limit(5).preload(comments: [:user, votes: [:voter]])
print_posts(posts)
