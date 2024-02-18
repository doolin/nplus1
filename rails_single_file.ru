#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

# Links for single page Rails application:
# - https://greg.molnar.io/blog/a-single-file-rails-application/
# - https://github.com/XiaoA/single-rackup-file-rails/blob/main/app.ru
# - https://gist.github.com/v-kolesnikov/111144e4ca12850b06921c1d7bd18336
# - https://gist.github.com/doolin/9d76786d3d144b13e8f272c71c832632
# - https://gist.github.com/doolin/dd9a6047d5cd0784a508979539ae44b2
# - https://github.com/sirfilip/single-file-rails/blob/master/app.rb
# - https://github.com/hopsoft/sr_mini/blob/main/application.rb

# Dealing with some errors:
# This error "You should run `bundle binstub rack` to work around a system/bundle conflict"
# was fixed by running:
#  - `gem uninstall bundler`
#  - `gem install bundler`

# Not sure how I fixed this, but updating bundler, reinstalling
# Ruby 3.3.0, and running `bundle pristibe` seemed to fix it.
# gem-wrappers_plugin.rb": cannot load such file -- gem-wrappers

# Had to reinstall ruby 3.3.0 and got the usual issue linking.
# This worked: `rvm install 3.3.0 --autolibs=disable`
# This flag should also work: --with-openssl-dir=/opt/homebrew/opt/openssl@1.1

# Also did this: `bundle update --bundler` to fix a bundler issue.

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
require 'action_controller'
require 'logger'

Rails.logger = Logger.new($stdout)

# Ok so this is not _strictly_ a single file application,
# but adding the setup.rb code for the schema would make
# it so. Might add it incline later.
require_relative 'setup'

# Define user model
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

# The actual Rails application.
class App < Rails::Application
  # Not sure what these do,  comment out for now.
  # config.root = __dir__
  config.consider_all_requests_local = true

  # config.logger           = ActiveSupport::Logger.new(STDOUT)
  # config.logger = Rails::Rack::Logger.new(Logger.new (STDOUT) )
  # config.logger           = ActiveSupport::Logger.new(STDOUT)
  # logger.formatter = config.log_formatter
  # config.colorize_logging
  config.secret_key_base = 'i_am_a_secret'
  # config.active_storage.service_configurations = { 'local' => { 'service' => 'Disk', 'root' => './storage' } }
end

Rails.application.routes.draw do
  get '/welcome' => 'welcome#index' # , via: %i[get]
  # root to: proc{|env| [200, {'Content-type' => 'text/html'}, ['Hello World']]}
end

# Demo controller, will likely be removed.
class WelcomeController < ActionController::Base
  def index
    render inline: 'Hi!'
  end
end

# consider the following instead:
# App.initialize!
# Rack::Server.start(app: App)

run App
