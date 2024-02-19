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
  gem 'rack-mini-profiler', require: false
  gem 'stackprof'
  gem 'sqlite3'
  gem 'bullet'
  gem 'colorize'
  gem 'query_count'
  gem 'puma'
end

require 'rails/all'
require 'action_controller/railtie'
require 'action_controller'
require 'active_record'
require 'rack-mini-profiler'
require 'logger'

Rails.logger = Logger.new($stdout)

# It won't run in memory:
# ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'ch1.db')
# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = Logger::INFO  # Or another level, like Logger::WARN
# Define Schema
ActiveRecord::Schema.define do
  create_table :posts do |table|
    table.column :title, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
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
    table.column :body, :string
    table.datetime 'created_at', null: false
    table.datetime 'updated_at', null: false
  end
end

# Make rubocop happy
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

# Define user model
class User < ApplicationRecord
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
ActiveRecord::Base.logger = Logger.new('./log/development.log')
# Apparently cannot configure in class App per Page 13,
# so we configure directly here.
# ActiveRecord::Base.strict_loading_by_default = true

Rack::MiniProfiler.config.storage = Rack::MiniProfiler::FileStore.new(path: './tmp/miniprofiler/profile')
# From `rack-mini-profiler/lib/rack-mini-profiler.rb`
require 'mini_profiler/version'
require 'mini_profiler/asset_version'
require 'mini_profiler'
require 'patches/sql_patches'
require 'patches/net_patches'
if defined?(::Rails) && defined?(::Rails::VERSION) && ::Rails::VERSION::MAJOR.to_i >= 3
  require 'mini_profiler_rails/railtie'
end
### The lines above ^^^ are from `rack-mini-profiler/lib/rack-mini-profiler.rb`

# The actual Rails application.
class App < Rails::Application
  # Not sure what these do,  comment out for now.
  # config.root = __dir__
  config.consider_all_requests_local = true

  # Page 13, this doesn't work, see ActiveRecord::Base above.
  # config.active_record.strict_loading_by_default = true
  # Page 13, does not appear to work, it's not going to log.
  config.active_record.action_on_strict_loading_violation = :log

  # config.logger           = ActiveSupport::Logger.new(STDOUT)
  # config.logger = Rails::Rack::Logger.new(Logger.new (STDOUT) )
  # config.logger           = ActiveSupport::Logger.new(STDOUT)
  # logger.formatter = config.log_formatter
  # config.colorize_logging
  config.secret_key_base = 'i_am_a_secret'
  # config.active_storage.service_configurations = { 'local' => { 'service' => 'Disk', 'root' => './storage' } }

  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
    # Bullet.sentry = true
    # Bullet.alert = true
    # Bullet.bullet_logger = true
    # Bullet.console = true
    # Bullet.xmpp = { :account  => 'bullets_account@jabber.org',
    #                 :password => 'bullets_password_for_jabber',
    #                 :receiver => 'your_account@jabber.org',
    #                 :show_online_status => true }
    # Bullet.rails_logger = true
    # Bullet.honeybadger = true
    # Bullet.bugsnag = true
    # Bullet.appsignal = true
    # Bullet.airbrake = true
    # Bullet.rollbar = true
    # Bullet.add_footer = true
    # Bullet.skip_html_injection = false
    # Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
    # Bullet.stacktrace_excludes = [ 'their_gem', 'their_middleware', ['my_file.rb', 'my_method'], ['my_file.rb', 16..20] ]
    # Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#default', username: 'notifier' }
  end

end

Rails.application.routes.draw do
  get '/welcome' => 'welcome#index' # , via: %i[get]
  # root to: proc{|env| [200, {'Content-type' => 'text/html'}, ['Hello World']]}
end

# Demo controller, will likely be removed.
class WelcomeController < ActionController::Base
  def index
    render inline: "Hi! This is a Rails #{Rails.env} environment."

    seed(user_count: 2, comment_count: 5)

    user = User.first
    begin
      user.comments.to_a
    rescue ActiveRecord::StrictLoadingViolationError => e
      # Will induce a 304 response when strict loading is enforced.
      puts e.message.red
    end
  end

  def seed(user_count:, comment_count:)
    (1..user_count).each do |i|
      user = User.create(first_name: "Name#{i}")
      (1..comment_count).each do |j|
        user.comments.create(body: "Comment #{j}")
      end
    end
  end
end

# consider the following instead:
# App.initialize!
# Rack::Server.start(app: App)

run App
