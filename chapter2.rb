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

def seed_comments(count:) # rubocop:disable Metrics/MethodLength
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

# rubocop:disable Metrics/AbcSize
def print_posts(posts)
  posts.each do |post|
    puts "Post: #{post.title}"
    puts "Author: #{post.author.first_name}"
    puts "Comments: #{post.comments.map(&:body)}"
    puts "Comments count: #{post.comments.size}"
    puts "Commenters: #{post.comments.map { |comment| comment.user.first_name }}"
  end
end
# rubocop:enable Metrics/AbcSize

##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

seed_users_and_posts(user_count: 2, post_count: 2)
seed_comments(count: 20)

def post_preload_votes(*_args)
  banner = <<~BANNER
    Page 39, posts preload votes.
  BANNER
  puts banner.red

  post = Post.first
  puts post.comment_voters
end

def preload_comment_voters(*_args)
  banner = <<~BANNER
    Page 42, this should preload comment voters.
    This matches what is shown in the book.
  BANNER
  puts banner.green

  Post.preload(:comment_voters_preloaded).to_a.count
end

def eager_load_voters(*_args)
  banner = <<~BANNER
    Page 42, demo for eager load.
  BANNER
  puts banner.green

  # puts Post.all.each(&:comment_voters_preloaded)
  Post.eager_load(:comment_voters_preloaded).to_a
end

def custom_query(*_args)
  banner = <<~BANNER
    Page 43, custom query, resulting SQL:
      SELECT DISTINCT users.*, comments.post_id
      FROM "users"
      INNER JOIN "comment_votes" ON "comment_votes"."voter_id" = "users"."id"
      INNER JOIN "comments" ON "comments"."id" = "comment_votes"."comment_id"
      WHERE "comments"."post_id"
      IN (
        SELECT "posts"."id" FROM "posts" LIMIT ?
      )  [["LIMIT", 30]]
  BANNER
  puts banner.green

  posts = Post.limit(30)
  comment_voters = User
                   .select('users.*, comments.post_id') # selects the user attributes and the post_id of the comment.
                   .joins(comment_votes: [:comment])
                   .distinct
                   .where(comments: { post_id: posts })
                   .to_a

  puts comment_voters
end

def pick_voters_by_post(*_args)
  banner = <<~BANNER
    Page 43, pick voters by post, which makes two calls. The first is the same as
    the custom query, the second is to post, which is similar to what's in the IN
    clause of the custom query:
      SELECT "posts".* FROM "posts" LIMIT ?  [["LIMIT", 30]]
  BANNER
  puts banner.green

  posts = Post.limit(30)
  comment_voters = User
                   .select('users.*, comments.post_id') # selects the user attributes and the post_id of the comment.
                   .joins(comment_votes: [:comment])
                   .where(comments: { post_id: posts })
                   .distinct
                   .group_by(&:post_id)

  posts.each do |post|
    puts comment_voters[post.id].map(&:first_name)
  end
end

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
  handler.option('single post preloads votes and voters', &method(:post_preload_votes))
  handler.option('preload voters and count', &method(:preload_comment_voters))
  handler.option('eager load posts', &method(:eager_load_voters))
  handler.option('custom query', &method(:custom_query))
  handler.option('pick_voters_by_posts', &method(:pick_voters_by_post))
  handler.option('preloas object', &method(:preload_object))
end
