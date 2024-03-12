#!/usr/bin/env ruby
# frozen_string_literal: true

# See also https://github.com/bhserna/specific_preloading_with_scoped_associations

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

  has_many :posts
  has_many :comments
end

# Define post modela
class Post < ApplicationRecord
  # self.strict_loading_by_default = true
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
  has_many :comments

  has_many :popular_comments, -> { popular }, class_name: "Comment"
end

# Define comment model
class Comment < ApplicationRecord
  POPULAR = 1 # 3 # Chnage the number depending on whwther scoped example is used.

  belongs_to :user
  belongs_to :post
  has_many :votes, class_name: 'CommentVote'

  scope :popular, -> { where(likes_count: POPULAR..) }

  def popular?
    votes.count >= POPULAR
  end
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
    likes_count = rand(0..5)
    comment = Comment.create(body: "Comment #{i}", post_id:, user_id:, likes_count:)
    CommentVote.create(comment_id: comment.id, voter_id: user_id)
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

seed_users_and_posts(user_count: 2, post_count: 2)
seed_comments(count: 20)

def print_posts(posts)
  posts.each do |post|
    puts
    puts "Post: #{post.title}"
    puts "Author: #{post.author.first_name}"
    puts "Comments: #{post.comments.map(&:body)}"
    puts "Comments count: #{post.comments.size}"
    puts "Commenters: #{post.comments.map { |comment| comment.user.first_name }}"
  end
end

def without_scopes(*args)
  banner = <<~BANNER
    TPage 35: his example does not use scopes and filters the results in Ruby.
    The CommentVotes are not preloaded, inducing n + 1.

    This is not what the book is asking for, and there is an open thread
    here on how to preload the CommentVotes.
  BANNER
  puts banner.red

  posts = Post.preload(:comments).limit(1)

  posts.each do |post|
    puts "Post: #{post.title}"
    popular_comments = post.comments.select(&:popular?)
    popular_comments.each do |comment|
      puts "Comment: #{comment.body}, votes count: #{comment.votes.count}"
    end
  end
end

def with_scopes(*args)
  banner = <<~BANNER
    Page 36: using a scope to filter the comments. No join table
    for counring votes, added a likes_count column to the comments.
  BANNER
  puts banner.yellow

  posts = Post.preload(:popular_comments).limit(1)
  posts.each do |post|
    puts "Post: #{post.title}"
    post.popular_comments.each do |comment|
      puts "Comment: #{comment.body}, likes count: #{comment.likes_count}"
    end
  end
end

CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY
CLI::UI::Prompt.ask('What language/framework do you use?') do |handler|
  handler.option('with scopes', &method(:with_scopes))
  handler.option('without scopes', &method(:without_scopes))
end
