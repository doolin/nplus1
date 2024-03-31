# frozen_string_literal: true

# Database Setup
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = Logger::INFO  # Or another level, like Logger::WARN

# Define Schema
ActiveRecord::Schema.define do
  create_table :posts do |t|
    t.column :user_id, :bigint
    t.column :title, :string
    t.column :body, :text
    # Default Rails counter cache name
    # t.integer :likes_count, default: 0, null: false
    # Custom counter cache name
    t.integer :likes_total
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table :likes do |t|
    t.references :post
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table :users do |table|
    table.column :first_name, :string
    table.column :last_name, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end

  create_table :comments do |table|
    table.column :post_id, :integer
    table.column :user_id, :integer
    table.column :likes_count, :integer
    table.column :body, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end

  create_table :comment_votes do |table|
    table.column :comment_id, :integer
    table.column :voter_id, :integer
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end
end

# Make rubocop happy
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

def reset_tables
  ActiveRecord::Base.logger = nil
  Comment.delete_all
  Post.delete_all
  User.delete_all
  Likes.delete_all
  CommentVote.delete_all
  ActiveRecord::Base.logger = Logger.new($stdout)
end

def seed_posts_and_comments(post_count:, comment_count:)
  ActiveRecord::Base.logger = nil
  (1..post_count).each do |i|
    post = Post.create(title: "Post #{i}")
    (1..comment_count).each do |j|
      post.comments.create(body: "Comment #{j}")
    end
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

def seed_users_and_comments(user_count:, comment_count:)
  (1..user_count).each do |i|
    user = User.create(first_name: "Name#{i}")
    (1..comment_count).each do |j|
      user.comments.create(body: "Comment #{j}")
    end
  end
end

def seed_posts(count:)
  ActiveRecord::Base.logger = nil
  (1..count).each do |i|
    Post.create(title: "Post #{i}")
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

def seed_users(count:)
  ActiveRecord::Base.logger = nil
  (1..count).each do |i|
    User.create(first_name: "Name #{i}")
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

# TODO: seed posts and users
# This is needed to make sense of popular comments.
def seed_users_and_posts(user_count:, post_count:)
  ActiveRecord::Base.logger = nil
  (1..user_count).each do |i|
    user = User.create(first_name: "Name#{i}")
    (1..post_count).each do |j|
      user.posts.create(title: "Post #{j}")
    end
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
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

def seed_poste_and_likes(post_count:, like_count:)
  ActiveRecord::Base.logger = nil
  (1..post_count).each do |i|
    post = Post.create(title: "Name#{i}")
    (1..rand(like_count)).each do
      post.likes.create
    end
  end
  ActiveRecord::Base.logger = Logger.new($stdout)
end

# Create synthetic data.
class Provision
  def initialize
    users = create_users(100) do
      { first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name }
    end

    posts = create_posts(users, 100) do
      { title: FFaker::CheesyLingo.title, body: FFaker::CheesyLingo.paragraph, user_id: users.sample.id }
    end

    create_comments(posts, users, 1000) do |post, user_id|
      { post_id: post.id, user_id:, body: FFaker::CheesyLingo.sentence, likes_count: rand(10) }
    end

    create_comment_votes(100)
    create_likes(posts, 10) do |post|
      { post_id: post.id }
    end
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

  # This will not update counter caches.
  def create_likes(posts, count, &block)
    data = posts.flat_map { |post| count.times.map { block.call(post) } }
    Like.insert_all(data, record_timestamps: true)
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
end
