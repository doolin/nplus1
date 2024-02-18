#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

# From https://greg.molnar.io/blog/a-single-file-rails-application/
# Necessary for single file Rails application, not sure how I want
# to handle this yet.
gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
  gem 'rack'
  gem 'sqlite3'
  gem 'colorize'
  gem 'query_count'
  gem 'puma'
end

require 'rails/all'
require 'action_controller/railtie'
require 'logger'

Rails.logger = Logger.new(STDOUT)

# require 'logger'
# require 'sqlite3'
# require 'colorize'
# require 'query_count'

require_relative 'setup'

# Define post model
class User < ApplicationRecord
  self.strict_loading_by_default = true

  has_many :comments
end

# Define comment model
class Comment < ApplicationRecord
  belongs_to :user
end

banner = <<~BANNER
  Single File Rails Application for  testing various parts
  of the book.
BANNER
puts banner.yellow

# ActiveRecord::Base.logger = Logger.new($stdout)

class App < Rails::Application
  config.root = __dir__
  config.consider_all_requests_local = true
  # config.logger           = ActiveSupport::Logger.new(STDOUT)
  # config.logger = Rails::Rack::Logger.new(Logger.new (STDOUT) )
  # config.logger           = ActiveSupport::Logger.new(STDOUT)
  # logger.formatter = config.log_formatter
  config.colorize_logging
  config.secret_key_base = 'i_am_a_secret'
  # config.active_storage.service_configurations = { 'local' => { 'service' => 'Disk', 'root' => './storage' } }

  routes.append do
    match '/' => 'welcome#index', via: %i[get]
    root to: 'welcome#index'
  end
end

class WelcomeController < ActionController::Base
  def index
    binding.irb
    render inline: 'Hi!'
  end
end

# consider the following instead:
# App.initialize!
# Rack::Server.start(app: App)

run App