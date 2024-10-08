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
  gem 'query_count'
  gem 'prosopite'
  gem 'pg_query'
end

require 'active_record'
require 'logger'
require 'sqlite3'
require 'colorize'
require 'query_count'
require 'prosopite'

Prosopite.prosopite_logger = true

require_relative 'setup'

# Define post model
class User < ApplicationRecord
  # self.strict_loading_by_default = true

  has_many :comments
end

# Define comment model
class Comment < ApplicationRecord
  belongs_to :user
end

def seed(user_count:, comment_count:)
  (1..user_count).each do |i|
    user = User.create(first_name: "Name#{i}")
    (1..comment_count).each do |j|
      user.comments.create(body: "Comment #{j}")
    end
  end
end

banner = <<~BANNER
  Strict loading is a feature that helps you to avoid N+1 queries by
  raising an error when you try to load an association that was not
  preloaded. This feature is useful to ensure that you are not
  accidentally loading associations in a loop or in a view.

  In this case, strict loading is being set on the model instead of
  the association. This means that the error will be raised when you
  try to load the association from any instance of the model.
BANNER
puts banner.yellow

seed(user_count: 2, comment_count: 5)
ActiveRecord::Base.logger = Logger.new($stdout)

# Page 12. Strict loading on a relation.
# user = User.first
# begin
#   user.comments.to_a
# rescue ActiveRecord::StrictLoadingViolationError => e
#   puts e.message.red
# end

result = Prosopite.scan do
  user = User.first
  user.comments.to_a
end

puts "Result: #{result}"
