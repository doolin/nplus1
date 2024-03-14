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

##### Everything above this line should carry forward
##### from page to page. Below is where changes are made
##### to follow along with the book.

seed_users_and_posts(user_count: 2, post_count: 2)
seed_comments(count: 20)

def single_post(*_args)
  banner = <<~BANNER
    Page 38 Simplify preloading with has many through
    associations. In this case using a single post does
    not induce n+1 on the associations.
  BANNER
  puts banner.red

  post = Post.first
  puts post.comment_voters
end

def list_of_posts(*_args)
  banner = <<~BANNER
    Page 39 for a list of posts, n+1 is induced on the
    query. This makes 13 calls with our current setup.
  BANNER
  puts banner.red

  puts Post.all.each(&:comment_voters)
end

def posts_has_many(*_args)
  banner = <<~BANNER
    Page 39 I'm not seeing any gain here, and don't know
    if the 15 calls I'm seeing are correct.
  BANNER
  puts banner.red

  # puts Post.all.each(&:comment_voters_preloaded)
  Post.preload(:comment_voters_preloaded).each do |post|
    puts post.comment_voters.to_a
  end
end

CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY
CLI::UI::Prompt.ask('Which scenario?') do |handler|
  handler.option('single post', &method(:single_post))
  handler.option('list of posts', &method(:list_of_posts))
  handler.option('posts with has many through', &method(:posts_has_many))
end
