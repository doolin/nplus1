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
  gem 'pg'
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
  # Will do n+1 if the counter cache is not defined.
  has_many :likes # , counter_cache: :likes_total

  has_many :popular_comments, -> { popular }, class_name: 'Comment'
  has_many :comment_voters_preloaded, -> { distinct }, through: :comments, source: :voters

  def comment_voters
    comments.preload(votes: :voter)
            .flat_map(&:votes)
            .flat_map(&:voter)
            .uniq
  end
end

# An anonymous like for posts.
class Like < ApplicationRecord
  belongs_to :post, counter_cache: :likes_total
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

# A preload object.
class LikesCounts
  attr_reader :posts

  def initialize(posts)
    @posts = posts
  end

  def [](post)
    counts[post.id] || 0
  end

  def counts
    @counts ||= Like.where(post_id: posts).group(:post_id).count
  end
end

# P. 72 Account and Entry models.
class Account < ApplicationRecord
  has_many :entries

  def create_entry(amount:)
    entry = entries.create(amount:)
    # Copilot suggested this.
    # update!(balance: balance + amount)
    update_balance_with(entry)
  end

  def update_balance_with(entry)
    update!(balance: balance + entry.amount)
  end
end

# P. 72 Entry for race condition demonstration.
class Entry < ApplicationRecord
  belongs_to :account, touch: true
end

def seed_accounts_and_entries(account_count: 10, entry_count: 10)
  account_count.times do
    account = Account.create
    entry_count.times do
      Entry.create(account:)
    end
  end
end

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

seed_accounts_and_entries(account_count: 10, entry_count: 10)

ActiveRecord::Base.logger = Logger.new($stdout)

def account_balance(*_args)
  banner = <<~BANNER
    Page 73, account balance without threading.
  BANNER
  puts banner.green

  account = Account.first
  4.times { account.create_entry(amount: 100) }
  puts "Account balance: #{account.reload.balance}"
end

def threaded_account_balance(*_args) # rubocop:disable Metrics/MethodLength
  banner = <<~BANNER
    Page 73, account balance with threading.
  BANNER
  puts banner.green

  explanation = <<~ERROR
    In-memory SQLite3 does not play well with threading. This is a
    demonstration. In a real application, you would use a
    database that supports threading. For example, PostgreSQL
    this example works as expected, that is, the balance is not
    updated correctly.
  ERROR

  # Does this change the result?
  account = Account.first
  account.create_entry(amount: 0)

  threads = 4.times.map do
    Thread.new do
      account.create_entry(amount: 100)
    rescue StandardError => e
      puts "#{e.message}\n #{explanation}".red
    end
  end

  threads.each(&:join)
  puts "Account balance: #{Account.first.balance}"
end

CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY
CLI::UI::Prompt.ask('Which scenario?') do |handler|
  handler.option('threaded account balance', &method(:threaded_account_balance))
  handler.option('account balance', &method(:account_balance))
  handler.option('preload object', &method(:preload_object))
end
