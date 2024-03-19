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
  gem 'dotenv' # https://github.com/bkeepers/dotenv
  gem 'pg_query'
  gem 'cli-ui' # https://github.com/Shopify/cli-ui
  gem 'ffaker'
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
  has_many :comment_votes, foreign_key: :voter_id
end

# Define post modela
class Post < ApplicationRecord
  # self.strict_loading_by_default = true
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
  has_many :comments

  has_many :popular_comments, -> { popular }, class_name: 'Comment'
  has_many :comment_voters_preloaded, -> { distinct }, through: :comments, source: :voters

  def comment_voters
    comments.preload(votes: :voter)
            .flat_map(&:votes)
            .flat_map(&:voter)
            .uniq
  end
end

# Define comment model
class Comment < ApplicationRecord
  POPULAR = 1 # 3 # Chnage the number depending on whwther scoped example is used.

  belongs_to :user
  belongs_to :post
  has_many :votes, class_name: 'CommentVote'
  has_many :voters, through: :votes

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

# Example from Page 44.
class Post::CommentVotersPreload # rubocop:disable Style/ClassAndModuleChildren
  def initialize(posts)
    @posts = posts
  end

  def for_post(post)
    comment_voters[post.id]
  end

  def comment_voters
    @comment_voters ||= fetch_records.group_by(&:post_id)
  end

  def fetch_records
    User.select('users.*, comments.post_id')
        .joins(comment_votes: [:comment])
        .where(comments: { post_id: @posts })
        .distinct
  end
end

def create_posts(count, &block)
  posts_data = count.times.map(&block)
  post_ids = Post.insert_all(posts_data, record_timestamps: true).map { |data| data["id"] }
  Post.where(id: post_ids)
end

def create_users(count, &block)
  users_data = count.times.map(&block)
  user_ids = User.insert_all(users_data, record_timestamps: true).map { |data| data["id"] }
  User.where(id: user_ids)
end

# What needs to be done here is range on count,
# then map with index for posts, then sample users
# to get from 1 to 5 comments per post.
def create_comments(posts, users, count, &block)
  comments_data = posts.flat_map { |post| count.times.map { block.(post) } }
  binding.irb
  Comment.insert_all(comments_data, record_timestamps: true)
end

posts = create_posts(100) do
  { title: FFaker::CheesyLingo.title, body: FFaker::CheesyLingo.paragraph }
end

users = create_users(100) do
  { first_name: FFaker::Name.first_name }
end

create_comments(posts, users, 1000) do |post, user|
  { post_id: post.id, user_id: user.id, body: FFaker::CheesyLingo.sentence, likes_count: rand(10) }
end


# Need to create CommentVoters:
# CommentVote.create(comment_id: comment.id, voter_id: user_id)
# This is not in the seeding code.



##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

def preload_object(*_args)
  banner = <<~BANNER
    Page 44, preload object, same SQL as custom query,
    with a service object to handle the preloading.
  BANNER
  puts banner.green

  posts = Post.limit(30)
  comment_voters = Post::CommentVotersPreload.new(posts)

  posts.each do |post|
    puts comment_voters.for_post(post).map(&:first_name)
  end
end

CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY
CLI::UI::Prompt.ask('Which scenario?') do |handler|
  handler.option('preloas object', &method(:preload_object))
end
