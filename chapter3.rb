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

def create_posts(_users, count, &)
  posts_data = count.times.map(&)
  post_ids = Post.insert_all(posts_data, record_timestamps: true).map { |data| data['id'] }
  Post.where(id: post_ids)
end

def create_users(count, &)
  users_data = count.times.map(&)
  user_ids = User.insert_all(users_data, record_timestamps: true).map { |data| data['id'] }
  User.where(id: user_ids)
end

def create_comments(posts, _users, count, &block)
  user_id = rand(1..100)
  # TODO: This is creating 1000 comments at the moment, too many.
  comments_data = posts.flat_map { |post| count.times.map { block.call(post, user_id) } }
  Comment.insert_all(comments_data, record_timestamps: true)
end

users = create_users(100) do
  { first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name }
end

posts = create_posts(users, 100) do
  { title: FFaker::CheesyLingo.title, body: FFaker::CheesyLingo.paragraph, user_id: users.sample.id }
end

create_comments(posts, users, 1000) do |post, user_id|
  { post_id: post.id, user_id:, body: FFaker::CheesyLingo.sentence, likes_count: rand(10) }
end

def create_comment_votes(count)
  data = (1..count).to_a.map do
    {
      comment_id: rand(1..100),
      voter_id: rand(1..100)
    }
  end
  CommentVote.insert_all(data, record_timestamps: true)
end

create_comment_votes(100)

##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

def preload_object(*_args)
  banner = <<~BANNER
    Page 44, preload object, same SQL as custom query,
    with a service object to handle the preloading.
  BANNER
  puts banner.green

  # Somewhere below this line, something is not working.
  # It looks like all the CommentVotes are on a single post,
  # which is wrong, they should be randomly distributed.
  # binding.irb

  posts = Post.limit(2)
  # TODO: fix this such that it only works with posts which
  # have comments, and maybe with comments that have votes.
  comment_voters = Post::CommentVotersPreload.new(posts)

  # binding.irb

  posts.each_with_index do |post, i|
    puts "Post id: #{post.id}, index: #{i + 1}: #{post.title}"
    # binding.irb
    puts comment_voters.for_post(post)&.map(&:first_name)
  end
end

ActiveRecord::Base.logger = Logger.new($stdout)

def comments_count(*_args) # rubocop:disable Metrics/MethodLength
  banner = <<~BANNER
    Count always calls.
  BANNER
  puts banner.green

  puts 'Press Enter to load post...'.green
  gets
  post = Post.first
  puts 'Press Enter for first call to count...'.green
  gets
  puts post.comments.count
  puts 'Press Enter for second call to count...'.green
  gets
  puts post.comments.count

  puts 'Press Enter to load comments...'.green
  gets
  post.comments.load
  puts 'count always performs an SQL COUNT query:'.red
  puts 'Press Enter'.green
  gets
  puts post.comments.count
end

def comments_length(*_args) # rubocop:disable Metrics/MethodLength
  banner = <<~BANNER
    Length always calls.
  BANNER
  puts banner.green

  puts 'Press Enter to load post...'.green
  gets
  post = Post.first
  puts 'Press Enter for first call to post.comments.length, which has a SQL call.'.green
  gets
  puts post.comments.length
  puts "Press Enter for second call to post.comments.length.\nThere is no SQL call".green
  gets
  puts post.comments.length
end

CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY
CLI::UI::Prompt.ask('Which scenario?') do |handler|
  handler.option('comments length', &method(:comments_length))
  handler.option('comments count', &method(:comments_count))
  handler.option('preloas object', &method(:preload_object))
end
