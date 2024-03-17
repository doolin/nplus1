#!/usr/bin/env ruby
# frozen_string_literal: true

# This file is specific to the following blog post:
# https://tadhao.medium.com/joins-vs-preload-vs-includes-vs-eager-load-in-rails-5f721c44b3a9

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

# TODO: copy the relevant bits here.
# require_relative 'setup'

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


# This seeding all comes from
# https://github.com/bhserna/specific_preloading_with_scoped_associations/blob/main/db/seeds.rb
def create_posts(count, &block)
  posts_data = count.times.map(&block)
  post_ids = Post.insert_all(posts_data, record_timestamps: true).map { |data| data["id"] }
  Post.where(id: post_ids)
end

def create_comments(posts, count, &block)
  comments_data = posts.flat_map { |post| count.times.map { block.(post) } }
  Comment.insert_all(comments_data, record_timestamps: true)
end

posts = create_posts(100) do
  { title: FFaker::CheesyLingo.title, body: FFaker::CheesyLingo.paragraph }
end

create_comments(posts, 1000) do |post|
  { post_id: post.id, body: FFaker::CheesyLingo.sentence, likes_count: rand(10) }
end
# end seeding

CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY
CLI::UI::Prompt.ask('Which scenario?') do |handler|
  handler.option('single post preloads votes and voters', &method(:post_preload_votes))
  handler.option('preload voters and count', &method(:preload_comment_voters))
  handler.option('eager load posts', &method(:eager_load_voters))
end
