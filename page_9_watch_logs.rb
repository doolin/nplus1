#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'
require 'logger'
require 'sqlite3'
require 'query_count'

require_relative 'setup'

# Page 8 use default comment order.
module Page9
  # Define post model
  class Post < ApplicationRecord
    has_many :comments
  end

  # Define comment model
  class Comment < ApplicationRecord
    belongs_to :post
  end
end

def seed(post_count:, comment_count:)
  (1..post_count).each do |i|
    post = Page9::Post.create(title: "Example Post #{i}")
    (1..comment_count).each do |j|
      post.comments.create(body: "Comment #{j}")
    end
  end
end

seed(post_count: 2, comment_count: 5)
ActiveRecord::Base.logger = Logger.new($stdout)

# Page 9
# ./page_9_watch_logs.rb:49:> tmp/out.txt
# Verufy with grep "SELECT" tmp/out.txt | wc -l
Page9::Post.all.map(&:comments).map(&:to_a)