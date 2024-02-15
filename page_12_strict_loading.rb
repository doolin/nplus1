#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'
require 'logger'
require 'sqlite3'
require 'colorize'
require 'query_count'

require_relative 'setup'

# Define post model
class User < ApplicationRecord
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

seed(user_count: 2, comment_count: 5)
ActiveRecord::Base.logger = Logger.new($stdout)

# Page 12. Strict loading on a record (or model).
user = User.first
user.strict_loading!
begin
  user.comments.to_a
rescue ActiveRecord::StrictLoadingViolationError => e
  puts e.message.red
end

# Page 12. Strict loading on a relation.
user = User.strict_loading.first
begin
  user.comments.to_a
rescue ActiveRecord::StrictLoadingViolationError => e
  puts e.message.red
end
